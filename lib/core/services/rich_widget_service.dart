// lib/core/services/rich_widget_service.dart

import 'package:flutter/services.dart';

import '../../feature/betting/model/sport_news_model.dart';
import '../../feature/betting/repository/betting_repository.dart';
import '../../feature/life/model/habit_model.dart';
import '../../feature/life/model/health_log_model.dart';
import '../../feature/life/repository/life_repository.dart';
import '../../feature/milestones/model/milestone.dart';
import '../../feature/milestones/repository/milestone_repository.dart';
import '../../feature/trading/model/news_event.dart';
import '../../feature/trading/repository/trading_repository.dart';
import '../../feature/work/model/meeting_model.dart';
import '../../feature/work/model/task_model.dart';
import '../../feature/work/repository/work_repository.dart';

class RichWidgetService {
  RichWidgetService._();
  static final RichWidgetService instance = RichWidgetService._();

  static const MethodChannel _channel = MethodChannel('com.rich.app/widget');

  Future<void> refresh({
    List<NewsEvent> tradingNews = const [],
    List<SportNewsArticle> bettingNews = const [],
  }) async {
    try {
      final snapshot = _buildSnapshot(
        tradingNews: tradingNews,
        bettingNews: bettingNews,
      );
      await _channel.invokeMethod<void>('saveSnapshot', snapshot);
    } catch (_) {
      // Widgets are supportive surface area. A platform failure must never
      // affect the main Flutter app.
    }
  }

  Map<String, String> _buildSnapshot({
    required List<NewsEvent> tradingNews,
    required List<SportNewsArticle> bettingNews,
  }) {
    final workRepo = WorkRepository();
    final lifeRepo = LifeRepository();
    final tradingRepo = TradingRepository();
    final bettingRepo = BettingRepository();
    final milestoneRepo = MilestoneRepository();

    final tasks = workRepo.loadTodayTasks();
    final meetings = workRepo.loadUpcomingMeetings();
    final habits = lifeRepo.loadHabits();
    final health = lifeRepo.loadTodayHealthLog();
    final workouts = lifeRepo.loadTodayWorkouts();
    final recovery = lifeRepo.loadActiveRecoverySession();
    final brokerInfo = tradingRepo.loadBrokerInfo();
    final startingCapital = tradingRepo.loadStartingCapital();
    final openTrades = tradingRepo.loadBrokerTrades().where((t) => t.isOpen);
    final bankroll = bettingRepo.loadBankroll();
    final activeBets = bettingRepo.loadActiveBets();
    final activePlan = bettingRepo
        .loadPlans()
        .where((p) => p.isActive)
        .toList();
    final milestone = milestoneRepo
        .loadAll()
        .where((m) => m.isActive)
        .cast<Milestone>()
        .toList();

    final work = _nextWorkItem(tasks, meetings);
    final life = _lifeDiscipline(habits, recovery, workouts.isNotEmpty);
    final nextMilestone = _nextMilestone(milestone);

    final tradingAmount = brokerInfo != null
        ? '${brokerInfo.currency} ${_money(brokerInfo.equity)} equity'
        : startingCapital > 0
        ? 'USD ${_money(startingCapital)} capital'
        : 'Trading capital not set';
    final tradeRisk = '${openTrades.length} open trade(s)';

    final bettingAmount =
        'TZS ${_money(bankroll.currentBalance)} · ${activeBets.length} live bet(s)';
    final bettingPlan = activePlan.isEmpty
        ? 'No active plan'
        : '${activePlan.first.name} active';

    return {
      'nextWorkTitle': work.title,
      'nextWorkMeta': work.meta,
      'lifeTitle': life.title,
      'lifeMeta': life.meta,
      'healthTitle': health == null
          ? 'Health status not logged'
          : 'Energy ${health.energyLevel.shortLabel}',
      'healthMeta': health == null
          ? 'Log sleep, water, steps'
          : '${health.sleepHours ?? 0}h sleep · ${health.waterGlasses ?? 0} water · ${health.steps ?? 0} steps',
      'tradingAmount': tradingAmount,
      'tradingMeta': tradeRisk,
      'bettingAmount': bettingAmount,
      'bettingMeta': bettingPlan,
      'tradingNews': tradingNews.isEmpty
          ? 'Trading news will appear after the feed updates'
          : tradingNews.first.headline,
      'bettingNews': bettingNews.isEmpty
          ? 'Betting news will appear after sport news loads'
          : bettingNews.first.headline,
      'milestoneTitle': nextMilestone.title,
      'milestoneMeta': nextMilestone.meta,
      'updatedAt': _hhmm(DateTime.now()),
    };
  }

