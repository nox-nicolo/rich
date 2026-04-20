// lib/features/meditation/repository/meditation_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/meditation_session_model.dart';
import '../model/meditation_streak_model.dart';

class MeditationRepository {
  static const String _streakKey = 'meditation_streak';
  static const String _sessionsKey = 'meditation_sessions';
  static const String _completedTodayKey = 'meditation_completed_today';
  static const String _lastDateKey = 'meditation_last_date';

  MeditationStreak loadStreak() {
    final raw = HiveService.get<Map>(HiveBoxes.routines, _streakKey);
    if (raw == null) return MeditationStreak.empty();
    return MeditationStreak.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> saveStreak(MeditationStreak streak) async {
    await HiveService.put(HiveBoxes.routines, _streakKey, streak.toMap());
  }

  bool isCompletedToday() {
    final dateStr = HiveService.get<String>(HiveBoxes.routines, _lastDateKey);
    if (dateStr == null) return false;
    final last = DateTime.tryParse(dateStr);
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  Future<void> markCompletedToday() async {
    await HiveService.put(HiveBoxes.routines, _completedTodayKey, true);
    await HiveService.put(
      HiveBoxes.routines,
      _lastDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> resetCompletion() async {
    await HiveService.put(HiveBoxes.routines, _completedTodayKey, false);
    await HiveService.delete(HiveBoxes.routines, _lastDateKey);
  }

  Future<void> saveSession(MeditationSession session) async {
    final box = HiveService.box(HiveBoxes.routines);
    final List<dynamic> existing =
        List.from(box.get(_sessionsKey, defaultValue: []) as List);
    existing.add(session.toMap());
    if (existing.length > 90) existing.removeAt(0);
    await box.put(_sessionsKey, existing);
  }

  List<MeditationSession> loadTodaySessions() {
    final box = HiveService.box(HiveBoxes.routines);
    final List<dynamic> raw =
        List.from(box.get(_sessionsKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) => MeditationSession.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .toList();
  }

  List<MeditationSession> loadAllSessions() {
    final box = HiveService.box(HiveBoxes.routines);
    final List<dynamic> raw =
        List.from(box.get(_sessionsKey, defaultValue: []) as List);
    return raw
        .map((e) => MeditationSession.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
