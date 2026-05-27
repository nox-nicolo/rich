// lib/core/services/accountability_service.dart

import '../constants/hive_boxes.dart';
import '../tracking/model/daily_record.dart';
import '../tracking/tracking_feature.dart';
import '../../feature/finance/model/finance_models.dart';
import '../../feature/finance/repository/finance_repository.dart';
import '../../feature/rules_engine/model/rich_feature.dart';
import '../../feature/rules_engine/repository/rules_repository.dart';
import 'hive_service.dart';
import 'notification_service.dart';

class AccountabilityService {
  AccountabilityService._();

  static const _lastMorningKey = 'accountability_last_morning';
  static const _lastStreakWarningKey = 'accountability_last_streak_warning';
  static const _lastWeeklyKey = 'accountability_last_weekly';
  static const _lastSavingsMonthKey = 'accountability_last_savings_month';

  static Future<void> scheduleNotifications() async {
    final svc = NotificationService.instance;
    final now = DateTime.now();

    Future<void> scheduleNext({
      required int id,
      required int hour,
      required int minute,
      required String title,
      required String body,
      int? weekday,
    }) async {
      var time = DateTime(now.year, now.month, now.day, hour, minute);
      if (weekday != null) {
        while (time.weekday != weekday || time.isBefore(now)) {
          time = time.add(const Duration(days: 1));
        }
      } else if (time.isBefore(now)) {
        time = time.add(const Duration(days: 1));
      }

      await svc.schedule(
        id: id,
        title: title,
        body: body,
        scheduledTime: time,
        channel: NotificationChannel.critical,
        payload: 'dashboard',
      );
    }

    await scheduleNext(
      id: 101,
      hour: 6,
      minute: 0,
      title: 'Morning Accountability Report',
      body: 'Open RICH. Yesterday gets judged now.',
    );
    await scheduleNext(
      id: 102,
      hour: 22,
      minute: 0,
      title: 'Streak Death Warning',
      body: 'You have 2 hours. Finish the incomplete work or lose the streak.',
    );
    await scheduleNext(
      id: 103,
      hour: 7,
      minute: 0,
      weekday: DateTime.monday,
      title: 'Weekly Brutal Report',
      body: 'Open RICH. Last week gets audited now.',
    );
  }

  static Future<void> runDueChecks() async {
    await _runMorningReportIfDue();
    await _runStreakWarningIfDue();
    await _runWeeklyReportIfDue();
    await _applyMeditationEscalation();
    await _applySavingsEscalation();
  }

  static Map<TrackingFeature, String> yesterdayRedFlags() {
    final yesterday = _localDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final flags = <TrackingFeature, String>{};
    for (final feature in TrackingFeature.values) {
      final issues = _issuesForDay(feature, yesterday);
      if (issues.isNotEmpty) {
        flags[feature] = issues.first;
      }
    }
    return flags;
  }

  static Future<void> _runMorningReportIfDue() async {
    final now = DateTime.now();
    if (now.hour < 6) return;
    final todayKey = _dateKey(now);
    if (_stored(_lastMorningKey) == todayKey) return;

    final body = morningReportBody();
    await NotificationService.instance.show(
      id: 201,
      title: 'Morning Accountability Report',
      body: body,
      channel: NotificationChannel.critical,
      payload: 'dashboard',
    );
    await _store(_lastMorningKey, todayKey);
  }

  static Future<void> _runStreakWarningIfDue() async {
    final now = DateTime.now();
    if (now.hour < 22) return;
    final todayKey = _dateKey(now);
    if (_stored(_lastStreakWarningKey) == todayKey) return;

    final issues = todayIncompleteIssues();
    if (issues.isEmpty) return;

    await NotificationService.instance.show(
      id: 202,
      title: 'Streak Death Warning',
      body: 'You have 2 hours. ${issues.take(3).join(' ')}',
      channel: NotificationChannel.critical,
      payload: 'dashboard',
    );
    await _store(_lastStreakWarningKey, todayKey);
  }

