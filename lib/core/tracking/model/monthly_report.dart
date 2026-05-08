// lib/core/tracking/model/monthly_report.dart
//
// Monthly aggregation of daily records across every feature for a given
// local month (YYYY-MM). Created by the retention sweep once dailies for
// that month exceed the 35-day window and are being folded away.
//
// `byFeature[featureKey]` holds the summed data map for that feature's
// daily records in the month. Numeric fields are summed; non-numeric
// fields keep the most recent value seen.

import '../tracking_feature.dart';

class MonthlyReport {
  final String yearMonth; // "YYYY-MM"
  final Map<String, Map<String, dynamic>> byFeature;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MonthlyReport({
    required this.yearMonth,
    required this.byFeature,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic>? featureTotals(TrackingFeature f) => byFeature[f.key];

  int get year  => int.parse(yearMonth.split('-')[0]);
  int get month => int.parse(yearMonth.split('-')[1]);

  MonthlyReport mergeFeature(
    TrackingFeature feature,
    Map<String, dynamic> additional,
  ) {
    final current = Map<String, dynamic>.from(byFeature[feature.key] ?? {});
    for (final entry in additional.entries) {
      final existing = current[entry.key];
      final incoming = entry.value;

      if (existing is num && incoming is num) {
        current[entry.key] = existing + incoming;
      } else if (existing is List && incoming is List) {
        // Item lists (taskItems, meetingItems, etc.) accumulate across the
        // month so the monthly report keeps every item from every folded day.
        current[entry.key] = [...existing, ...incoming];
      } else if (existing == null && incoming is num) {
        current[entry.key] = incoming;
      } else if (existing == null && incoming is List) {
        current[entry.key] = List.from(incoming);
      } else {
        // non-numeric — last value wins
        current[entry.key] = incoming;
      }
    }

    final next = Map<String, Map<String, dynamic>>.from(byFeature);
    next[feature.key] = current;

    return MonthlyReport(
      yearMonth: yearMonth,
      byFeature: next,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'yearMonth': yearMonth,
    'byFeature': byFeature,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static MonthlyReport? fromMap(Map<String, dynamic> m) {
    final ym = m['yearMonth'] as String?;
    if (ym == null || !RegExp(r'^\d{4}-\d{2}$').hasMatch(ym)) return null;

    final rawByFeature = m['byFeature'];
    final byFeature = <String, Map<String, dynamic>>{};
    if (rawByFeature is Map) {
      for (final entry in rawByFeature.entries) {
        final k = entry.key?.toString();
        if (k == null) continue;
        final v = entry.value;
        if (v is Map) byFeature[k] = Map<String, dynamic>.from(v);
      }
    }

    final createdAt =
        DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now();
    final updatedAt =
        DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? createdAt;

    return MonthlyReport(
      yearMonth: ym,
      byFeature: byFeature,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static MonthlyReport empty(String yearMonth) {
    final now = DateTime.now();
    return MonthlyReport(
      yearMonth: yearMonth,
      byFeature: const {},
      createdAt: now,
      updatedAt: now,
    );
  }
}