  _WidgetLine _nextWorkItem(
    List<TaskModel> tasks,
    List<MeetingModel> meetings,
  ) {
    final openTasks = tasks.where((t) => !t.isCompleted && !t.isBlocked);
    final upcomingTasks = openTasks.where((t) => t.scheduledStart != null);
    TaskModel? nextTask;
    for (final task in upcomingTasks) {
      if (nextTask == null ||
          task.scheduledStart!.isBefore(nextTask.scheduledStart!)) {
        nextTask = task;
      }
    }
    nextTask ??= openTasks.isEmpty ? null : openTasks.first;

    final nextMeeting = meetings.isEmpty ? null : meetings.first;
    if (nextTask == null && nextMeeting == null) {
      return const _WidgetLine('Work clear', 'No open task or meeting');
    }
    if (nextTask != null && nextMeeting != null) {
      final taskTime = nextTask.scheduledStart;
      if (taskTime == null || nextMeeting.scheduledAt.isBefore(taskTime)) {
        return _WidgetLine(
          nextMeeting.title,
          'Meeting · ${_hhmm(nextMeeting.scheduledAt)}',
        );
      }
    }
    return _WidgetLine(
      nextTask!.title,
      nextTask.scheduledStart == null
          ? '${nextTask.priority.label} task'
          : 'Task · ${_hhmm(nextTask.scheduledStart!)}',
    );
  }

  _WidgetLine _lifeDiscipline(
    List<HabitModel> habits,
    dynamic recovery,
    bool workedOutToday,
  ) {
    if (recovery != null) {
      return const _WidgetLine('Recovery active', 'Stay in discipline mode');
    }
    final pending = habits.where((h) => !h.completedToday).toList()
      ..sort((a, b) {
        if (a.streakAtRisk && !b.streakAtRisk) return -1;
        if (!a.streakAtRisk && b.streakAtRisk) return 1;
        return b.currentStreak.compareTo(a.currentStreak);
      });
    if (pending.isNotEmpty) {
      final h = pending.first;
      return _WidgetLine(
        h.name,
        h.streakAtRisk ? 'Streak at risk' : '${h.currentStreak} day streak',
      );
    }
    if (!workedOutToday) {
      return const _WidgetLine('Workout', 'Move today');
    }
    return const _WidgetLine('Life checklist clear', 'Keep the standard');
  }

  _WidgetLine _nextMilestone(List<Milestone> milestones) {
    if (milestones.isEmpty) {
      return const _WidgetLine(
        'No active milestone',
        'Create a 6-month target',
      );
    }
    milestones.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.isAtRisk && !b.isAtRisk) return -1;
      if (!a.isAtRisk && b.isAtRisk) return 1;
      return a.targetDate.compareTo(b.targetDate);
    });
    final m = milestones.first;
    final days = m.targetDate.difference(DateTime.now()).inDays;
    final status = m.isOverdue
        ? 'Overdue'
        : m.isAtRisk
        ? 'At risk'
        : days <= 0
        ? 'Due today'
        : '$days day(s) left';
    return _WidgetLine(m.title, '$status · ${(m.progress * 100).round()}%');
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _money(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _WidgetLine {
  final String title;
  final String meta;
  const _WidgetLine(this.title, this.meta);
}
