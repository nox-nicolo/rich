// lib/features/meditation/model/meditation_type.dart

enum MeditationType {
  prayer,
  breathing,
  stillness,
  visualization,
  reflection,
  reset,
}

extension MeditationTypeX on MeditationType {
  String get label {
    switch (this) {
      case MeditationType.prayer:
        return 'Prayer';
      case MeditationType.breathing:
        return 'Breathing';
      case MeditationType.stillness:
        return 'Stillness';
      case MeditationType.visualization:
        return 'Visualization';
      case MeditationType.reflection:
        return 'Reflection';
      case MeditationType.reset:
        return 'Reset';
    }
  }

  String get sublabel {
    switch (this) {
      case MeditationType.prayer:
        return 'Connect and ground';
      case MeditationType.breathing:
        return 'Calm the nervous system';
      case MeditationType.stillness:
        return 'Clear mental noise';
      case MeditationType.visualization:
        return 'See the disciplined self';
      case MeditationType.reflection:
        return 'Review and process';
      case MeditationType.reset:
        return 'Anti-impulse break';
    }
  }

  int get defaultDurationSeconds {
    switch (this) {
      case MeditationType.prayer:
        return 300;
      case MeditationType.breathing:
        return 240;
      case MeditationType.stillness:
        return 600;
      case MeditationType.visualization:
        return 300;
      case MeditationType.reflection:
        return 420;
      case MeditationType.reset:
        return 180;
    }
  }

  bool get isGateQualifier {
    return this == MeditationType.prayer ||
        this == MeditationType.breathing ||
        this == MeditationType.stillness;
  }

  String get durationLabel {
    final m = defaultDurationSeconds ~/ 60;
    return '${m}m';
  }
}
