// lib/core/services/daily_reset_service.dart

import '../constants/hive_boxes.dart';
import 'hive_service.dart';
import '../../feature/dashboard/repository/dashboard_repository.dart';
import '../../feature/rules_engine/repository/rules_repository.dart';
import '../../feature/meditation/repository/meditation_repository.dart';

/// Resets per-day state once per calendar day.
///
/// Yesterday's routines, meditation gate, locks, mind readiness and discipline
/// score do not carry forward — every day starts from zero. Historical entries
/// (sessions, workouts, journal, recovery, etc.) are not touched; they live in
/// their own time-stamped lists.
class DailyResetService {
  DailyResetService._();

  static const _lastResetKey = 'last_reset_date';

  /// Call once on app startup, after Hive is initialised. Cheap when the date
  /// hasn't changed (single key read + string compare).
  static Future<void> runIfNewDay() async {
    final today = _todayKey();
    final stored = HiveService.get<String>(
        HiveBoxes.dashboardSummary, _lastResetKey);

    if (stored == today) return;

    await DashboardRepository().resetForNewDay();
    await RulesRepository().resetForNewDay();
    await MeditationRepository().resetCompletion();

    await HiveService.put(
        HiveBoxes.dashboardSummary, _lastResetKey, today);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
