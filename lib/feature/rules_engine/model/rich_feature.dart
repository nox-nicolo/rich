// lib/features/rules_engine/model/rich_feature.dart

enum RichFeature {
  dashboard,
  meditation,
  work,
  life,
  trading,
  betting,
  reading,
  writing,
  overlay,
  notifications,
}

extension RichFeatureX on RichFeature {
  String get label {
    switch (this) {
      case RichFeature.dashboard:     return 'Dashboard';
      case RichFeature.meditation:    return 'Meditation';
      case RichFeature.work:          return 'Work';
      case RichFeature.life:          return 'Life';
      case RichFeature.trading:       return 'Trading';
      case RichFeature.betting:       return 'Betting';
      case RichFeature.reading:       return 'Reading';
      case RichFeature.writing:       return 'Writing';
      case RichFeature.overlay:       return 'Overlay HUD';
      case RichFeature.notifications: return 'Notifications';
    }
  }

  bool get isLockable =>
      this == RichFeature.trading ||
      this == RichFeature.betting ||
      this == RichFeature.notifications;
}
