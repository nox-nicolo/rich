// lib/feature/betting/model/rollover_strategy_model.dart

enum RolloverStrategyType {
  strategyA, // 100% reinvest @ 1.50 odds — phase/hold tracking
  strategyB, // 75% reinvest / 25% profit @ 8 odds — phase targets
}

// ── Strategy A — 100% Reinvest at 1.50 ───────────────────────────────────────

class StrategyARow {
  final int step;
  final double stake;
  final double odds;       // always 1.50
  final double winReturn;  // stake * odds
  final double profit;     // winReturn - stake
  final double holdAmount; // amount kept aside this phase
  final double nextStake;
  final bool completed;

  const StrategyARow({
    required this.step,
    required this.stake,
    required this.odds,
    required this.winReturn,
    required this.profit,
    required this.holdAmount,
    required this.nextStake,
    this.completed = false,
  });

  StrategyARow copyWith({bool? completed}) => StrategyARow(
    step:       step,
    stake:      stake,
    odds:       odds,
    winReturn:  winReturn,
    profit:     profit,
    holdAmount: holdAmount,
    nextStake:  nextStake,
    completed:  completed ?? this.completed,
  );

  Map<String, dynamic> toMap() => {
    'step':       step,
    'stake':      stake,
    'odds':       odds,
    'winReturn':  winReturn,
    'profit':     profit,
    'holdAmount': holdAmount,
    'nextStake':  nextStake,
    'completed':  completed,
  };

  factory StrategyARow.fromMap(Map<String, dynamic> m) => StrategyARow(
    step:       m['step'] as int,
    stake:      (m['stake'] as num).toDouble(),
    odds:       (m['odds'] as num).toDouble(),
    winReturn:  (m['winReturn'] as num).toDouble(),
    profit:     (m['profit'] as num).toDouble(),
    holdAmount: (m['holdAmount'] as num).toDouble(),
    nextStake:  (m['nextStake'] as num).toDouble(),
    completed:  m['completed'] as bool? ?? false,
  );
}

class RolloverStrategyA {
  final String id;
  final double startingStake;
  final int totalSteps;
  final List<StrategyARow> rows;
  final DateTime createdAt;

  const RolloverStrategyA({
    required this.id,
    required this.startingStake,
    required this.totalSteps,
    required this.rows,
    required this.createdAt,
  });

  int get currentStep => rows.where((r) => r.completed).length;
  bool get isComplete => currentStep >= totalSteps;
  double get totalHeld => rows
      .where((r) => r.completed)
      .fold(0.0, (s, r) => s + r.holdAmount);

  /// Build the plan: at each step reinvest 100% of winnings into next stake.
  /// holdAmount = 0 for strategy A (full reinvest), but can be set per phase.
  static RolloverStrategyA build({
    required String id,
    required double startingStake,
    required int steps,
    double holdPercent = 0,   // 0 = full reinvest
    DateTime? createdAt,
  }) {
    final rows = <StrategyARow>[];
    double stake = startingStake;

    for (int i = 1; i <= steps; i++) {
      const odds    = 1.50;
      final ret     = stake * odds;
      final profit  = ret - stake;
      final hold    = profit * holdPercent;
      final next    = stake + profit - hold; // reinvest remainder

      rows.add(StrategyARow(
        step:       i,
        stake:      double.parse(stake.toStringAsFixed(2)),
        odds:       odds,
        winReturn:  double.parse(ret.toStringAsFixed(2)),
        profit:     double.parse(profit.toStringAsFixed(2)),
        holdAmount: double.parse(hold.toStringAsFixed(2)),
        nextStake:  double.parse(next.toStringAsFixed(2)),
      ));
      stake = next;
    }

    return RolloverStrategyA(
      id:           id,
      startingStake: startingStake,
      totalSteps:   steps,
      rows:         rows,
      createdAt:    createdAt ?? DateTime.now(),
    );
  }

