// lib/features/meditation/model/meditation_session_model.dart

import 'meditation_type.dart';

enum MoodLevel {
  veryLow,
  low,
  neutral,
  good,
  excellent,
}

extension MoodLevelX on MoodLevel {
  String get label {
    switch (this) {
      case MoodLevel.veryLow:
        return 'Very Low';
      case MoodLevel.low:
        return 'Low';
      case MoodLevel.neutral:
        return 'Neutral';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.excellent:
        return 'Excellent';
    }
  }

  String get shortLabel {
    switch (this) {
      case MoodLevel.veryLow:
        return 'V.Low';
      case MoodLevel.low:
        return 'Low';
      case MoodLevel.neutral:
        return 'OK';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.excellent:
        return 'Sharp';
    }
  }

  bool get isUnstable {
    return this == MoodLevel.veryLow || this == MoodLevel.low;
  }
}

class MeditationSession {
  final String id;
  final MeditationType type;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final bool completed;
  final String? note;
  final MoodLevel moodBefore;
  final MoodLevel? moodAfter;

  const MeditationSession({
    required this.id,
    required this.type,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.completed,
    this.note,
    required this.moodBefore,
    this.moodAfter,
  });

  MeditationSession copyWith({
    DateTime? completedAt,
    bool? completed,
    String? note,
    MoodLevel? moodAfter,
  }) {
    return MeditationSession(
      id: id,
      type: type,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds,
      completed: completed ?? this.completed,
      note: note ?? this.note,
      moodBefore: moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'completed': completed,
      'note': note,
      'moodBefore': moodBefore.index,
      'moodAfter': moodAfter?.index,
    };
  }

  factory MeditationSession.fromMap(Map<String, dynamic> m) {
    return MeditationSession(
      id: m['id'] as String,
      type: MeditationType.values[m['type'] as int],
      startedAt: DateTime.parse(m['startedAt'] as String),
      completedAt: m['completedAt'] != null
          ? DateTime.parse(m['completedAt'] as String)
          : null,
      durationSeconds: m['durationSeconds'] as int,
      completed: m['completed'] as bool,
      note: m['note'] as String?,
      moodBefore: MoodLevel.values[m['moodBefore'] as int],
      moodAfter: m['moodAfter'] != null
          ? MoodLevel.values[m['moodAfter'] as int]
          : null,
    );
  }

  bool get isGateQualifier {
    return completed && type.isGateQualifier;
  }
}
