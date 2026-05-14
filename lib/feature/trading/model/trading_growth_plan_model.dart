// lib/feature/trading/model/trading_growth_plan_model.dart

enum GrowthDayStatus { pending, completed, missed }

extension GrowthDayStatusX on GrowthDayStatus {
  String get label {
    switch (this) {
      case GrowthDayStatus.pending:
        return 'PENDING';
      case GrowthDayStatus.completed:
        return 'DONE';
      case GrowthDayStatus.missed:
        return 'MISSED';
    }
  }
}

// ── Lot size rules based on account balance ───────────────────────────────────

String lotSizeForBalance(double balance) {
  if (balance < 100) return '0.01';
  if (balance < 500) return '0.02';
  if (balance < 1000) return '0.05';
  if (balance < 5000) return '0.10';
  if (balance < 10000) return '0.20';
  if (balance < 50000) return '0.50';
  return '1.00+';
}

String scaledLotSize({
  required double startingBalance,
  required double currentBalance,
  required double startingLotSize,
}) {
  if (startingBalance <= 0 || startingLotSize <= 0) {
    return lotSizeForBalance(currentBalance);
  }

  final scaled = startingLotSize * (currentBalance / startingBalance);
  final rounded = (scaled * 100).round() / 100;
  return rounded.clamp(0.01, double.infinity).toStringAsFixed(2);
}

// ── A single day in the growth plan ──────────────────────────────────────────

class GrowthPlanDay {
  final int day;
  final double startBalance;
  final double dailyTarget; // startBalance * growthPercent
  final double expectedEnd; // startBalance + dailyTarget
  final double stopLoss; // max loss allowed this step
  final String lotSize;
  final GrowthDayStatus status;
  final double? actualEnd;

  const GrowthPlanDay({
    required this.day,
    required this.startBalance,
    required this.dailyTarget,
    required this.expectedEnd,
    required this.stopLoss,
    required this.lotSize,
    this.status = GrowthDayStatus.pending,
    this.actualEnd,
  });

  /// How much of the starting balance the SL represents.
  double get stopLossPercent =>
      startBalance > 0 ? (stopLoss / startBalance) * 100 : 0;

  GrowthPlanDay copyWith({GrowthDayStatus? status, double? actualEnd}) =>
      GrowthPlanDay(
        day: day,
        startBalance: startBalance,
        dailyTarget: dailyTarget,
        expectedEnd: expectedEnd,
        stopLoss: stopLoss,
        lotSize: lotSize,
        status: status ?? this.status,
        actualEnd: actualEnd ?? this.actualEnd,
      );

  Map<String, dynamic> toMap() => {
    'day': day,
    'startBalance': startBalance,
    'dailyTarget': dailyTarget,
    'expectedEnd': expectedEnd,
    'stopLoss': stopLoss,
    'lotSize': lotSize,
    'status': status.index,
    'actualEnd': actualEnd,
  };

  factory GrowthPlanDay.fromMap(Map<String, dynamic> m) => GrowthPlanDay(
    day: m['day'] as int,
    startBalance: (m['startBalance'] as num).toDouble(),
    dailyTarget: (m['dailyTarget'] as num).toDouble(),
    expectedEnd: (m['expectedEnd'] as num).toDouble(),
    stopLoss: (m['stopLoss'] as num?)?.toDouble() ?? 0,
    lotSize: m['lotSize'] as String,
    status: GrowthDayStatus.values[m['status'] as int],
    actualEnd: (m['actualEnd'] as num?)?.toDouble(),
  );
}

// ── The growth plan ───────────────────────────────────────────────────────────

class TradingGrowthPlan {
  final String id;
  final String name;
  final double startingCapital;
  final double targetCapital;
  final double dailyGrowthPercent; // e.g. 25 = 25%
  final double stopLossPercent; // e.g. 2 = 2% max loss per step
  final int totalDays;
  final List<GrowthPlanDay> days;
  final bool isActive;
  final DateTime createdAt;

