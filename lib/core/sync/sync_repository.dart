import 'package:uuid/uuid.dart';

import '../constants/hive_boxes.dart';
import '../services/hive_service.dart';

class SyncRepository {
  static const _deviceIdKey = 'sync_device_id';
  static const _lastPullPrefix = 'sync_last_pull_';
  static const _tombstonesKey = 'sync_tombstones';

  String loadDeviceId() {
    final box = HiveService.box(HiveBoxes.syncMetadata);
    final existing = box.get(_deviceIdKey) as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final created = const Uuid().v4();
    box.put(_deviceIdKey, created);
    return created;
  }

  DateTime? loadLastPullAt(String scope) {
    final raw = HiveService.get<String>(
      HiveBoxes.syncMetadata,
      '$_lastPullPrefix$scope',
    );
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastPullAt(String scope, DateTime value) async {
    await HiveService.put(
      HiveBoxes.syncMetadata,
      '$_lastPullPrefix$scope',
      value.toUtc().toIso8601String(),
    );
  }

  Future<void> saveTombstone({
    required String entityType,
    required String entityId,
    DateTime? deletedAt,
  }) async {
    final box = HiveService.box(HiveBoxes.syncMetadata);
    final existing = List<dynamic>.from(
      box.get(_tombstonesKey, defaultValue: const <dynamic>[]) as List,
    );
    final now = deletedAt ?? DateTime.now().toUtc();
    final key = '$entityType:$entityId';
    existing.removeWhere((e) => (e as Map)['key'] == key);
    existing.add({
      'key': key,
      'entityType': entityType,
      'entityId': entityId,
      'deletedAt': now.toIso8601String(),
    });
    await box.put(_tombstonesKey, existing);
  }

  List<SyncTombstone> loadTombstones() {
    final raw = List<dynamic>.from(
      HiveService.box(
            HiveBoxes.syncMetadata,
          ).get(_tombstonesKey, defaultValue: const <dynamic>[])
          as List,
    );

    return raw
        .map((e) => SyncTombstone.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> clearTombstones(Iterable<SyncTombstone> tombstones) async {
    final remove = tombstones.map((e) => e.key).toSet();
    final remaining = loadTombstones()
        .where((e) => !remove.contains(e.key))
        .map((e) => e.toMap())
        .toList();
    await HiveService.box(
      HiveBoxes.syncMetadata,
    ).put(_tombstonesKey, remaining);
  }
}

class SyncTombstone {
  final String entityType;
  final String entityId;
  final DateTime deletedAt;

  const SyncTombstone({
    required this.entityType,
    required this.entityId,
    required this.deletedAt,
  });

  String get key => '$entityType:$entityId';

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'entityType': entityType,
      'entityId': entityId,
      'deletedAt': deletedAt.toUtc().toIso8601String(),
    };
  }

  factory SyncTombstone.fromMap(Map<String, dynamic> map) {
    return SyncTombstone(
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      deletedAt:
          DateTime.tryParse(map['deletedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class SyncResult {
  final bool ran;
  final bool changedLocalData;
  final int uploaded;
  final int downloaded;
  final String? message;

  const SyncResult({
    required this.ran,
    required this.changedLocalData,
    required this.uploaded,
    required this.downloaded,
    this.message,
  });

  const SyncResult.skipped(String reason)
    : ran = false,
      changedLocalData = false,
      uploaded = 0,
      downloaded = 0,
      message = reason;
}
