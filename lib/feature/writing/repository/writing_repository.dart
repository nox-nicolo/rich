// lib/feature/writing/repository/writing_repository.dart

import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/hive_service.dart';
import '../model/writing_session_model.dart';

class WritingRepository {
  Box<dynamic> get _box => HiveService.box(HiveBoxes.writingEntries);

  static const _sessionsKey = 'writing_sessions';
  static const _streakKey   = 'writing_streak';
  static const _lastDayKey  = 'writing_last_day';

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// Insert or update a session. The list is keyed by [WritingSession.id]
  /// so calling this with an existing id replaces the old record in place —
  /// this is what makes "continue writing" on a past session possible.
  Future<void> saveSession(WritingSession session) async {
    final List<dynamic> all =
        List.from(_box.get(_sessionsKey, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == session.id);
    if (idx >= 0) {
      all[idx] = session.toMap();
    } else {
      all.add(session.toMap());
      // Only enforce the cap on brand-new sessions, never during an update —
      // otherwise editing an older entry could silently evict the oldest.
      if (all.length > 500) all.removeAt(0);
    }
    await _box.put(_sessionsKey, all);
  }

  Future<void> deleteSession(String id) async {
    final List<dynamic> all =
        List.from(_box.get(_sessionsKey, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await _box.put(_sessionsKey, all);
  }

  List<WritingSession> loadAllSessions() {
    final List<dynamic> all =
        List.from(_box.get(_sessionsKey, defaultValue: []) as List);
    return all
        .map((e) => WritingSession.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<WritingSession> loadTodaySessions() {
    return loadAllSessions().where((s) => s.isToday).toList();
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  int loadStreak() => _box.get(_streakKey, defaultValue: 0) as int;

  Future<void> updateStreak() async {
    final lastDay  = _box.get(_lastDayKey) as String?;
    final today    = _todayKey();
    final yesterday = _yesterdayKey();

    if (lastDay == today) return; // already updated today

    int streak = loadStreak();
    if (lastDay == yesterday) {
      streak += 1; // consecutive day
    } else if (lastDay == null) {
      streak = 1; // first time
    } else {
      streak = 1; // streak broken, restart
    }

    await _box.put(_streakKey, streak);
    await _box.put(_lastDayKey, today);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _yesterdayKey() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month}-${y.day}';
  }

  // ── Weekly word count ─────────────────────────────────────────────────────

  int weeklyWordCount() {
    final sessions = loadAllSessions();
    final weekAgo  = DateTime.now().subtract(const Duration(days: 7));
    return sessions
        .where((s) => s.createdAt.isAfter(weekAgo))
        .fold(0, (sum, s) => sum + s.wordCount);
  }

  int monthlyWordCount() {
    final sessions = loadAllSessions();
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return sessions
        .where((s) => s.createdAt.isAfter(monthAgo))
        .fold(0, (sum, s) => sum + s.wordCount);
  }
}