  const TradingGrowthPlan({
    required this.id,
    required this.name,
    required this.startingCapital,
    required this.targetCapital,
    required this.dailyGrowthPercent,
    this.stopLossPercent = 2.0,
    required this.totalDays,
    required this.days,
    required this.isActive,
    required this.createdAt,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  int get completedDays =>
      days.where((d) => d.status == GrowthDayStatus.completed).length;
  int get missedDays =>
      days.where((d) => d.status == GrowthDayStatus.missed).length;
  double get progressPercent => totalDays > 0 ? completedDays / totalDays : 0;

  /// A single missed day breaks the compounding math of the remaining days,
  /// since the start-balance assumed by the table no longer matches reality.
  bool get isBroken => missedDays > 0;
  bool get isComplete => completedDays >= totalDays;

  /// Best estimate of the current capital after the last marked day. Used to
  /// pre-fill the starting capital of a recalibrated plan.
  double get currentCapital {
    final marked = days
        .where(
          (d) =>
              d.status == GrowthDayStatus.completed ||
              d.status == GrowthDayStatus.missed,
        )
        .toList();
    if (marked.isEmpty) return startingCapital;
    final last = marked.last;
    if (last.actualEnd != null) return last.actualEnd!;
    if (last.status == GrowthDayStatus.missed) {
      return last.startBalance - last.stopLoss;
    }
    return last.expectedEnd;
  }

  double get projectedFinalBalance {
    if (days.isEmpty) return startingCapital;
    final last = days.last;
    return last.actualEnd ?? last.expectedEnd;
  }

  GrowthPlanDay? get currentDay =>
      days.where((d) => d.status == GrowthDayStatus.pending).isNotEmpty
      ? days.firstWhere((d) => d.status == GrowthDayStatus.pending)
      : null;

  // ── Build plan from rules ──────────────────────────────────────────────────

  static TradingGrowthPlan build({
    required String id,
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double dailyGrowthPercent,
    required int totalDays,
    double stopLossPercent = 2.0,
    double? startingLotSize,
    DateTime? createdAt,
  }) {
    final days = <GrowthPlanDay>[];
    double balance = startingCapital;
    final rate = dailyGrowthPercent / 100;
    final slPct = stopLossPercent / 100;

    for (int i = 1; i <= totalDays; i++) {
      final target = balance * rate;
      final end = balance + target;
      final sl = balance * slPct;
      days.add(
        GrowthPlanDay(
          day: i,
          startBalance: double.parse(balance.toStringAsFixed(2)),
          dailyTarget: double.parse(target.toStringAsFixed(2)),
          expectedEnd: double.parse(end.toStringAsFixed(2)),
          stopLoss: double.parse(sl.toStringAsFixed(2)),
          lotSize: startingLotSize == null
              ? lotSizeForBalance(balance)
              : scaledLotSize(
                  startingBalance: startingCapital,
                  currentBalance: balance,
                  startingLotSize: startingLotSize,
                ),
        ),
      );
      balance = end;
    }

    return TradingGrowthPlan(
      id: id,
      name: name,
      startingCapital: startingCapital,
      targetCapital: targetCapital,
      dailyGrowthPercent: dailyGrowthPercent,
      stopLossPercent: stopLossPercent,
      totalDays: totalDays,
      days: days,
      isActive: true,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // ── Mark a day ────────────────────────────────────────────────────────────

  TradingGrowthPlan markDay(
    int day,
    GrowthDayStatus status, {
    double? actualEnd,
  }) {
    final updated = days.map((d) {
      if (d.day != day) return d;
      return d.copyWith(status: status, actualEnd: actualEnd);
    }).toList();
    return copyWith(days: updated);
  }

  TradingGrowthPlan copyWith({List<GrowthPlanDay>? days, bool? isActive}) =>
      TradingGrowthPlan(
        id: id,
        name: name,
        startingCapital: startingCapital,
        targetCapital: targetCapital,
        dailyGrowthPercent: dailyGrowthPercent,
        stopLossPercent: stopLossPercent,
        totalDays: totalDays,
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startingCapital': startingCapital,
    'targetCapital': targetCapital,
    'dailyGrowthPercent': dailyGrowthPercent,
    'stopLossPercent': stopLossPercent,
    'totalDays': totalDays,
    'days': days.map((d) => d.toMap()).toList(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TradingGrowthPlan.fromMap(Map<String, dynamic> m) =>
      TradingGrowthPlan(
        id: m['id'] as String,
        name: m['name'] as String,
        startingCapital: (m['startingCapital'] as num).toDouble(),
        targetCapital: (m['targetCapital'] as num).toDouble(),
        dailyGrowthPercent: (m['dailyGrowthPercent'] as num).toDouble(),
        stopLossPercent: (m['stopLossPercent'] as num?)?.toDouble() ?? 2.0,
        totalDays: m['totalDays'] as int,
        days: (m['days'] as List)
            .map(
              (d) => GrowthPlanDay.fromMap(Map<String, dynamic>.from(d as Map)),
            )
            .toList(),
        isActive: m['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
