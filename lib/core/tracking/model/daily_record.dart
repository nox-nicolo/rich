// lib/core/tracking/model/daily_record.dart
//
// One DailyRecord = one feature's activity on one local calendar day.
// Storage key format: "{featureKey}|{YYYY-MM-DD}" so a record is uniquely
// addressable.

import '../tracking_feature.dart';

class DailyRecord {
  final TrackingFeature feature;
  final DateTime date; // normalized to local midnight
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  const DailyRecord({
    required this.feature,
    required this.date,
    required this.data,
    required this.updatedAt,
  });

  static String composeKey(TrackingFeature feature, DateTime localDay) {
    final d = DateTime(localDay.year, localDay.month, localDay.day);
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm   = d.month.toString().padLeft(2, '0');
    final dd   = d.day.toString().padLeft(2, '0');
    return '${feature.key}|$yyyy-$mm-$dd';
  }

  String get key => composeKey(feature, date);

  String get yearMonth {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm   = date.month.toString().padLeft(2, '0');
    return '$yyyy-$mm';
  }

  Map<String, dynamic> toMap() => {
    'feature':   feature.key,
    'date':      DateTime(date.year, date.month, date.day).toIso8601String(),
    'data':      data,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DailyRecord? fromMap(Map<String, dynamic> m) {
    final featureKey = m['feature'] as String?;
    final feature    = featureKey == null
        ? null
        : TrackingFeatureX.fromKey(featureKey);
    final dateStr = m['date'] as String?;
    if (feature == null || dateStr == null) return null;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    final rawData = m['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final updatedAt =
        DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? date;

    return DailyRecord(
      feature:   feature,
      date:      DateTime(date.year, date.month, date.day),
      data:      data,
      updatedAt: updatedAt,
    );
  }
}
