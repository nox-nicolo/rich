// lib/features/life/model/recovery_model.dart

enum RecoveryMode { active, low, digital, full }

extension RecoveryModeX on RecoveryMode {
  String get label {
    switch (this) {
      case RecoveryMode.active:
        return 'Active Recovery';
      case RecoveryMode.low:
        return 'Low Stimulation';
      case RecoveryMode.digital:
        return 'Digital Cleanup';
      case RecoveryMode.full:
        return 'Full Rest';
    }
  }

  String get description {
    switch (this) {
      case RecoveryMode.active:
        return 'Light movement, stretch, walk. No high intensity.';
      case RecoveryMode.low:
        return 'Reduce screen time, noise, and mental load.';
      case RecoveryMode.digital:
        return 'Clear inbox, files, and digital environment.';
      case RecoveryMode.full:
        return 'Rest completely. No work, no training, no stress.';
    }
  }
}

class RecoverySession {
  final String id;
  final RecoveryMode mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final bool active;
  final String? note;

  const RecoverySession({
    required this.id,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    required this.active,
    this.note,
  });

  RecoverySession copyWith({
    DateTime? endedAt,
    bool? active,
    String? note,
  }) {
    return RecoverySession(
      id: id,
      mode: mode,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes,
      active: active ?? this.active,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode.index,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'active': active,
      'note': note,
    };
  }

  factory RecoverySession.fromMap(Map<String, dynamic> m) {
    return RecoverySession(
      id: m['id'] as String,
      mode: RecoveryMode.values[m['mode'] as int],
      startedAt: DateTime.parse(m['startedAt'] as String),
      endedAt: m['endedAt'] != null
          ? DateTime.parse(m['endedAt'] as String)
          : null,
      durationMinutes: m['durationMinutes'] as int,
      active: m['active'] as bool,
      note: m['note'] as String?,
    );
  }
}
