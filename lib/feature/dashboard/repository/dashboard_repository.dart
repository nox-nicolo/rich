// lib/features/dashboard/repository/dashboard_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/dashboard_state_model.dart';

class DashboardRepository {
  static const _scoreKey    = 'discipline_score';
  static const _routineKey  = 'routine_progress';
  static const _actionKey   = 'next_required_action';
  static const _readinessKey = 'mental_readiness';

  // ── Discipline Score ──────────────────────────────────────────────────────

  Future<void> saveScore(int score) async {
    await HiveService.put(
        HiveBoxes.dashboardSummary, _scoreKey, score);
  }

  int loadScore() {
    return HiveService.get<int>(
            HiveBoxes.dashboardSummary, _scoreKey) ??
        0;
  }

  // ── Routine Progress ──────────────────────────────────────────────────────

  Future<void> saveRoutineProgress(
      Map<String, bool> progress) async {
    await HiveService.put(
        HiveBoxes.dashboardSummary, _routineKey, progress);
  }

  Map<String, bool> loadRoutineProgress() {
    final raw = HiveService.get<Map>(
        HiveBoxes.dashboardSummary, _routineKey);
    if (raw == null) return _defaultRoutines();
    return raw.map(
        (k, v) => MapEntry(k.toString(), v as bool));
  }

  Map<String, bool> _defaultRoutines() => {
    'Prayer':      false,
    'Breathing':   false,
    'Workout':     false,
    'Deep Work':   false,
    'Reading':     false,
    'Journaling':  false,
  };

  // ── Next Required Action ──────────────────────────────────────────────────

  Future<void> saveNextAction(String action) async {
    await HiveService.put(
        HiveBoxes.dashboardSummary, _actionKey, action);
  }

  String loadNextAction() {
    return HiveService.get<String>(
            HiveBoxes.dashboardSummary, _actionKey) ??
        'Begin Morning Meditation';
  }

  // ── Mental Readiness ──────────────────────────────────────────────────────

  Future<void> saveReadiness(MentalReadiness readiness) async {
    await HiveService.put(
        HiveBoxes.dashboardSummary, _readinessKey,
        readiness.index);
  }

  MentalReadiness loadReadiness() {
    final index = HiveService.get<int>(
        HiveBoxes.dashboardSummary, _readinessKey);
    if (index == null) return MentalReadiness.unchecked;
    return MentalReadiness.values[index];
  }

  // ── Reset daily (call at midnight or on new day) ──────────────────────────

  Future<void> resetForNewDay() async {
    final defaultProgress = _defaultRoutines();
    await saveRoutineProgress(defaultProgress);
    await saveScore(0);
    await saveNextAction('Begin Morning Meditation');
    await saveReadiness(MentalReadiness.unchecked);
  }
}
