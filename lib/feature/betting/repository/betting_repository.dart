// lib/features/betting/repository/betting_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/bet_model.dart';
import '../model/bankroll_model.dart';
import '../model/lockdown_model.dart';
import '../model/betting_plan_model.dart';

class BettingRepository {
  static const String _betsKey     = 'betting_bets';
  static const String _bankrollKey = 'betting_bankroll';
  static const String _lockdownKey = 'betting_lockdown';
  static const String _plansKey    = 'betting_plans';

  // ── Bets ──────────────────────────────────────────────────────────────────

  Future<void> saveBet(BetModel bet) async {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> existing =
        List.from(box.get(_betsKey, defaultValue: []) as List);
    final index = existing.indexWhere((e) => (e as Map)['id'] == bet.id);
    if (index >= 0) {
      existing[index] = bet.toMap();
    } else {
      existing.add(bet.toMap());
    }
    if (existing.length > 500) existing.removeAt(0);
    await box.put(_betsKey, existing);
  }

  List<BetModel> loadActiveBets() {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> raw =
        List.from(box.get(_betsKey, defaultValue: []) as List);
    return raw
        .map((e) => BetModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((b) => b.isActive)
        .toList();
  }

  List<BetModel> loadTodayBets() {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> raw =
        List.from(box.get(_betsKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) => BetModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((b) =>
            b.placedAt.year == now.year &&
            b.placedAt.month == now.month &&
            b.placedAt.day == now.day)
        .toList();
  }

  List<BetModel> loadAllBets() {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> raw =
        List.from(box.get(_betsKey, defaultValue: []) as List);
    return raw
        .map((e) => BetModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Returns all bets placed within the last [days] days, sorted newest first.
  List<BetModel> loadRecentBets({int days = 31}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return loadAllBets()
        .where((b) => b.placedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
  }

  // ── Bankroll ──────────────────────────────────────────────────────────────

  Future<void> saveBankroll(BankrollModel bankroll) async {
    await HiveService.put(HiveBoxes.bettingLogs, _bankrollKey, bankroll.toMap());
  }

  BankrollModel loadBankroll() {
    final raw = HiveService.get<Map>(HiveBoxes.bettingLogs, _bankrollKey);
    if (raw == null) return BankrollModel.initial();
    return BankrollModel.fromMap(Map<String, dynamic>.from(raw));
  }

  // ── Lockdown ──────────────────────────────────────────────────────────────

  Future<void> saveLockdown(LockdownModel lockdown) async {
    await HiveService.put(HiveBoxes.bettingLogs, _lockdownKey, lockdown.toMap());
  }

  LockdownModel loadLockdown() {
    final raw = HiveService.get<Map>(HiveBoxes.bettingLogs, _lockdownKey);
    if (raw == null) return LockdownModel.unlocked();
    return LockdownModel.fromMap(Map<String, dynamic>.from(raw));
  }

  // ── Betting Plans ─────────────────────────────────────────────────────────

  Future<void> savePlan(BettingPlan plan) async {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> all =
        List.from(box.get(_plansKey, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == plan.id);
    if (idx >= 0) {
      all[idx] = plan.toMap();
    } else {
      all.add(plan.toMap());
    }
    await box.put(_plansKey, all);
  }

  List<BettingPlan> loadPlans() {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> raw =
        List.from(box.get(_plansKey, defaultValue: []) as List);
    return raw
        .map((e) => BettingPlan.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deletePlan(String id) async {
    final box = HiveService.box(HiveBoxes.bettingLogs);
    final List<dynamic> all =
        List.from(box.get(_plansKey, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_plansKey, all);
  }
}
