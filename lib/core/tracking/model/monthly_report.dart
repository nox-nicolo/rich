// lib/core/tracking/model/monthly_report.dart
//
// Monthly aggregation of daily records across every feature for a given
// local month (YYYY-MM). Created by the retention sweep once dailies for
// that month exceed the 25-day window and are being folded away.
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

  int get year => int.parse(yearMonth.split('-')[0]);
  int get month => int.parse(yearMonth.split('-')[1]);
  int get featureCount => byFeature.length;

  int get tasksCompleted =>
      _intFor(TrackingFeature.work, 'tasksCompleted') +
      _intFor(TrackingFeature.work, 'tasksDone');
  int get tasksPending => _intFor(TrackingFeature.work, 'tasksPending');
  int get tasksBlocked => _intFor(TrackingFeature.work, 'tasksBlocked');
  int get focusSeconds => _intFor(TrackingFeature.work, 'totalSeconds');
  int get meetingMinutes =>
      _intFor(TrackingFeature.work, 'meetingActualMinutes');

  int get pagesRead =>
      _intFor(TrackingFeature.reading, 'pages') +
      _intFor(TrackingFeature.reading, 'pagesRead');
  int get wordsWritten =>
      _intFor(TrackingFeature.writing, 'words') +
      _intFor(TrackingFeature.writing, 'wordsWritten');

  double get financeIncome => _doubleFor(TrackingFeature.finance, 'income');
  double get financeExpense => _doubleFor(TrackingFeature.finance, 'expense');
  double get financeKept => _doubleFor(TrackingFeature.finance, 'kept');
  double get financePnl => _doubleFor(TrackingFeature.finance, 'pnl');

  List<String> mentorSignals() {
    final signals = <String>[];
    if (tasksCompleted > 0) signals.add('$tasksCompleted work tasks finished');
    if (tasksPending > 0) signals.add('$tasksPending tasks carried over');
    if (tasksBlocked > 0) signals.add('$tasksBlocked tasks blocked');
    if (focusSeconds > 0) {
      signals.add('${_formatHours(focusSeconds)} focused');
    }
    if (meetingMinutes > 0) signals.add('$meetingMinutes meeting minutes');
    if (pagesRead > 0) signals.add('$pagesRead pages read');
    if (wordsWritten > 0) signals.add('$wordsWritten words written');
    if (financeIncome > 0 || financeExpense > 0 || financeKept > 0) {
      signals.add(
        'money: income ${financeIncome.toStringAsFixed(0)}, '
        'expense ${financeExpense.toStringAsFixed(0)}, '
        'kept ${financeKept.toStringAsFixed(0)}',
      );
    }
    if (signals.isEmpty) {
      signals.add('No strong signal yet; this month needs more daily records.');
    }
    return signals;
  }

  String mentorBrief() {
    final features = byFeature.keys.join(', ');
    return '''
MONTH: $yearMonth
FEATURES RECORDED: ${features.isEmpty ? 'none' : features}
TASKS COMPLETED: $tasksCompleted
TASKS PENDING: $tasksPending
TASKS BLOCKED: $tasksBlocked
FOCUS TIME: ${_formatHours(focusSeconds)}
MEETING TIME: $meetingMinutes minutes
PAGES READ: $pagesRead
WORDS WRITTEN: $wordsWritten
FINANCE INCOME: ${financeIncome.toStringAsFixed(0)}
FINANCE EXPENSE: ${financeExpense.toStringAsFixed(0)}
FINANCE KEPT: ${financeKept.toStringAsFixed(0)}
FINANCE PNL: ${financePnl.toStringAsFixed(0)}
MENTOR SIGNALS:
${mentorSignals().map((s) => '- $s').join('\n')}
''';
  }

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

  int _intFor(TrackingFeature feature, String key) =>
      _numFor(feature, key).toInt();

  double _doubleFor(TrackingFeature feature, String key) =>
      _numFor(feature, key).toDouble();

  num _numFor(TrackingFeature feature, String key) {
    final value = byFeature[feature.key]?[key];
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }

  String _formatHours(int seconds) {
    if (seconds <= 0) return '0h';
    final hours = seconds / 3600;
    if (hours >= 10) return '${hours.round()}h';
    return '${hours.toStringAsFixed(1)}h';
  }
}
