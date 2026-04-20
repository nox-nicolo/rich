// lib/features/rules_engine/model/user_mode.dart

enum UserMode {
  idle,
  meditating,
  working,
  trading,
  betting,
  reading,
  writing,
  resting,
}

extension UserModeX on UserMode {
  String get label {
    switch (this) {
      case UserMode.idle:       return 'Idle';
      case UserMode.meditating: return 'Meditating';
      case UserMode.working:    return 'Working';
      case UserMode.trading:    return 'Trading';
      case UserMode.betting:    return 'Betting';
      case UserMode.reading:    return 'Reading';
      case UserMode.writing:    return 'Writing';
      case UserMode.resting:    return 'Resting';
    }
  }

  bool get isHighFocus =>
      this == UserMode.trading ||
      this == UserMode.working;

  bool get isHighRisk =>
      this == UserMode.trading ||
      this == UserMode.betting;
}
