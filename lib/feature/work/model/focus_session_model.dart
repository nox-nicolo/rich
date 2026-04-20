// lib/features/work/model/focus_session_model.dart

enum FocusSessionType { deepWork, shallowWork, review, planning }

extension FocusSessionTypeX on FocusSessionType {
  String get label {
    switch (this) {
      case FocusSessionType.deepWork:
        return 'Deep Work';
      case FocusSessionType.shallowWork:
        return 'Shallow Work';
      case FocusSessionType.review:
        return 'Review';
      case FocusSessionType.planning:
        return 'Planning';
    }
  }

  String get sublabel {
    switch (this) {
      case FocusSessionType.deepWork:
        return 'Zero distractions. Full output.';
      case FocusSessionType.shallowWork:
        return 'Admin, emails, small tasks.';
      case FocusSessionType.review:
        return 'Review work and take notes.';
      case FocusSessionType.planning:
        return 'Plan next steps and priorities.';
    }
  }

  int get defaultDurationMinutes {
    switch (this) {
      case FocusSessionType.deepWork:
        return 90;
      case FocusSessionType.shallowWork:
        return 45;
      case FocusSessionType.review:
        return 30;
      case FocusSessionType.planning:
        return 20;
    }
  }

  bool get isDeepWork => this == FocusSessionType.deepWork;
}

class FocusSessionModel {
  final String id;
  final FocusSessionType type;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final bool completed;
  final String? taskFocusedOn;
  final String? outcome;
  final int? distractionCount;

  const FocusSessionModel({
    required this.id,
    required this.type,
    required this.startedAt,
    this.completedAt,
    required this.durationMinutes,
    required this.completed,
    this.taskFocusedOn,
    this.outcome,
    this.distractionCount,
  });

  FocusSessionModel copyWith({
    DateTime? completedAt,
    bool? completed,
    String? outcome,
    int? distractionCount,
  }) {
    return FocusSessionModel(
      id: id,
      type: type,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes,
      completed: completed ?? this.completed,
      taskFocusedOn: taskFocusedOn,
      outcome: outcome ?? this.outcome,
      distractionCount: distractionCount ?? this.distractionCount,
    );
  }

  int get durationSeconds => durationMinutes * 60;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
      'taskFocusedOn': taskFocusedOn,
      'outcome': outcome,
      'distractionCount': distractionCount,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> m) {
    return FocusSessionModel(
      id: m['id'] as String,
      type: FocusSessionType.values[m['type'] as int],
      startedAt: DateTime.parse(m['startedAt'] as String),
      completedAt: m['completedAt'] != null
          ? DateTime.parse(m['completedAt'] as String)
          : null,
      durationMinutes: m['durationMinutes'] as int,
      completed: m['completed'] as bool,
      taskFocusedOn: m['taskFocusedOn'] as String?,
      outcome: m['outcome'] as String?,
      distractionCount: m['distractionCount'] as int?,
    );
  }
}
