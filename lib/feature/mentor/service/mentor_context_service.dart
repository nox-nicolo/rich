// lib/feature/mentor/service/mentor_context_service.dart

import '../../../core/services/accountability_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';
import '../../finance/model/finance_models.dart';
import '../../finance/repository/finance_repository.dart';
import '../../meditation/repository/meditation_repository.dart';
import '../../milestones/repository/milestone_repository.dart';
import '../../trading/repository/trading_repository.dart';
import '../model/mentor_models.dart';

class MentorContextService {
  MentorContextSnapshot build() {
    return MentorContextSnapshot(
      coreGoals: _coreGoals(),
      currentStreaks: _currentStreaks(),
      savingsProgress: _savingsProgress(),
      missedActivities: _missedActivities(),
      activeGoals: _activeGoals(),
      patterns: _patterns(),
    );
  }

  String _coreGoals() {
    return [
      'Build financial discipline: log money, protect savings, avoid careless betting.',
      'Maintain meditation as the gatekeeper habit before trading or betting.',
      'Trade with journaled discipline, not impulse.',
      'Read, write, work deeply, and train the body every week.',
      'Use RICH daily so failures are visible instead of hidden.',
    ].join('\n');
  }

  String _currentStreaks() {
    final meditation = MeditationRepository().loadStreak();
    return 'Meditation streak: ${meditation.currentStreak} day(s), best ${meditation.longestStreak}.';
  }

  String _savingsProgress() {
    final repo = FinanceRepository();
    final summary = repo.loadThisMonthSummary();
    final allocation = repo.loadLatestAllocationForCategory(
      FinanceCategory.saving,
      FinancePeriod.monthly,
    );
    final target = allocation?.allocatedAmount ?? 0;
    final actual = summary.incomeFor(FinanceCategory.saving);
    if (target <= 0) {
      return 'No monthly savings target is configured. Actual saved this month: ${actual.toStringAsFixed(0)}.';
    }
    final remaining = target - actual;
    return 'Monthly savings target ${target.toStringAsFixed(0)}, actual ${actual.toStringAsFixed(0)}, remaining ${remaining.toStringAsFixed(0)}.';
  }

  String _missedActivities() {
    final flags = AccountabilityService.yesterdayRedFlags();
    if (flags.isEmpty) return 'Yesterday has no missed activities recorded.';
    return flags.entries.map((e) => '${e.key.label}: ${e.value}').join('\n');
  }

  String _activeGoals() {
    final tradingTarget = TradingRepository()
        .loadTargets()
        .where((t) => t.status.name == 'active')
        .map(
          (t) =>
              'Trading target: ${t.title}, ${t.currentCapital.toStringAsFixed(0)} / ${t.targetCapital.toStringAsFixed(0)}, lot ${t.lotSize}.',
        )
        .toList();
    final milestones = MilestoneRepository()
        .loadAll()
        .where((m) => m.status.name == 'active')
        .take(5)
        .map((m) => 'Milestone: ${m.title}')
        .toList();
    final all = [...tradingTarget, ...milestones];
    return all.isEmpty ? 'No active goals found in Hive.' : all.join('\n');
  }

  String _patterns() {
    final lines = <String>[];
    for (final feature in TrackingFeature.values) {
      var missed = 0;
      final records = TrackingService.recentDailies(feature, days: 14);
      for (int i = 0; i < 14; i++) {
        final day = DateTime.now().subtract(Duration(days: i));
        final hasRecord = records.any(
          (r) =>
              r.date.year == day.year &&
              r.date.month == day.month &&
              r.date.day == day.day,
        );
        if (!hasRecord) missed++;
      }
      if (missed >= 5) {
        lines.add('${feature.label}: skipped or unrecorded $missed/14 days.');
      }
    }
    return lines.isEmpty
        ? 'Not enough repeated failure patterns yet, or no major 14-day skip pattern.'
        : lines.join('\n');
  }
}
