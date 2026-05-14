// lib/features/dashboard/viewmodel/dashboard_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/pillar_summary_model.dart';
import '../repository/dashboard_repository.dart';
import '../../../providers/providers.dart';
import '../../../core/services/accountability_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../meditation/viewmodel/meditation_viewmodel.dart';
import '../../work/viewmodel/work_viewmodel.dart';
import '../../trading/viewmodel/trading_viewmodel.dart';
import '../../betting/viewmodel/betting_viewmodel.dart';
import '../../reading/viewmodel/reading_viewmodel.dart';
import '../../finance/viewmodel/finance_viewmodel.dart';
import '../../life/viewmodel/life_viewmodel.dart';

// ── ViewModel ─────────────────────────────────────────────────────────────────

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  final Ref _ref;

  DashboardViewModel(this._repo, this._ref) : super(DashboardState.initial()) {
    _load();
    // Modules write routine progress directly to Hive. Listen to each one
    // and re-read routine progress when they change. Using _ref.listen here
    // (rather than Future.microtask in pillarSummariesProvider) avoids the
    // "cannot use ref after dependency changed but before rebuild" assertion.
    _ref.listen(meditationViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(workViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(tradingViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(bettingViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(readingViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(financeViewModelProvider, (_, __) => refreshRoutine());
    _ref.listen(lifeViewModelProvider, (_, __) => refreshRoutine());
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  void _load() {
    final score = _repo.loadScore();
    final routine = _repo.loadRoutineProgress();
    final readiness = _repo.loadReadiness();

    state = state.copyWith(
      disciplineScore: score,
      routineProgress: routine,
      mentalReadiness: readiness,
      isLoading: false,
    );

    _updateNextAction();
    _deriveReadiness();
  }

  // ── Routine ───────────────────────────────────────────────────────────────

  /// Re-reads routine progress from Hive (called when other modules update it).
  void refreshRoutine() {
    final routine = _repo.loadRoutineProgress();
    if (routine.toString() != state.routineProgress.toString()) {
      state = state.copyWith(routineProgress: routine);
      _recalculateScore();
      _updateNextAction();
    }
    // Mind readiness is derived, not user-entered. Re-derive whenever any
    // upstream signal moves.
    _deriveReadiness();
  }

  // ── Mind Readiness — auto-derived ─────────────────────────────────────────
  //
  // Inputs (all optional, all live):
  //   +2  meditation gate completed today
  //   +1  any extra meditation session beyond the first
  //   +1  workout logged today
  //   −2  mood marked unstable (from meditation mood-check)
  //
  // Mapping:
  //   no inputs at all → unchecked (still neutral early in the day)
  //   score ≤ 0        → LOW
  //   score 1..2       → MODERATE
  //   score ≥ 3        → SHARP (high)

  void _deriveReadiness() {
    final ruleCtx = _ref.read(ruleContextProvider);
    final meditation = _ref.read(meditationViewModelProvider);
    final life = _ref.read(lifeViewModelProvider);

    int score = 0;
    bool anySignal = false;

    if (ruleCtx.meditationCompletedToday) {
      score += 2;
      anySignal = true;
    }
    if (meditation.todaySessions.length > 1) {
      score += 1;
      anySignal = true;
    }
    if (life.hasWorkedOutToday) {
      score += 1;
      anySignal = true;
    }
    if (ruleCtx.isEmotionallyUnstable) {
      score -= 2;
      anySignal = true;
    }

    final MentalReadiness next;
    if (!anySignal) {
      next = MentalReadiness.unchecked;
    } else if (score <= 0) {
      next = MentalReadiness.low;
    } else if (score <= 2) {
      next = MentalReadiness.medium;
    } else {
      next = MentalReadiness.high;
    }

    if (next != state.mentalReadiness) {
      state = state.copyWith(mentalReadiness: next);
      _repo.saveReadiness(next);
    }
  }

  // ── Score ─────────────────────────────────────────────────────────────────

  void _recalculateScore() {
    final rate = state.routineCompletionRate;
    final ruleCtx = _ref.read(ruleContextProvider);
    final lockedCount = ruleCtx.lockedFeatures.length;

    int score = (rate * 60).round();
    if (ruleCtx.meditationCompletedToday) score += 20;
    if (lockedCount == 0) score += 20;
    score = score.clamp(0, 100);

    state = state.copyWith(disciplineScore: score);
    _repo.saveScore(score);
  }

  // ── Next Action — time-aware ──────────────────────────────────────────────

  void _updateNextAction() {
    final ruleCtx = _ref.read(ruleContextProvider);
    final hour = DateTime.now().hour;
    String action;
    String route = '/meditation';

    if (!ruleCtx.meditationCompletedToday) {
      if (hour < 7) {
        action = 'Meditation — Prayer (5 min)';
      } else if (hour < 10) {
        action = 'Meditation — Breathing (10 min)';
      } else {
        action = 'Meditation — Stillness (15 min)';
      }
      route = '/meditation';
    } else if (hour >= 5 && hour < 9) {
      if (state.routineProgress['Workout'] == false) {
        action = 'Workout — morning training block';
        route = '/life';
      } else {
        action = 'Morning complete. Start your first Work block.';
        route = '/work';
      }
    } else if (hour >= 9 && hour < 13) {
      final workState = _ref.read(workViewModelProvider);
      final pending = workState.todayTasks
          .where((t) => !t.isCompleted)
          .toList();
      if (pending.isNotEmpty) {
        final top = pending.first;
        action = 'Work — ${top.title} (${top.priority.name.toUpperCase()})';
      } else if (state.routineProgress['Deep Work'] == false) {
        action = 'Work — Deep Work block (90 min)';
      } else {
        action = 'Work — review next task or start session';
      }
      route = '/work';
    } else if (hour >= 13 && hour < 15) {
      final readingState = _ref.read(readingViewModelProvider);
      final active = readingState.allBooks
          .where((b) => b.readTodayAlready)
          .toList();
      if (state.routineProgress['Reading'] == false) {
        if (active.isNotEmpty) {
          final book = active.first;
          action =
              'Reading — ${book.title} (p. ${book.currentPage}/${book.totalPages})';
        } else {
          action = 'Reading — 20 min focused read';
        }
        route = '/reading';
      } else {
        action = 'Work — afternoon task block';
        route = '/work';
      }
    } else if (hour >= 15 && hour < 18) {
      final tradingState = _ref.read(tradingViewModelProvider);
      if (!ruleCtx.lockedFeatures.contains(RichFeature.trading)) {
        if (tradingState.sessionActive) {
          action = 'Trading — session live, stay disciplined';
        } else {
          action = 'Trading — review bias & open session';
        }
        route = '/trading';
      } else {
        action = 'Work — complete remaining tasks';
        route = '/work';
      }
    } else if (hour >= 18 && hour < 21) {
      final bettingState = _ref.read(bettingViewModelProvider);
      if (bettingState.activeBets.isNotEmpty) {
        action =
            'Betting — ${bettingState.activeBets.length} active bet(s) to settle';
        route = '/betting';
      } else if (state.routineProgress['Journaling'] == false) {
        action = 'Journal — write today\'s reflection';
        route = '/writing';
      } else {
        action = 'Evening review — check scores & plan tomorrow';
        route = '/';
      }
    } else {
      if (state.routineProgress['Journaling'] == false) {
        action = 'Journal — end of day reflection';
        route = '/writing';
      } else {
        action = 'All done. Rest and recover.';
        route = '/';
      }
    }

    state = state.copyWith(nextRequiredAction: action, nextActionRoute: route);
    _repo.saveNextAction(action);
  }

  // ── Mental Readiness ──────────────────────────────────────────────────────

  Future<void> setMentalReadiness(MentalReadiness readiness) async {
    state = state.copyWith(mentalReadiness: readiness);
    await _repo.saveReadiness(readiness);
    _ref
        .read(ruleContextProvider.notifier)
        .setEmotionalState(readiness == MentalReadiness.low);
  }

  // ── News Impact ───────────────────────────────────────────────────────────

  void setHighImpactNews(bool hasNews) {
    state = state.copyWith(hasHighImpactNews: hasNews);
  }

  // ── Pillar Summaries (derived, with real stats) ───────────────────────────

  List<PillarSummary> get pillarSummaries {
    final lockedFeatures = _ref.read(lockedFeaturesProvider);
    final ruleCtx = _ref.read(ruleContextProvider);
    final meditationState = _ref.read(meditationViewModelProvider);
    final workState = _ref.read(workViewModelProvider);
    final tradingState = _ref.read(tradingViewModelProvider);
    final bettingState = _ref.read(bettingViewModelProvider);
    final readingState = _ref.read(readingViewModelProvider);
    final redFlags = AccountabilityService.yesterdayRedFlags();

    return PillarDefinitions.all.map((p) {
      final locked = lockedFeatures.contains(p.feature);
      final redFlag = redFlags[_trackingFeatureFor(p.feature)];
      if (redFlag != null && !locked) {
        return p.copyWith(
          status: PillarStatus.warning,
          statusDetail: 'Yesterday: $redFlag',
        );
      }

      switch (p.feature) {
        case RichFeature.meditation:
          if (ruleCtx.meditationCompletedToday) {
            return p.copyWith(
              status: PillarStatus.completed,
              statusDetail:
                  'Streak ${meditationState.streak.currentStreak}d — gate open',
            );
          }
          final sessions = meditationState.todaySessions.length;
          return p.copyWith(
            status: PillarStatus.idle,
            statusDetail: sessions > 0
                ? '$sessions session(s) today'
                : 'Not done — gate closed',
          );

        case RichFeature.work:
          if (locked) return p.copyWith(status: PillarStatus.locked);
          final pending = workState.todayTasks
              .where((t) => !t.isCompleted)
              .length;
          final completed = workState.todayTasks
              .where((t) => t.isCompleted)
              .length;
          final active = workState.activeSession != null;
          return p.copyWith(
            status: active ? PillarStatus.active : PillarStatus.idle,
            statusDetail: active
                ? 'Session active — $pending tasks left'
                : '$completed done · $pending pending',
          );

        case RichFeature.trading:
          if (locked) {
            return p.copyWith(
              status: PillarStatus.locked,
              statusDetail: 'Complete meditation to unlock',
            );
          }
          if (tradingState.sessionActive) {
            return p.copyWith(
              status: PillarStatus.active,
              statusDetail: 'Session live',
            );
          }
          return p.copyWith(
            status: PillarStatus.idle,
            statusDetail: 'Gate open — no active session',
          );

        case RichFeature.betting:
          if (locked) {
            return p.copyWith(
              status: PillarStatus.locked,
              statusDetail: bettingState.isLocked ? 'Locked' : 'Unavailable',
            );
          }
          final active2 = bettingState.activeBets.length;
          final plToday = bettingState.todayProfitLoss;
          final plStr = plToday >= 0
              ? '+TZS ${plToday.toStringAsFixed(0)}'
              : '-TZS ${plToday.abs().toStringAsFixed(0)}';
          return p.copyWith(
            status: active2 > 0 ? PillarStatus.active : PillarStatus.idle,
            statusDetail: active2 > 0
                ? '$active2 active · $plStr today'
                : 'No active bets',
          );

        case RichFeature.reading:
          if (locked) return p.copyWith(status: PillarStatus.locked);
          final booksRead = readingState.allBooks
              .where((b) => b.readTodayAlready)
              .length;
          final inProgress = readingState.allBooks
              .where((b) => b.currentPage > 0 && b.progressPercent < 1.0)
              .length;
          return p.copyWith(
            status: booksRead > 0 ? PillarStatus.active : PillarStatus.idle,
            statusDetail: booksRead > 0
                ? '$booksRead read today · $inProgress in progress'
                : '$inProgress book(s) in progress',
          );

        case RichFeature.writing:
          if (locked) return p.copyWith(status: PillarStatus.locked);
          final notes = readingState.allNotes.length;
          return p.copyWith(
            status: PillarStatus.idle,
            statusDetail: '$notes notes in vault',
          );

        case RichFeature.life:
          if (locked) return p.copyWith(status: PillarStatus.locked);
          return p.copyWith(status: PillarStatus.idle);

        default:
          if (locked) return p.copyWith(status: PillarStatus.locked);
          return p.copyWith(status: PillarStatus.idle);
      }
    }).toList();
  }

  TrackingFeature? _trackingFeatureFor(RichFeature feature) {
    switch (feature) {
      case RichFeature.meditation:
        return TrackingFeature.meditation;
      case RichFeature.work:
        return TrackingFeature.work;
      case RichFeature.life:
        return TrackingFeature.life;
      case RichFeature.trading:
        return TrackingFeature.trading;
      case RichFeature.betting:
        return TrackingFeature.betting;
      case RichFeature.reading:
        return TrackingFeature.reading;
      case RichFeature.writing:
        return TrackingFeature.writing;
      default:
        return null;
    }
  }

  // ── Reload from Hive (call when screen becomes visible) ──────────────────

  void reload() {
    final routine = _repo.loadRoutineProgress();
    final readiness = _repo.loadReadiness();
    state = state.copyWith(
      routineProgress: routine,
      mentalReadiness: readiness,
    );
    _recalculateScore();
    _updateNextAction();
  }

  // ── Reset for New Day ─────────────────────────────────────────────────────

  Future<void> resetForNewDay() async {
    await _repo.resetForNewDay();
    _load();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (_) => DashboardRepository(),
);

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(ref.read(dashboardRepositoryProvider), ref),
    );

final pillarSummariesProvider = Provider<List<PillarSummary>>((ref) {
  ref.watch(dashboardViewModelProvider);
  ref.watch(lockedFeaturesProvider);
  ref.watch(meditationViewModelProvider);
  ref.watch(workViewModelProvider);
  ref.watch(tradingViewModelProvider);
  ref.watch(bettingViewModelProvider);
  ref.watch(readingViewModelProvider);
  ref.watch(financeViewModelProvider);
  // Refresh of routine progress is handled by DashboardViewModel itself
  // via _ref.listen on the module providers — no cross-provider mutation
  // needed during this provider's build.
  return ref.read(dashboardViewModelProvider.notifier).pillarSummaries;
});
