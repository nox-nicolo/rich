// lib/features/life/model/health_log_model.dart

class HealthLogModel {
  final String id;
  final DateTime loggedAt;
  final int? sleepHours;
  final int? waterGlasses;
  final int? steps;
  final EnergyLevel energyLevel;
  final String? meals;
  final String? notes;

  const HealthLogModel({
    required this.id,
    required this.loggedAt,
    this.sleepHours,
    this.waterGlasses,
    this.steps,
    required this.energyLevel,
    this.meals,
    this.notes,
  });

  HealthLogModel copyWith({
    int? sleepHours,
    int? waterGlasses,
    int? steps,
    EnergyLevel? energyLevel,
    String? meals,
    String? notes,
  }) {
    return HealthLogModel(
      id: id,
      loggedAt: loggedAt,
      sleepHours: sleepHours ?? this.sleepHours,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      steps: steps ?? this.steps,
      energyLevel: energyLevel ?? this.energyLevel,
      meals: meals ?? this.meals,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loggedAt': loggedAt.toIso8601String(),
      'sleepHours': sleepHours,
      'waterGlasses': waterGlasses,
      'steps': steps,
      'energyLevel': energyLevel.index,
      'meals': meals,
      'notes': notes,
    };
  }

  factory HealthLogModel.fromMap(Map<String, dynamic> m) {
    return HealthLogModel(
      id: m['id'] as String,
      loggedAt: DateTime.parse(m['loggedAt'] as String),
      sleepHours: m['sleepHours'] as int?,
      waterGlasses: m['waterGlasses'] as int?,
      steps: m['steps'] as int?,
      energyLevel: EnergyLevel.values[m['energyLevel'] as int],
      meals: m['meals'] as String?,
      notes: m['notes'] as String?,
    );
  }
}

enum EnergyLevel { low, moderate, high, peak }

extension EnergyLevelX on EnergyLevel {
  String get label {
    switch (this) {
      case EnergyLevel.low:
        return 'Low';
      case EnergyLevel.moderate:
        return 'Moderate';
      case EnergyLevel.high:
        return 'High';
      case EnergyLevel.peak:
        return 'Peak';
    }
  }

  String get shortLabel {
    switch (this) {
      case EnergyLevel.low:
        return 'LOW';
      case EnergyLevel.moderate:
        return 'MOD';
      case EnergyLevel.high:
        return 'HIGH';
      case EnergyLevel.peak:
        return 'PEAK';
    }
  }
}
