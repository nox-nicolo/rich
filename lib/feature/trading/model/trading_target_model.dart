// lib/feature/trading/model/trading_target_model.dart

enum TargetTimeframe { hours, days, weeks, months }

extension TargetTimeframeX on TargetTimeframe {
  String get label {
    switch (this) {
      case TargetTimeframe.hours:  return 'Hours';
      case TargetTimeframe.days:   return 'Days';
      case TargetTimeframe.weeks:  return 'Weeks';
      case TargetTimeframe.months: return 'Months';
    }
  }
}

enum TargetStatus { active, completed, abandoned }

extension TargetStatusX on TargetStatus {
  String get label {
    switch (this) {
      case TargetStatus.active:    return 'Active';
      case TargetStatus.completed: return 'Completed';
      case TargetStatus.abandoned: return 'Abandoned';
    }
  }
}

class TradingTarget {
  final String id;
  final String title;

  // Capital
  final double startingCapital;
  final double targetCapital;
  final double currentCapital;

  // Per-session / per-day targets
  final double dailyTarget;
  final double sessionTarget;

  // Risk rules
  final double lotSize;
  final int maxTradesPerSession;
  final int maxDailyLosses;
  final double stopLossThreshold; // USD — stop if daily loss exceeds this
  final bool stopAfterDailyTarget;
  final bool stopAfterLossThreshold;

  // Timeframe
  final TargetTimeframe timeframe;
  final int timeframeValue; // e.g. 5 for "5 days"
  final DateTime startDate;
  final DateTime endDate;

  final TargetStatus status;
  final String? notes;
  final DateTime createdAt;

  const TradingTarget({
    required this.id,
    required this.title,
    required this.startingCapital,
    required this.targetCapital,
    required this.currentCapital,
    required this.dailyTarget,
    required this.sessionTarget,
    required this.lotSize,
    required this.maxTradesPerSession,
    required this.maxDailyLosses,
    required this.stopLossThreshold,
    required this.stopAfterDailyTarget,
    required this.stopAfterLossThreshold,
    required this.timeframe,
    required this.timeframeValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  double get progressPercent {
    if (targetCapital <= startingCapital) return 0;
    final gained = currentCapital - startingCapital;
    final needed = targetCapital - startingCapital;
    return (gained / needed).clamp(0.0, 1.0);
  }

  double get remainingToTarget => (targetCapital - currentCapital).clamp(0, double.infinity);

  bool get isExpired => DateTime.now().isAfter(endDate);

  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  TradingTarget copyWith({
    double? currentCapital,
    TargetStatus? status,
  }) => TradingTarget(
    id:                    id,
    title:                 title,
    startingCapital:       startingCapital,
    targetCapital:         targetCapital,
    currentCapital:        currentCapital ?? this.currentCapital,
    dailyTarget:           dailyTarget,
    sessionTarget:         sessionTarget,
    lotSize:               lotSize,
    maxTradesPerSession:   maxTradesPerSession,
    maxDailyLosses:        maxDailyLosses,
    stopLossThreshold:     stopLossThreshold,
    stopAfterDailyTarget:  stopAfterDailyTarget,
    stopAfterLossThreshold: stopAfterLossThreshold,
    timeframe:             timeframe,
    timeframeValue:        timeframeValue,
    startDate:             startDate,
    endDate:               endDate,
    status:                status ?? this.status,
    notes:                 notes,
    createdAt:             createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id':                    id,
    'title':                 title,
    'startingCapital':       startingCapital,
    'targetCapital':         targetCapital,
    'currentCapital':        currentCapital,
    'dailyTarget':           dailyTarget,
    'sessionTarget':         sessionTarget,
    'lotSize':               lotSize,
    'maxTradesPerSession':   maxTradesPerSession,
    'maxDailyLosses':        maxDailyLosses,
    'stopLossThreshold':     stopLossThreshold,
    'stopAfterDailyTarget':  stopAfterDailyTarget,
    'stopAfterLossThreshold': stopAfterLossThreshold,
    'timeframe':             timeframe.index,
    'timeframeValue':        timeframeValue,
    'startDate':             startDate.toIso8601String(),
    'endDate':               endDate.toIso8601String(),
    'status':                status.index,
    'notes':                 notes,
    'createdAt':             createdAt.toIso8601String(),
  };

  factory TradingTarget.fromMap(Map<String, dynamic> m) => TradingTarget(
    id:                    m['id'] as String,
    title:                 m['title'] as String,
    startingCapital:       (m['startingCapital'] as num).toDouble(),
    targetCapital:         (m['targetCapital'] as num).toDouble(),
    currentCapital:        (m['currentCapital'] as num).toDouble(),
    dailyTarget:           (m['dailyTarget'] as num).toDouble(),
    sessionTarget:         (m['sessionTarget'] as num).toDouble(),
    lotSize:               (m['lotSize'] as num).toDouble(),
    maxTradesPerSession:   m['maxTradesPerSession'] as int,
    maxDailyLosses:        m['maxDailyLosses'] as int,
    stopLossThreshold:     (m['stopLossThreshold'] as num).toDouble(),
    stopAfterDailyTarget:  m['stopAfterDailyTarget'] as bool,
    stopAfterLossThreshold: m['stopAfterLossThreshold'] as bool,
    timeframe:             TargetTimeframe.values[m['timeframe'] as int],
    timeframeValue:        m['timeframeValue'] as int,
    startDate:             DateTime.parse(m['startDate'] as String),
    endDate:               DateTime.parse(m['endDate'] as String),
    status:                TargetStatus.values[m['status'] as int],
    notes:                 m['notes'] as String?,
    createdAt:             DateTime.parse(m['createdAt'] as String),
  );
}
