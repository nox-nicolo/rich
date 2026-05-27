import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/supabase_service.dart';
import '../../../core/sync/sync_repository.dart';
import '../model/finance_models.dart';
import '../repository/finance_repository.dart';

class FinanceSyncService {
  FinanceSyncService._();
  static final FinanceSyncService instance = FinanceSyncService._();

  static const _scope = 'finance';
  static const _table = 'rich_sync_records';

  final FinanceRepository _finance = FinanceRepository();
  final SyncRepository _sync = SyncRepository();

  bool _running = false;

  Future<SyncResult> sync() async {
    if (_running) {
      return _skipped('Finance sync already running');
    }
    _running = true;

    try {
      final supabase = SupabaseService.instance;
      if (!supabase.isConfigured) {
        return _skipped('Supabase is not configured');
      }

      await supabase.init();
      final hasSession = await supabase.ensureSession();
      final client = supabase.client;
      if (client == null || !hasSession) {
        return _skipped('Supabase session is not available');
      }

      final uploaded = await _uploadLocalRecords(client);
      final downloaded = await _downloadRemoteRecords(client);

      final result = SyncResult(
        ran: true,
        changedLocalData: downloaded > 0,
        uploaded: uploaded,
        downloaded: downloaded,
      );
      debugPrint(
        'Finance sync completed: uploaded=$uploaded downloaded=$downloaded',
      );
      return result;
    } catch (e) {
      return _skipped('Finance sync failed: $e');
    } finally {
      _running = false;
    }
  }

  SyncResult _skipped(String reason) {
    debugPrint('Finance sync skipped: $reason');
    return SyncResult.skipped(reason);
  }

  Future<int> _uploadLocalRecords(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 0;

    final deviceId = _sync.loadDeviceId();
    final rows = <Map<String, dynamic>>[
      ..._finance.loadAccounts().map(
        (e) => _row(
          userId: userId,
          deviceId: deviceId,
          entityType: FinanceRepository.accountEntityType,
          entityId: e.id,
          payload: e.toMap(),
          updatedAt: e.updatedAt,
        ),
      ),
      ..._finance.loadAllocations().map(
        (e) => _row(
          userId: userId,
          deviceId: deviceId,
          entityType: FinanceRepository.allocationEntityType,
          entityId: e.id,
          payload: e.toMap(),
          updatedAt: e.updatedAt,
        ),
      ),
      ..._finance.loadAllTransactions().map(
        (e) => _row(
          userId: userId,
          deviceId: deviceId,
          entityType: FinanceRepository.transactionEntityType,
          entityId: e.id,
          payload: e.toMap(),
          updatedAt: e.updatedAt,
        ),
      ),
      ..._finance.loadAuditTrail().map(
        (e) => _row(
          userId: userId,
          deviceId: deviceId,
          entityType: FinanceRepository.auditEntryEntityType,
          entityId: e.id,
          payload: e.toMap(),
          updatedAt: e.timestamp,
        ),
      ),
    ];

    final tombstones = _sync.loadTombstones();
    rows.addAll(
      tombstones.map(
        (e) => _row(
          userId: userId,
          deviceId: deviceId,
          entityType: e.entityType,
          entityId: e.entityId,
          payload: const <String, dynamic>{},
          updatedAt: e.deletedAt,
          deletedAt: e.deletedAt,
        ),
      ),
    );

    if (rows.isEmpty) return 0;

    await client
        .from(_table)
        .upsert(rows, onConflict: 'user_id,entity_type,entity_id');
    if (tombstones.isNotEmpty) {
      await _sync.clearTombstones(tombstones);
    }
    return rows.length;
  }

  Future<int> _downloadRemoteRecords(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 0;

    final lastPullAt = _sync.loadLastPullAt(_scope);
    final query = client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .inFilter('entity_type', const [
          FinanceRepository.accountEntityType,
          FinanceRepository.allocationEntityType,
          FinanceRepository.transactionEntityType,
          FinanceRepository.auditEntryEntityType,
        ]);

    final List<dynamic> rows = lastPullAt == null
        ? await query.order('updated_at')
        : await query
              .gte('updated_at', lastPullAt.toUtc().toIso8601String())
              .order('updated_at');

    var changed = 0;
    DateTime newestPull = DateTime.now().toUtc();

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
      if (updatedAt != null && updatedAt.isAfter(newestPull)) {
        newestPull = updatedAt;
      }
      if (await _applyRemoteRow(row)) changed++;
    }

    await _sync.saveLastPullAt(_scope, newestPull);
    return changed;
  }

  Future<bool> _applyRemoteRow(Map<String, dynamic> row) async {
    final entityType = row['entity_type'] as String? ?? '';
    final entityId = row['entity_id'] as String? ?? '';
    final payload = Map<String, dynamic>.from(
      (row['payload'] as Map?) ?? const <String, dynamic>{},
    );
    final deletedAt = row['deleted_at'];

    if (deletedAt != null) {
      await _removeLocal(entityType, entityId);
      return true;
    }

    switch (entityType) {
      case FinanceRepository.accountEntityType:
        final remote = FinanceAccount.fromMap(payload);
        final local = _finance.loadAccountById(remote.id);
        if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
          return false;
        }
        await _finance.saveAccount(remote);
        return true;
      case FinanceRepository.allocationEntityType:
        final remote = BudgetAllocation.fromMap(payload);
        final local = _finance
            .loadAllocations()
            .where((e) => e.id == remote.id)
            .firstOrNull;
        if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
          return false;
        }
        await _finance.saveAllocation(remote);
        return true;
      case FinanceRepository.transactionEntityType:
        final remote = FinanceTransaction.fromMap(payload);
        final local = _finance.loadTransactionById(remote.id);
        if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
          return false;
        }
        await _finance.saveTransaction(remote);
        return true;
      case FinanceRepository.auditEntryEntityType:
        final remote = AuditTrailEntry.fromMap(payload);
        final local = _finance
            .loadAuditTrail()
            .where((e) => e.id == remote.id)
            .firstOrNull;
        if (local != null && local.timestamp.isAfter(remote.timestamp)) {
          return false;
        }
        await _finance.saveAuditEntry(remote);
        return true;
      default:
        return false;
    }
  }

  Future<void> _removeLocal(String entityType, String entityId) async {
    switch (entityType) {
      case FinanceRepository.accountEntityType:
        await _finance.removeLocalAccount(entityId);
        return;
      case FinanceRepository.allocationEntityType:
        await _finance.removeLocalAllocation(entityId);
        return;
      case FinanceRepository.transactionEntityType:
        await _finance.removeLocalTransaction(entityId);
        return;
      case FinanceRepository.auditEntryEntityType:
        await _finance.removeLocalAuditEntry(entityId);
        return;
    }
  }

  Map<String, dynamic> _row({
    required String userId,
    required String deviceId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) {
    return {
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }
}
