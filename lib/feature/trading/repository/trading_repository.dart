// lib/features/trading/repository/trading_repository.dart

import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/hive_service.dart';
import '../model/trading_models.dart';
import '../model/trading_target_model.dart';
import '../model/trading_growth_plan_model.dart';
import '../model/trading_account_model.dart';

class TradingRepository {
  Box<dynamic> get _box => HiveService.box(HiveBoxes.tradingNotes);

  static const _journalKey  = 'trading_journal';
  static const _biasKey     = 'trading_bias_board';
  static const _rulesKey    = 'trading_rules';
  static const _sessionKey  = 'trading_session_active';

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> saveSessionActive(bool active) async {
    await _box.put(_sessionKey, active);
  }

  bool loadSessionActive() {
    return _box.get(_sessionKey, defaultValue: false) as bool;
  }

  // ── Journal ───────────────────────────────────────────────────────────────

  /// Save or update a journal entry (replaces if id exists).
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final List<dynamic> entries =
        List.from(_box.get(_journalKey, defaultValue: []) as List);

    final map = entry.toMap();
    final idx = entries.indexWhere((e) => (e as Map)['id'] == entry.id);
    if (idx >= 0) {
      entries[idx] = map;
    } else {
      entries.add(map);
    }

    // Keep last 500 entries
    if (entries.length > 500) entries.removeAt(0);
    await _box.put(_journalKey, entries);
  }

  /// Delete a journal entry by id.
  Future<void> deleteJournalEntry(String id) async {
    final List<dynamic> entries =
        List.from(_box.get(_journalKey, defaultValue: []) as List);
    entries.removeWhere((e) => (e as Map)['id'] == id);
    await _box.put(_journalKey, entries);
  }

  List<JournalEntry> loadTodayJournal() {
    final List<dynamic> all =
        List.from(_box.get(_journalKey, defaultValue: []) as List);
    final today = DateTime.now();

    return all
        .where((e) {
          final dt = DateTime.parse((e as Map)['createdAt'] as String);
          return dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day;
        })
        .map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<JournalEntry> loadAllJournal() {
    final List<dynamic> all =
        List.from(_box.get(_journalKey, defaultValue: []) as List);

    return all
        .map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Bias Board ────────────────────────────────────────────────────────────

  Future<void> saveBiasBoard(List<BiasEntry> biases) async {
    final data = biases.map((b) => {
      'id':         b.id,
      'instrument': b.instrument,
      'direction':  b.direction.index,
      'reasoning':  b.reasoning,
      'createdAt':  b.createdAt.toIso8601String(),
      'expiresAt':  b.expiresAt?.toIso8601String(),
    }).toList();

    await _box.put(_biasKey, data);
  }

  List<BiasEntry> loadBiasBoard() {
    final List<dynamic> data =
        List.from(_box.get(_biasKey, defaultValue: []) as List);

    return data
        .map((b) => BiasEntry(
              id:         b['id'] as String,
              instrument: b['instrument'] as String,
              direction:  BiasDirection.values[b['direction'] as int],
              reasoning:  b['reasoning'] as String,
              createdAt:  DateTime.parse(b['createdAt'] as String),
              expiresAt:  b['expiresAt'] != null
                  ? DateTime.parse(b['expiresAt'] as String)
                  : null,
            ))
        .where((b) => !b.isExpired) // auto-filter expired biases on load
        .toList();
  }

  // ── Rules ─────────────────────────────────────────────────────────────────

  Future<void> saveAllRules(List<TradingRule> rules) async {
    final data = rules.map((r) => r.toMap()).toList();
    await _box.put(_rulesKey, data);
  }

  Future<void> deleteRule(String id) async {
    final List<dynamic> rules =
        List.from(_box.get(_rulesKey, defaultValue: []) as List);
    rules.removeWhere((r) => (r as Map)['id'] == id);
    await _box.put(_rulesKey, rules);
  }

  List<TradingRule> loadCustomRules() {
    final List<dynamic> rules =
        List.from(_box.get(_rulesKey, defaultValue: []) as List);

    return rules
        .map((r) => TradingRule.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // ── Targets ───────────────────────────────────────────────────────────────

  static const _targetsKey = 'trading_targets';

  Future<void> saveTarget(TradingTarget target) async {
    final List<dynamic> all =
        List.from(_box.get(_targetsKey, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == target.id);
    if (idx >= 0) {
      all[idx] = target.toMap();
    } else {
      all.add(target.toMap());
    }
    await _box.put(_targetsKey, all);
  }

  List<TradingTarget> loadTargets() {
    final List<dynamic> all =
        List.from(_box.get(_targetsKey, defaultValue: []) as List);
    return all
        .map((e) => TradingTarget.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteTarget(String id) async {
    final List<dynamic> all =
        List.from(_box.get(_targetsKey, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await _box.put(_targetsKey, all);
  }

  // ── Starting Capital ──────────────────────────────────────────────────────

  static const _capitalKey = 'trading_starting_capital';

  Future<void> saveStartingCapital(double amount) async {
    await _box.put(_capitalKey, amount);
  }

  double loadStartingCapital() {
    return (_box.get(_capitalKey, defaultValue: 0.0) as num).toDouble();
  }

  // ── Growth Plans ──────────────────────────────────────────────────────────

  static const _growthPlansKey = 'trading_growth_plans';

  Future<void> saveGrowthPlan(TradingGrowthPlan plan) async {
    final List<dynamic> all =
        List.from(_box.get(_growthPlansKey, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == plan.id);
    if (idx >= 0) {
      all[idx] = plan.toMap();
    } else {
      all.add(plan.toMap());
    }
    await _box.put(_growthPlansKey, all);
  }

  List<TradingGrowthPlan> loadGrowthPlans() {
    final List<dynamic> all =
        List.from(_box.get(_growthPlansKey, defaultValue: []) as List);
    return all
        .map((e) => TradingGrowthPlan.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteGrowthPlan(String id) async {
    final List<dynamic> all =
        List.from(_box.get(_growthPlansKey, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await _box.put(_growthPlansKey, all);
  }

  // ── Trading Account (MetaApi bridge) ──────────────────────────────────────

  static const _accountKey      = 'trading_account_config';
  static const _brokerTradesKey = 'trading_broker_trades';
  static const _brokerInfoKey   = 'trading_broker_info';

  Future<void> saveAccountConfig(TradingAccountConfig? config) async {
    if (config == null) {
      await _box.delete(_accountKey);
    } else {
      await _box.put(_accountKey, config.toMap());
    }
  }

  TradingAccountConfig? loadAccountConfig() {
    final raw = _box.get(_accountKey);
    if (raw == null) return null;
    return TradingAccountConfig.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveBrokerTrades(List<BrokerTrade> trades) async {
    final data = trades.map((t) => t.toMap()).toList();
    await _box.put(_brokerTradesKey, data);
  }

  List<BrokerTrade> loadBrokerTrades() {
    final List<dynamic> all =
        List.from(_box.get(_brokerTradesKey, defaultValue: []) as List);
    return all
        .map((e) => BrokerTrade.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveBrokerInfo(BrokerAccountInfo? info) async {
    if (info == null) {
      await _box.delete(_brokerInfoKey);
    } else {
      await _box.put(_brokerInfoKey, info.toMap());
    }
  }

  BrokerAccountInfo? loadBrokerInfo() {
    final raw = _box.get(_brokerInfoKey);
    if (raw == null) return null;
    return BrokerAccountInfo.fromMap(Map<String, dynamic>.from(raw as Map));
  }
}