  static Future<void> _runWeeklyReportIfDue() async {
    final now = DateTime.now();
    if (now.weekday != DateTime.monday || now.hour < 7) return;
    final weekKey = _dateKey(_weekStart(now));
    if (_stored(_lastWeeklyKey) == weekKey) return;

    await NotificationService.instance.show(
      id: 203,
      title: 'Weekly Brutal Report',
      body: weeklyReportBody(),
      channel: NotificationChannel.critical,
      payload: 'dashboard',
    );
    await _store(_lastWeeklyKey, weekKey);
  }

  static String morningReportBody() {
    final yesterday = _localDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final issues = <String>[];
    for (final feature in TrackingFeature.values) {
      issues.addAll(_issuesForDay(feature, yesterday));
    }
    if (issues.isEmpty) {
      return 'Yesterday (${_dateKey(yesterday)}) was complete. No misses recorded.';
    }

    final main = issues.first;
    final extra = issues.length - 1;
    final suffix = extra > 0 ? ' +$extra more gap(s).' : '';
    return 'Yesterday (${_dateKey(yesterday)}): $main$suffix Today: fix this first.';
  }

  static List<String> todayIncompleteIssues() {
    final today = _localDay(DateTime.now());
    final issues = <String>[];
    for (final feature in TrackingFeature.values) {
      issues.addAll(_issuesForDay(feature, today));
    }
    return issues;
  }

  static String weeklyReportBody() {
    final now = DateTime.now();
    final start = _weekStart(now).subtract(const Duration(days: 7));
    final end = start.add(const Duration(days: 6));
    final misses = <String>[];
    final completed = <String>[];

    for (final feature in TrackingFeature.values) {
      var goodDays = 0;
      var badDays = 0;
      for (int i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        if (_issuesForDay(feature, day).isEmpty) {
          goodDays++;
        } else {
          badDays++;
        }
      }
      completed.add('${feature.label}: $goodDays/7');
      if (badDays > 0) misses.add('${feature.label} missed $badDays day(s)');
    }

    final savings = _savingsLine(start, end);
    final trading = _tradingLine(start);
    final missed = misses.isEmpty ? 'No streaks broken.' : misses.join('. ');
    return '${completed.join(', ')}. $missed. $savings $trading';
  }

  static Future<void> _applyMeditationEscalation() async {
    final today = _localDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final beforeYesterday = today.subtract(const Duration(days: 2));
    final skippedTwo =
        _issuesForDay(TrackingFeature.meditation, yesterday).isNotEmpty &&
        _issuesForDay(TrackingFeature.meditation, beforeYesterday).isNotEmpty;

    if (!skippedTwo) return;

    final repo = RulesRepository();
    final locks = repo.loadLockedFeatures()
      ..add(RichFeature.trading)
      ..add(RichFeature.betting);
    await repo.saveLockedFeatures(locks);
  }

  static Future<void> _applySavingsEscalation() async {
    final now = DateTime.now();
    if (now.day == 1) return;

    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final monthKey = '${previousMonth.year}-${previousMonth.month}';
    if (_stored(_lastSavingsMonthKey) == monthKey) return;

    final repo = FinanceRepository();
    final start = previousMonth;
    final end = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
      23,
      59,
      59,
    );
    final summary = FinanceReportHelper.buildSummary(
      period: FinancePeriod.monthly,
      startDate: start,
      endDate: end,
      transactions: repo.loadTransactionsInRange(start: start, end: end),
    );
    final allocation = repo.loadLatestAllocationForCategory(
      FinanceCategory.saving,
      FinancePeriod.monthly,
    );
    final target = allocation?.allocatedAmount ?? 0;
    if (target <= 0 || summary.incomeFor(FinanceCategory.saving) >= target) {
      await _store(_lastSavingsMonthKey, monthKey);
      return;
    }