  RolloverStrategyA markStep(int step, {required bool completed}) {
    final updated = rows.map((r) =>
      r.step == step ? r.copyWith(completed: completed) : r,
    ).toList();
    return RolloverStrategyA(
      id:           id,
      startingStake: startingStake,
      totalSteps:   totalSteps,
      rows:         updated,
      createdAt:    createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':           id,
    'startingStake': startingStake,
    'totalSteps':   totalSteps,
    'rows':         rows.map((r) => r.toMap()).toList(),
    'createdAt':    createdAt.toIso8601String(),
  };

  factory RolloverStrategyA.fromMap(Map<String, dynamic> m) => RolloverStrategyA(
    id:           m['id'] as String,
    startingStake: (m['startingStake'] as num).toDouble(),
    totalSteps:   m['totalSteps'] as int,
    rows:         (m['rows'] as List)
        .map((r) => StrategyARow.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList(),
    createdAt:    DateTime.parse(m['createdAt'] as String),
  );
}

// ── Strategy B — 75% Reinvest / 25% Profit @ 8 odds ─────────────────────────

class StrategyBRow {
  final int step;
  final double stake;
  final double odds;         // always 8.0
  final double targeting;    // winReturn
  final double takeProfit;   // 25% of profit
  final double nextStake;    // 75% reinvested
  final String phase;        // e.g. "Phase 1: 0 → 500K"
  final bool completed;
  final bool isWin;

  const StrategyBRow({
    required this.step,
    required this.stake,
    required this.odds,
    required this.targeting,
    required this.takeProfit,
    required this.nextStake,
    required this.phase,
    this.completed = false,
    this.isWin = false,
  });

  StrategyBRow copyWith({bool? completed, bool? isWin}) => StrategyBRow(
    step:       step,
    stake:      stake,
    odds:       odds,
    targeting:  targeting,
    takeProfit: takeProfit,
    nextStake:  nextStake,
    phase:      phase,
    completed:  completed ?? this.completed,
    isWin:      isWin ?? this.isWin,
  );

  Map<String, dynamic> toMap() => {
    'step':       step,
    'stake':      stake,
    'odds':       odds,
    'targeting':  targeting,
    'takeProfit': takeProfit,
    'nextStake':  nextStake,
    'phase':      phase,
    'completed':  completed,
    'isWin':      isWin,
  };

  factory StrategyBRow.fromMap(Map<String, dynamic> m) => StrategyBRow(
    step:       m['step'] as int,
    stake:      (m['stake'] as num).toDouble(),
    odds:       (m['odds'] as num).toDouble(),
    targeting:  (m['targeting'] as num).toDouble(),
    takeProfit: (m['takeProfit'] as num).toDouble(),
    nextStake:  (m['nextStake'] as num).toDouble(),
    phase:      m['phase'] as String,
    completed:  m['completed'] as bool? ?? false,
    isWin:      m['isWin'] as bool? ?? false,
  );
}

class RolloverStrategyB {
  final String id;
  final double startingStake; // 10,000 TZS default
  final List<StrategyBRow> rows;
  final DateTime createdAt;

  // Phase thresholds in TZS
  static const List<double> phaseTargets = [
    500000,    // Phase 1
    3000000,   // Phase 2
    18000000,  // Phase 3
    100000000, // Phase 4+
  ];

  static const List<String> phaseLabels = [
    'Phase 1: 0 → 500K',
    'Phase 2: 500K → 3M',
    'Phase 3: 3M → 18M',
    'Phase 4: 18M → 100M+',
  ];

  const RolloverStrategyB({
    required this.id,
    required this.startingStake,
    required this.rows,
    required this.createdAt,
  });

  int get currentStep => rows.where((r) => r.completed).length;
  double get totalProfit => rows
      .where((r) => r.completed && r.isWin)
      .fold(0.0, (s, r) => s + r.takeProfit);

  static String _phaseFor(double cumulative) {
    for (int i = 0; i < phaseTargets.length; i++) {
      if (cumulative < phaseTargets[i]) return phaseLabels[i];
    }
    return phaseLabels.last;
  }

  static RolloverStrategyB build({
    required String id,
    required double startingStake,
    required int steps,
    DateTime? createdAt,
  }) {
    final rows = <StrategyBRow>[];
    double stake      = startingStake;
    double cumulative = 0;

    for (int i = 1; i <= steps; i++) {
      const odds      = 8.0;
      final ret       = stake * odds;
      final profit    = ret - stake;
      final take      = profit * 0.25;
      final reinvest  = profit * 0.75 + stake; // 75% profit + original stake

      rows.add(StrategyBRow(
        step:       i,
        stake:      double.parse(stake.toStringAsFixed(0)),
        odds:       odds,
        targeting:  double.parse(ret.toStringAsFixed(0)),
        takeProfit: double.parse(take.toStringAsFixed(0)),
        nextStake:  double.parse(reinvest.toStringAsFixed(0)),
        phase:      _phaseFor(cumulative),
      ));

      cumulative += ret;
      stake = reinvest;
    }

    return RolloverStrategyB(
      id:           id,
      startingStake: startingStake,
      rows:         rows,
      createdAt:    createdAt ?? DateTime.now(),
    );
  }

  RolloverStrategyB markStep(int step, {required bool isWin}) {
    final updated = rows.map((r) =>
      r.step == step ? r.copyWith(completed: true, isWin: isWin) : r,
    ).toList();
    return RolloverStrategyB(
      id:           id,
      startingStake: startingStake,
      rows:         updated,
      createdAt:    createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':           id,
    'startingStake': startingStake,
    'rows':         rows.map((r) => r.toMap()).toList(),
    'createdAt':    createdAt.toIso8601String(),
  };

  factory RolloverStrategyB.fromMap(Map<String, dynamic> m) => RolloverStrategyB(
    id:           m['id'] as String,
    startingStake: (m['startingStake'] as num).toDouble(),
    rows:         (m['rows'] as List)
        .map((r) => StrategyBRow.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList(),
    createdAt:    DateTime.parse(m['createdAt'] as String),
  );
}