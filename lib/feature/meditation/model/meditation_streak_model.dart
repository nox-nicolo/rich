// lib/features/meditation/model/meditation_streak_model.dart

class MeditationStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int totalSessions;

  const MeditationStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.totalSessions,
  });

  factory MeditationStreak.empty() {
    return const MeditationStreak(
      currentStreak: 0,
      longestStreak: 0,
      totalSessions: 0,
    );
  }

  bool get completedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  bool get streakAtRisk {
    if (lastCompletedDate == null) return false;
    final diff = DateTime.now().difference(lastCompletedDate!);
    return diff.inHours >= 20 && !completedToday;
  }

  MeditationStreak increment() {
    final now = DateTime.now();
    final newCurrent = currentStreak + 1;
    return MeditationStreak(
      currentStreak: newCurrent,
      longestStreak: newCurrent > longestStreak
          ? newCurrent
          : longestStreak,
      lastCompletedDate: now,
      totalSessions: totalSessions + 1,
    );
  }

  MeditationStreak reset() {
    return MeditationStreak(
      currentStreak: 0,
      longestStreak: longestStreak,
      lastCompletedDate: lastCompletedDate,
      totalSessions: totalSessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'totalSessions': totalSessions,
    };
  }

  factory MeditationStreak.fromMap(Map<String, dynamic> m) {
    return MeditationStreak(
      currentStreak: m['currentStreak'] as int,
      longestStreak: m['longestStreak'] as int,
      totalSessions: m['totalSessions'] as int,
      lastCompletedDate: m['lastCompletedDate'] != null
          ? DateTime.parse(m['lastCompletedDate'] as String)
          : null,
    );
  }
}
