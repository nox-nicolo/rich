// lib/providers/dashboard_provider.dart
//
// Dashboard-level state: discipline score, routine progress,
// next action, mental readiness. Derived from multiple sources.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/dashboard/model/dashboard_state_model.dart';
import '../feature/dashboard/repository/dashboard_repository.dart';
import 'rule_context_provider.dart';
import 'locked_features_provider.dart';

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  final Ref _ref;

  DashboardNotifier(this._repo, this._ref)
      : super(DashboardState.initial()) {
    _load();
  }

  void _load() {
    final score     = _repo.loadScore();
    final routine   = _repo.loadRoutineProgress();
    final action    = _repo.loadNextAction();
    final readiness = _repo.loadReadiness();

    state = state.copyWith(
      disciplineScore:    score,
      routineProgress:    routine,
      nextRequiredAction: action,
      mentalReadiness:    readiness,
      isLoading:          false,
    );
  }

  // ── Routine ───────────────────────────────────────────────────────────────

  Future<void> completeRoutineItem(String key) async {
    final updated =
        Map<String, bool>.from(state.routineProgress)..[key] = true;
    state = state.copyWith(routineProgress: updated);
    await _repo.saveRoutineProgress(updated);
    _recalculateScore();
    _updateNextAction();
  }

  Future<void> uncompleteRoutineItem(String key) async {
    final updated =
        Map<String, bool>.from(state.routineProgress)..[key] = false;
    state = state.copyWith(routineProgress: updated);
    await _repo.saveRoutineProgress(updated);
    _recalculateScore();
  }

  // ── Score ─────────────────────────────────────────────────────────────────

  void _recalculateScore() {
    final rate        = state.routineCompletionRate;
    final ruleCtx     = _ref.read(ruleContextProvider);
    final lockedCount = _ref.read(lockedFeaturesProvider).length;

    int score = (rate * 60).round();
    if (ruleCtx.meditationCompletedToday) score += 20;
    if (lockedCount == 0) score += 20;
    score = score.clamp(0, 100);

    state = state.copyWith(disciplineScore: score);
    _repo.saveScore(score);
  }

  // ── Next Action ───────────────────────────────────────────────────────────

  void _updateNextAction() {
    final ruleCtx = _ref.read(ruleContextProvider);
    final String action;

    if (!ruleCtx.meditationCompletedToday) {
      action = 'Begin Morning Meditation';
    } else if (state.routineProgress['Workout'] == false) {
      action = 'Complete your Workout';
    } else if (state.routineProgress['Deep Work'] == false) {
      action = 'Start a Deep Work block';
    } else if (state.routineProgress['Reading'] == false) {
      action = 'Read for 20 minutes';
    } else if (state.routineProgress['Journaling'] == false) {
      action = 'Write your journal entry';
    } else {
      action = 'All routines complete. Stay disciplined.';
    }

    state = state.copyWith(nextRequiredAction: action);
    _repo.saveNextAction(action);
  }

  // ── Mental Readiness ──────────────────────────────────────────────────────

  Future<void> setMentalReadiness(MentalReadiness readiness) async {
    state = state.copyWith(mentalReadiness: readiness);
    await _repo.saveReadiness(readiness);
    _ref.read(ruleContextProvider.notifier).setEmotionalState(
      readiness == MentalReadiness.low,
    );
  }

  // ── News Impact ───────────────────────────────────────────────────────────

  void setHighImpactNews(bool hasNews) {
    state = state.copyWith(hasHighImpactNews: hasNews);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetForNewDay() async {
    await _repo.resetForNewDay();
    _load();
  }
}

final _dashboardRepositoryProvider = Provider<DashboardRepository>(
  (_) => DashboardRepository(),
);

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(
    ref.read(_dashboardRepositoryProvider),
    ref,
  ),
);
