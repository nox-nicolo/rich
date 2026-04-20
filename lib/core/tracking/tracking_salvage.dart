// lib/core/tracking/tracking_salvage.dart
//
// One-shot retroactive backfill. Scans each feature's existing Hive-stored
// entities, groups them by their own timestamps (completedAt / createdAt /
// savedAt / transactionDate), and writes synthetic DailyRecord entries so
// the Reports screen has history the first time it's ever opened.
//
// Gated by a flag stored in the user_preferences box — runs exactly once
// per install, safe to call on every app launch.

import '../constants/hive_boxes.dart';
import '../services/hive_service.dart';

import '../../feature/betting/repository/betting_repository.dart';
import '../../feature/betting/model/bet_model.dart';
import '../../feature/betting/model/betting_plan_model.dart';
import '../../feature/finance/repository/finance_repository.dart';
import '../../feature/finance/model/finance_models.dart';
import '../../feature/life/repository/life_repository.dart';
import '../../feature/life/model/health_log_model.dart';
import '../../feature/meditation/repository/meditation_repository.dart';
import '../../feature/reading/repository/reading_repository.dart';
import '../../feature/reading/model/book_model.dart';
import '../../feature/trading/repository/trading_repository.dart';
import '../../feature/trading/model/trading_models.dart';
import '../../feature/work/repository/work_repository.dart';
import '../../feature/work/model/task_model.dart';
import '../../feature/writing/repository/writing_repository.dart';

import 'tracking_feature.dart';
import 'tracking_service.dart';

class TrackingSalvage {
  TrackingSalvage._();

  static const String _flagKey = 'tracking_salvage_v1_done';

  /// Run the one-shot backfill if it hasn't been run yet. Returns the number
  /// of synthetic DailyRecord upserts performed (0 if already run).
  static Future<int> runIfNeeded() async {
    final done = HiveService.get<bool>(HiveBoxes.userPreferences, _flagKey);
    if (done == true) return 0;

    var writes = 0;
    writes += await _salvageMeditation();
    writes += await _salvageTrading();
    writes += await _salvageBetting();
    writes += await _salvageFinance();
    writes += await _salvageReading();
    writes += await _salvageWriting();
    writes += await _salvageWork();
    writes += await _salvageLife();

    await HiveService.put(
      HiveBoxes.userPreferences,
      _flagKey,
      true,
    );
    return writes;
  }

  // ── Feature salvagers ──────────────────────────────────────────────────

  static Future<int> _salvageMeditation() async {
    final repo = MeditationRepository();
    final sessions = repo.loadAllSessions().where((s) => s.completed).toList();
    final byDay = <DateTime, Map<String, num>>{};
    for (final s in sessions) {
      final day = _midnight(s.completedAt ?? s.startedAt);
      final bucket = byDay.putIfAbsent(day, () => {'sessions': 0, 'totalSeconds': 0});
      bucket['sessions']     = (bucket['sessions']     ?? 0) + 1;
      bucket['totalSeconds'] = (bucket['totalSeconds'] ?? 0) + s.durationSeconds;
    }
    return _writeAll(TrackingFeature.meditation, byDay);
  }

  static Future<int> _salvageTrading() async {
    final repo = TradingRepository();
    final entries = repo.loadAllJournal();
    final byDay = <DateTime, Map<String, num>>{};
    for (final e in entries) {
      final day = _midnight(e.createdAt);
      final bucket = byDay.putIfAbsent(day, () => {});
      if (e.type == JournalEntryType.trade && e.outcome != TradeOutcome.pending) {
        bucket['trades'] = (bucket['trades'] ?? 0) + 1;
        if (e.outcome == TradeOutcome.win) {
          bucket['wins'] = (bucket['wins'] ?? 0) + 1;
        } else if (e.outcome == TradeOutcome.loss) {
          bucket['losses'] = (bucket['losses'] ?? 0) + 1;
        }
        if (e.pnl != null) {
          bucket['pnl'] = (bucket['pnl'] ?? 0) + e.pnl!;
        }
      } else if (e.type == JournalEntryType.sessionReview) {
        bucket['sessions'] = (bucket['sessions'] ?? 0) + 1;
        if (e.tradesTaken != null) {
          bucket['trades'] = (bucket['trades'] ?? 0) + e.tradesTaken!;
        }
        if (e.wins != null) {
          bucket['wins'] = (bucket['wins'] ?? 0) + e.wins!;
        }
        if (e.losses != null) {
          bucket['losses'] = (bucket['losses'] ?? 0) + e.losses!;
        }
        if (e.netPnl != null) {
          bucket['pnl'] = (bucket['pnl'] ?? 0) + e.netPnl!;
        }
      }
    }
    return _writeAll(TrackingFeature.trading, byDay);
  }

