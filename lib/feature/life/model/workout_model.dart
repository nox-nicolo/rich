// lib/feature/life/model/workout_model.dart

enum WorkoutType {
  strength,
  cardio,
  hiit,
  yoga,
  walk,
  sport,
  other,
}

extension WorkoutTypeX on WorkoutType {
  String get label {
    switch (this) {
      case WorkoutType.strength: return 'Strength';
      case WorkoutType.cardio:   return 'Cardio';
      case WorkoutType.hiit:     return 'HIIT';
      case WorkoutType.yoga:     return 'Yoga';
      case WorkoutType.walk:     return 'Walk';
      case WorkoutType.sport:    return 'Sport';
      case WorkoutType.other:    return 'Other';
    }
  }
}

enum WorkoutIntensity { low, moderate, high }

extension WorkoutIntensityX on WorkoutIntensity {
  String get label {
    switch (this) {
      case WorkoutIntensity.low:      return 'Low';
      case WorkoutIntensity.moderate: return 'Moderate';
      case WorkoutIntensity.high:     return 'High';
    }
  }
}

class WorkoutModel {
  final String id;
  final WorkoutType type;
  final WorkoutIntensity intensity;
  final int durationMinutes;
  final DateTime completedAt;
  final String? notes;
  final int? steps;

  const WorkoutModel({
    required this.id,
    required this.type,
    required this.intensity,
    required this.durationMinutes,
    required this.completedAt,
    this.notes,
    this.steps,
  });

  Map<String, dynamic> toMap() => {
    'id':              id,
    'type':            type.index,
    'intensity':       intensity.index,
    'durationMinutes': durationMinutes,
    'completedAt':     completedAt.toIso8601String(),
    'notes':           notes,
    'steps':           steps,
  };

  factory WorkoutModel.fromMap(Map<String, dynamic> m) => WorkoutModel(
    id:              m['id'] as String,
    type:            WorkoutType.values[m['type'] as int],
    intensity:       WorkoutIntensity.values[m['intensity'] as int],
    durationMinutes: m['durationMinutes'] as int,
    completedAt:     DateTime.parse(m['completedAt'] as String),
    notes:           m['notes'] as String?,
    steps:           m['steps'] as int?,
  );
}
