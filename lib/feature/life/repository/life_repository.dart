// lib/features/life/repository/life_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/habit_model.dart';
import '../model/workout_model.dart';
import '../model/health_log_model.dart';
import '../model/recovery_model.dart';

class LifeRepository {
  static const String _habitsKey = 'life_habits';
  static const String _workoutsKey = 'life_workouts';
  static const String _healthLogsKey = 'life_health_logs';
  static const String _recoveryKey = 'life_recovery_sessions';

  // ── Habits ────────────────────────────────────────────────────────────────

  Future<void> saveHabit(HabitModel habit) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_habitsKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == habit.id);
    if (index >= 0) {
      existing[index] = habit.toMap();
    } else {
      existing.add(habit.toMap());
    }
    await box.put(_habitsKey, existing);
  }

  Future<void> deleteHabit(String id) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_habitsKey, defaultValue: []) as List);
    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_habitsKey, existing);
  }

  List<HabitModel> loadHabits() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_habitsKey, defaultValue: []) as List);
    return raw
        .map((e) =>
            HabitModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((h) => h.active)
        .toList();
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  Future<void> saveWorkout(WorkoutModel workout) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_workoutsKey, defaultValue: []) as List);
    existing.add(workout.toMap());
    if (existing.length > 200) existing.removeAt(0);
    await box.put(_workoutsKey, existing);
  }

  List<WorkoutModel> loadTodayWorkouts() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_workoutsKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) =>
            WorkoutModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((w) =>
            w.completedAt.year == now.year &&
            w.completedAt.month == now.month &&
            w.completedAt.day == now.day)
        .toList();
  }

  List<WorkoutModel> loadAllWorkouts() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_workoutsKey, defaultValue: []) as List);
    return raw
        .map((e) =>
            WorkoutModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Health Logs ───────────────────────────────────────────────────────────

  Future<void> saveHealthLog(HealthLogModel log) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_healthLogsKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == log.id);
    if (index >= 0) {
      existing[index] = log.toMap();
    } else {
      existing.add(log.toMap());
    }
    if (existing.length > 90) existing.removeAt(0);
    await box.put(_healthLogsKey, existing);
  }

  List<HealthLogModel> loadAllHealthLogs() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_healthLogsKey, defaultValue: []) as List);
    return raw
        .map((e) =>
            HealthLogModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  HealthLogModel? loadTodayHealthLog() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_healthLogsKey, defaultValue: []) as List);
    final now = DateTime.now();
    final todayLogs = raw
        .map((e) => HealthLogModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((l) =>
            l.loggedAt.year == now.year &&
            l.loggedAt.month == now.month &&
            l.loggedAt.day == now.day)
        .toList();
    return todayLogs.isNotEmpty ? todayLogs.last : null;
  }

  // ── Recovery ──────────────────────────────────────────────────────────────

  Future<void> saveRecoverySession(RecoverySession session) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_recoveryKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == session.id);
    if (index >= 0) {
      existing[index] = session.toMap();
    } else {
      existing.add(session.toMap());
    }
    await box.put(_recoveryKey, existing);
  }

  RecoverySession? loadActiveRecoverySession() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_recoveryKey, defaultValue: []) as List);
    final active = raw
        .map((e) => RecoverySession.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((s) => s.active)
        .toList();
    return active.isNotEmpty ? active.last : null;
  }

  List<RecoverySession> loadAllRecoverySessions() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_recoveryKey, defaultValue: []) as List);
    return raw
        .map((e) => RecoverySession.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<RecoverySession> loadTodayRecoverySessions() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_recoveryKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) => RecoverySession.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .toList();
  }
}
