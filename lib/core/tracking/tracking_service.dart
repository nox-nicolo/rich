// lib/core/tracking/tracking_service.dart
//
// Central gateway for per-feature activity recording and retention.
//
// The retention policy:
//
//   • Today:           live from each feature's own state.
//   • Yesterday → 35d: DailyRecord entries in the `daily_records` box.
//   • Older than 35d:  Folded into a MonthlyReport in the `monthly_reports`
//                      box, per-feature summed — then the dailies are
//                      deleted.
//
// runRetention() is idempotent: it's safe to call on every app start
// and it will only do work if there are dailies beyond the window.

import '../constants/hive_boxes.dart';
import '../services/hive_service.dart';
import 'model/daily_record.dart';
import 'model/monthly_report.dart';
import 'tracking_feature.dart';

class TrackingService {
  TrackingService._();

  static const int retentionDays = 24;

  // ── Recording ──────────────────────────────────────────────────────────

  /// Upsert today's record for the given feature. `data` is merged into any
  /// existing record — numeric fields add, non-numeric fields overwrite.
  ///
  /// Use this for increment-style writes ("user logged +1 session").
  static Future<void> record(
    TrackingFeature feature,
    Map<String, dynamic> data, {
    DateTime? atLocalDay,
  }) async {
    final day = _localMidnight(atLocalDay ?? DateTime.now());
    final key = DailyRecord.composeKey(feature, day);

    final existing = _readDaily(key);

    final merged = <String, dynamic>{};
    if (existing != null) merged.addAll(existing.data);
    for (final entry in data.entries) {
      final prev = merged[entry.key];
      final next = entry.value;
      if (prev is num && next is num) {
        merged[entry.key] = prev + next;
      } else if (prev is List && next is List) {
        // Lists (e.g. taskItems, meetingItems) get concatenated so every
        // task/meeting completed during the day is preserved for the report.
        merged[entry.key] = [...prev, ...next];
      } else {
        merged[entry.key] = next;
      }
    }

    final record = DailyRecord(
      feature:   feature,
      date:      day,
      data:      merged,
      updatedAt: DateTime.now(),
    );

    await HiveService.put(
      HiveBoxes.dailyRecords,
      key,
      record.toMap(),
    );
  }

  /// Overwrite only the given keys in today's record, preserving all other
  /// fields. Use this for snapshot-shaped metrics (sleepHours, waterGlasses,
  /// steps, energyLevel) where the latest value wins but additive counters
  /// on the same day (habitsCompleted, workouts) must not be wiped.
  static Future<void> setKeys(
    TrackingFeature feature,
    Map<String, dynamic> keys, {
    DateTime? atLocalDay,
  }) async {
    final day = _localMidnight(atLocalDay ?? DateTime.now());
    final key = DailyRecord.composeKey(feature, day);

    final existing = _readDaily(key);
    final merged = <String, dynamic>{};
    if (existing != null) merged.addAll(existing.data);
    merged.addAll(keys);

    final record = DailyRecord(
      feature:   feature,
      date:      day,
      data:      merged,
      updatedAt: DateTime.now(),
    );

    await HiveService.put(
      HiveBoxes.dailyRecords,
      key,
      record.toMap(),
    );
  }

  /// Replace today's record wholesale (used for snapshots like end-of-day
  /// balance where additive merging would double-count).
  static Future<void> setSnapshot(
    TrackingFeature feature,
    Map<String, dynamic> data, {
    DateTime? atLocalDay,
  }) async {
    final day = _localMidnight(atLocalDay ?? DateTime.now());
    final key = DailyRecord.composeKey(feature, day);

    final record = DailyRecord(
      feature:   feature,
      date:      day,
      data:      Map<String, dynamic>.from(data),
      updatedAt: DateTime.now(),
    );

    await HiveService.put(
      HiveBoxes.dailyRecords,
      key,
      record.toMap(),
    );
  }

  // ── Reading ────────────────────────────────────────────────────────────

  static DailyRecord? readDay(TrackingFeature feature, DateTime day) {
    return _readDaily(DailyRecord.composeKey(feature, _localMidnight(day)));
  }

  /// All daily records for a feature within the last [days] days (inclusive
  /// of today). Result is newest-first.
  static List<DailyRecord> recentDailies(
    TrackingFeature feature, {
    int days = retentionDays,
  }) {
    final cutoff = _localMidnight(
      DateTime.now().subtract(Duration(days: days - 1)),
    );
    return _allDailies()
        .where((r) => r.feature == feature && !r.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Every daily record currently stored, newest-first.
  static List<DailyRecord> allDailies() =>
      _allDailies()..sort((a, b) => b.date.compareTo(a.date));

  static List<MonthlyReport> allMonthlyReports() {
    final box = HiveService.box(HiveBoxes.monthlyReports);
    final out = <MonthlyReport>[];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final report = MonthlyReport.fromMap(Map<String, dynamic>.from(raw));
      if (report != null) out.add(report);
    }
    out.sort((a, b) => b.yearMonth.compareTo(a.yearMonth));
    return out;
  }

  // ── Retention ──────────────────────────────────────────────────────────

  /// Fold every daily record older than the retention window into its
  /// month's report, then delete the folded daily. Safe to call on every
  /// app launch.
  static Future<RetentionResult> runRetention() async {
    final cutoff = _localMidnight(
      DateTime.now().subtract(const Duration(days: retentionDays)),
    );

    final expired = _allDailies()
        .where((r) => r.date.isBefore(cutoff))
        .toList();
    if (expired.isEmpty) {
      return const RetentionResult(foldedCount: 0, monthsTouched: 0);
    }

    // Group by yearMonth so we only load each monthly report once.
    final byMonth = <String, List<DailyRecord>>{};
    for (final r in expired) {
      byMonth.putIfAbsent(r.yearMonth, () => []).add(r);
    }

    for (final entry in byMonth.entries) {
      final ym = entry.key;
      MonthlyReport report = _readMonthly(ym) ?? MonthlyReport.empty(ym);

      for (final r in entry.value) {
        report = report.mergeFeature(r.feature, r.data);
      }

      await HiveService.put(
        HiveBoxes.monthlyReports,
        ym,
        report.toMap(),
      );
    }

    final dailyBox = HiveService.box(HiveBoxes.dailyRecords);
    for (final r in expired) {
      await dailyBox.delete(r.key);
    }

    return RetentionResult(
      foldedCount:   expired.length,
      monthsTouched: byMonth.length,
    );
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  static DateTime _localMidnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DailyRecord? _readDaily(String key) {
    final raw = HiveService.get<Map>(HiveBoxes.dailyRecords, key);
    if (raw == null) return null;
    return DailyRecord.fromMap(Map<String, dynamic>.from(raw));
  }

  static MonthlyReport? _readMonthly(String ym) {
    final raw = HiveService.get<Map>(HiveBoxes.monthlyReports, ym);
    if (raw == null) return null;
    return MonthlyReport.fromMap(Map<String, dynamic>.from(raw));
  }

  static List<DailyRecord> _allDailies() {
    final box = HiveService.box(HiveBoxes.dailyRecords);
    final out = <DailyRecord>[];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final parsed = DailyRecord.fromMap(Map<String, dynamic>.from(raw));
      if (parsed != null) out.add(parsed);
    }
    return out;
  }
}

class RetentionResult {
  final int foldedCount;
  final int monthsTouched;

  const RetentionResult({
    required this.foldedCount,
    required this.monthsTouched,
  });
}