    final rules = RulesRepository();
    final locks = rules.loadLockedFeatures()..add(RichFeature.betting);
    await rules.saveLockedFeatures(locks);
    await rules.saveCooldownExpiry(now.add(const Duration(days: 7)));
    await _store(_lastSavingsMonthKey, monthKey);
  }

  static List<String> _issuesForDay(TrackingFeature feature, DateTime day) {
    final record = _recordForDay(feature, day);
    final data = record?.data ?? const {};
    num n(String key) => data[key] is num ? data[key] as num : 0;

    switch (feature) {
      case TrackingFeature.meditation:
        if (record == null) return ['no meditation record was saved.'];
        return n('sessions') <= 0 ? ['you skipped meditation.'] : [];
      case TrackingFeature.trading:
        if (record == null) return ['no trading or journal record was saved.'];
        return n('sessions') <= 0 && n('trades') <= 0
            ? ['you did no trading session or journal.']
            : [];
      case TrackingFeature.betting:
        if (record == null) return ['no betting review record was saved.'];
        return n('stepsSettled') <= 0 && n('plansSettled') <= 0
            ? ['you ignored betting review.']
            : [];
      case TrackingFeature.finance:
        if (record == null) return ['no finance log was saved.'];
        return n('logs') <= 0 ? ['you did not log finance activity.'] : [];
      case TrackingFeature.reading:
        if (record == null) return ['no reading progress was saved.'];
        return n('pages') <= 0 ? ['you broke reading progress.'] : [];
      case TrackingFeature.writing:
        if (record == null) return ['no writing entry was saved.'];
        return n('entries') <= 0 &&
                n('updates') <= 0 &&
                n('words') <= 0 &&
                n('totalSeconds') <= 0
            ? ['you did not write.']
            : [];
      case TrackingFeature.work:
        if (record == null) return ['no work execution record was saved.'];
        return n('tasksCompleted') <= 0 && n('sessions') <= 0
            ? ['you left work execution blank.']
            : [];
      case TrackingFeature.life:
        if (record == null) {
          return ['no life habit or workout record was saved.'];
        }
        return n('habitsCompleted') <= 0 && n('workouts') <= 0
            ? ['you ignored life habits.']
            : [];
    }
  }

  static Map<String, dynamic> _recordData(
    TrackingFeature feature,
    DateTime day,
  ) {
    return _recordForDay(feature, day)?.data ?? const {};
  }

  static DailyRecord? _recordForDay(TrackingFeature feature, DateTime day) {
    final key = DailyRecord.composeKey(feature, _localDay(day));
    final raw = HiveService.get<Map>(HiveBoxes.dailyRecords, key);
    if (raw == null) return null;
    return DailyRecord.fromMap(Map<String, dynamic>.from(raw));
  }

  static String _savingsLine(DateTime start, DateTime end) {
    final repo = FinanceRepository();
    final summary = FinanceReportHelper.buildSummary(
      period: FinancePeriod.weekly,
      startDate: start,
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
      transactions: repo.loadTransactionsInRange(
        start: start,
        end: DateTime(end.year, end.month, end.day, 23, 59, 59),
      ),
    );
    return 'Savings actual: ${summary.incomeFor(FinanceCategory.saving).toStringAsFixed(0)}.';
  }

  static String _tradingLine(DateTime weekStart) {
    var sessions = 0;
    for (int i = 0; i < 7; i++) {
      final data = _recordData(
        TrackingFeature.trading,
        weekStart.add(Duration(days: i)),
      );
      final raw = data['sessions'];
      sessions += raw is num ? raw.toInt() : 0;
    }
    return 'Trading sessions completed: $sessions/7.';
  }

  static DateTime _localDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static DateTime _weekStart(DateTime dt) {
    final day = _localDay(dt);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static String _dateKey(DateTime dt) {
    final d = _localDay(dt);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String? _stored(String key) =>
      HiveService.get<String>(HiveBoxes.dashboardSummary, key);

  static Future<void> _store(String key, String value) =>
      HiveService.put(HiveBoxes.dashboardSummary, key, value);
}