  static Future<int> _salvageBetting() async {
    final repo = BettingRepository();

    final byDay = <DateTime, Map<String, num>>{};

    // Individual bets — settled ones contribute wins/losses/pnl.
    final bets = repo.loadAllBets();
    for (final b in bets) {
      if (!b.isSettled || b.settledAt == null) continue;
      final day = _midnight(b.settledAt!);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['stepsSettled'] = (bucket['stepsSettled'] ?? 0) + 1;
      if (b.status == BetStatus.won) {
        bucket['wins'] = (bucket['wins'] ?? 0) + 1;
      } else if (b.status == BetStatus.lost) {
        bucket['losses'] = (bucket['losses'] ?? 0) + 1;
      }
      bucket['pnl'] = (bucket['pnl'] ?? 0) + b.profitLoss;
    }

    // Plan steps — settled steps contribute similarly.
    final plans = repo.loadPlans();
    for (final p in plans) {
      for (final s in p.steps) {
        if (s.status == BettingPlanStepStatus.pending || s.settledAt == null) {
          continue;
        }
        final day = _midnight(s.settledAt!);
        final bucket = byDay.putIfAbsent(day, () => {});
        bucket['stepsSettled'] = (bucket['stepsSettled'] ?? 0) + 1;
        if (s.status == BettingPlanStepStatus.won) {
          bucket['wins']   = (bucket['wins']   ?? 0) + 1;
          bucket['pnl']    = (bucket['pnl']    ?? 0) + (s.potentialReturn - s.stake);
          bucket['kept']   = (bucket['kept']   ?? 0) + s.kept;
        } else {
          bucket['losses'] = (bucket['losses'] ?? 0) + 1;
          bucket['pnl']    = (bucket['pnl']    ?? 0) - s.stake;
        }
      }
    }

    return _writeAll(TrackingFeature.betting, byDay);
  }

  static Future<int> _salvageFinance() async {
    final repo = FinanceRepository();
    final txs = repo.loadAllTransactions();
    final byDay = <DateTime, Map<String, num>>{};
    for (final t in txs) {
      final day = _midnight(t.transactionDate);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['logs'] = (bucket['logs'] ?? 0) + 1;
      if (t.type == TransactionType.income) {
        bucket['income'] = (bucket['income'] ?? 0) + t.amount;
      } else if (t.type == TransactionType.expense) {
        bucket['expense'] = (bucket['expense'] ?? 0) + t.amount;
      }
    }
    return _writeAll(TrackingFeature.finance, byDay);
  }

  static Future<int> _salvageReading() async {
    final repo = ReadingRepository();

    final byDay = <DateTime, Map<String, num>>{};

    for (final h in repo.loadAllHighlights()) {
      final day = _midnight(h.savedAt);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['highlights'] = (bucket['highlights'] ?? 0) + 1;
    }
    for (final n in repo.loadAllNotes()) {
      final day = _midnight(n.createdAt);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['notes'] = (bucket['notes'] ?? 0) + 1;
    }
    for (final v in repo.loadAllVocab()) {
      final day = _midnight(v.savedAt);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['vocab'] = (bucket['vocab'] ?? 0) + 1;
    }
    for (final b in repo.loadAllBooks()) {
      if (b.status == BookStatus.completed && b.completedAt != null) {
        final day = _midnight(b.completedAt!);
        final bucket = byDay.putIfAbsent(day, () => {});
        bucket['booksCompleted'] = (bucket['booksCompleted'] ?? 0) + 1;
      }
    }

    return _writeAll(TrackingFeature.reading, byDay);
  }

  static Future<int> _salvageWriting() async {
    final repo = WritingRepository();
    final sessions = repo.loadAllSessions();
    final byDay = <DateTime, Map<String, num>>{};
    for (final s in sessions) {
      final day = _midnight(s.createdAt);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['entries']      = (bucket['entries']      ?? 0) + 1;
      bucket['words']        = (bucket['words']        ?? 0) + s.wordCount;
      bucket['totalSeconds'] = (bucket['totalSeconds'] ?? 0) + s.durationSeconds;
    }
    return _writeAll(TrackingFeature.writing, byDay);
  }

