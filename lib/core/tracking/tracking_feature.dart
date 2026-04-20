// lib/core/tracking/tracking_feature.dart
//
// Enumerates the features that produce activity data worth tracking.
// Config-only features (settings, security, overlay, etc.) are excluded
// on purpose — they don't need day-over-day record keeping.

enum TrackingFeature {
  meditation,
  trading,
  betting,
  finance,
  reading,
  writing,
  work,
  life,
}

extension TrackingFeatureX on TrackingFeature {
  String get key {
    switch (this) {
      case TrackingFeature.meditation: return 'meditation';
      case TrackingFeature.trading:    return 'trading';
      case TrackingFeature.betting:    return 'betting';
      case TrackingFeature.finance:    return 'finance';
      case TrackingFeature.reading:    return 'reading';
      case TrackingFeature.writing:    return 'writing';
      case TrackingFeature.work:       return 'work';
      case TrackingFeature.life:       return 'life';
    }
  }

  String get label {
    switch (this) {
      case TrackingFeature.meditation: return 'Meditation';
      case TrackingFeature.trading:    return 'Trading';
      case TrackingFeature.betting:    return 'Betting';
      case TrackingFeature.finance:    return 'Finance';
      case TrackingFeature.reading:    return 'Reading';
      case TrackingFeature.writing:    return 'Writing';
      case TrackingFeature.work:       return 'Work';
      case TrackingFeature.life:       return 'Life';
    }
  }

  static TrackingFeature? fromKey(String key) {
    for (final f in TrackingFeature.values) {
      if (f.key == key) return f;
    }
    return null;
  }
}