  static Future<int> _salvageWork() async {
    final repo = WorkRepository();
    final tasks = repo.loadAllTasks();
    final byDay = <DateTime, Map<String, num>>{};
    for (final t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final day = _midnight(t.completedAt!);
      final bucket = byDay.putIfAbsent(day, () => {});
      bucket['tasksCompleted'] = (bucket['tasksCompleted'] ?? 0) + 1;
    }
    return _writeAll(TrackingFeature.work, byDay);
  }

  static Future<int> _salvageLife() async {
    final repo = LifeRepository();

    final numericByDay = <DateTime, Map<String, num>>{};

    for (final w in repo.loadAllWorkouts()) {
      final day = _midnight(w.completedAt);
      final bucket = numericByDay.putIfAbsent(day, () => {});
      bucket['workouts']       = (bucket['workouts']       ?? 0) + 1;
      bucket['workoutMinutes'] = (bucket['workoutMinutes'] ?? 0) + w.durationMinutes;
    }

    for (final r in repo.loadAllRecoverySessions()) {
      if (r.active || r.endedAt == null) continue;
      final day = _midnight(r.startedAt);
      final bucket = numericByDay.putIfAbsent(day, () => {});
      bucket['recoverySessions'] =
          (bucket['recoverySessions'] ?? 0) + 1;
      bucket['recoverySeconds']  = (bucket['recoverySeconds'] ?? 0) +
          r.endedAt!.difference(r.startedAt).inSeconds;
    }

    // Health logs are snapshot-shaped (last-wins per day), so we take the
    // most recent log per local day and write its fields via _writeSnapshot.
    final latestHealthByDay = <DateTime, HealthLogModel>{};
    for (final h in repo.loadAllHealthLogs()) {
      final day = _midnight(h.loggedAt);
      final existing = latestHealthByDay[day];
      if (existing == null || h.loggedAt.isAfter(existing.loggedAt)) {
        latestHealthByDay[day] = h;
      }
    }
    final healthByDay = <DateTime, Map<String, dynamic>>{};
    for (final entry in latestHealthByDay.entries) {
      final h = entry.value;
      final snap = <String, dynamic>{};
      if (h.sleepHours   != null) snap['sleepHours']   = h.sleepHours;
      if (h.waterGlasses != null) snap['waterGlasses'] = h.waterGlasses;
      if (h.steps        != null) snap['steps']        = h.steps;
      snap['energyLevel'] = h.energyLevel.index;
      if (snap.isNotEmpty) healthByDay[entry.key] = snap;
    }

    final n1 = await _writeAll(TrackingFeature.life, numericByDay);
    final n2 = await _writeSnapshot(TrackingFeature.life, healthByDay);
    return n1 + n2;
  }

  // ── Internal ───────────────────────────────────────────────────────────

  static DateTime _midnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Writes each (day, data) bucket via [TrackingService.setKeys] so that
  /// subsequent salvagers for the same feature/day (e.g. life workouts +
  /// life health log) merge into one record rather than overwriting.
  /// Safe because salvage is gated by a one-shot flag — no live records
  /// exist yet to double-count.
  static Future<int> _writeAll(
    TrackingFeature feature,
    Map<DateTime, Map<String, num>> byDay,
  ) async {
    if (byDay.isEmpty) return 0;
    for (final entry in byDay.entries) {
      await TrackingService.setKeys(
        feature,
        entry.value.map((k, v) => MapEntry(k, v)),
        atLocalDay: entry.key,
      );
    }
    return byDay.length;
  }

  /// Partial-merge variant for mixed numeric + non-numeric snapshot data
  /// (e.g. health log fields where energyLevel is an enum index).
  static Future<int> _writeSnapshot(
    TrackingFeature feature,
    Map<DateTime, Map<String, dynamic>> byDay,
  ) async {
    if (byDay.isEmpty) return 0;
    for (final entry in byDay.entries) {
      await TrackingService.setKeys(
        feature,
        entry.value,
        atLocalDay: entry.key,
      );
    }
    return byDay.length;
  }
}
