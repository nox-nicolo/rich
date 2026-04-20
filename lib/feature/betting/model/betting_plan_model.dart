// lib/feature/betting/model/betting_plan_model.dart

// ── Enums ────────────────────────────────────────────────────────────────────

enum BettingPlanStepStatus { pending, won, lost }

extension BettingPlanStepStatusX on BettingPlanStepStatus {
  String get label {
    switch (this) {
      case BettingPlanStepStatus.pending: return 'PENDING';
      case BettingPlanStepStatus.won:     return 'WON';
      case BettingPlanStepStatus.lost:    return 'LOST';
    }
  }
}

enum BettingPlanStatus { active, won, lost, abandoned }

extension BettingPlanStatusX on BettingPlanStatus {
  String get label {
    switch (this) {
      case BettingPlanStatus.active:    return 'ACTIVE';
      case BettingPlanStatus.won:       return 'WON';
      case BettingPlanStatus.lost:      return 'LOST';
      case BettingPlanStatus.abandoned: return 'ABANDONED';
    }
  }
}

// ── Plan Phase ───────────────────────────────────────────────────────────────

class PlanPhase {
  final int    number;
  final String name;
  final double target;

  const PlanPhase({
    required this.number,
    required this.name,
    required this.target,
  });

  Map<String, dynamic> toMap() => {
    'number': number,
    'name':   name,
    'target': target,
  };

  factory PlanPhase.fromMap(Map<String, dynamic> m) => PlanPhase(
    number: m['number'] as int,
    name:   m['name'] as String,
    target: (m['target'] as num).toDouble(),
  );
}

// ── A single step in the betting plan ────────────────────────────────────────

class BettingPlanStep {
  final int step;
  final double stake;        // amount bet
  final double odds;         // user-defined
  final double kept;         // amount kept aside (not bet), e.g. 40K out of 100K
  final int    phase;        // which phase this step belongs to (1-indexed)
  final BettingPlanStepStatus status;
  final DateTime? settledAt;

  const BettingPlanStep({
    required this.step,
    required this.stake,
    required this.odds,
    this.kept      = 0,
    this.phase     = 1,
    this.status    = BettingPlanStepStatus.pending,
    this.settledAt,
  });

  double get potentialReturn => stake * odds;
  double get potentialProfit => potentialReturn - stake;

  /// Total available before this step = stake + kept
  double get availableBefore => stake + kept;

  BettingPlanStep copyWith({
    double? stake,
    double? odds,
    double? kept,
    int?    phase,
    BettingPlanStepStatus? status,
    DateTime? settledAt,
  }) =>
      BettingPlanStep(
        step:       step,
        stake:      stake      ?? this.stake,
        odds:       odds       ?? this.odds,
        kept:       kept       ?? this.kept,
        phase:      phase      ?? this.phase,
        status:     status     ?? this.status,
        settledAt:  settledAt  ?? this.settledAt,
      );

  Map<String, dynamic> toMap() => {
    'step':       step,
    'stake':      stake,
    'odds':       odds,
    'kept':       kept,
    'phase':      phase,
    'status':     status.index,
    'settledAt':  settledAt?.toIso8601String(),
  };

  factory BettingPlanStep.fromMap(Map<String, dynamic> m) => BettingPlanStep(
    step:      m['step'] as int,
    stake:     (m['stake'] as num).toDouble(),
    odds:      (m['odds'] as num).toDouble(),
    kept:      (m['kept'] as num?)?.toDouble() ?? 0,
    phase:     (m['phase'] as int?) ?? 1,
    status:    BettingPlanStepStatus.values[m['status'] as int],
    settledAt: m['settledAt'] != null
        ? DateTime.parse(m['settledAt'] as String)
        : null,
  );
}

// ── The plan itself ───────────────────────────────────────────────────────────

class BettingPlan {
  final String id;
  final String name;
  final double startingCapital;
  final double targetCapital;
  final double currentBalance;
  final List<BettingPlanStep> steps;
  final List<PlanPhase> phases;
  final BettingPlanStatus status;
  final DateTime createdAt;

  const BettingPlan({
    required this.id,
    required this.name,
    required this.startingCapital,
    required this.targetCapital,
    required this.currentBalance,
    required this.steps,
    this.phases  = const [],
    this.status  = BettingPlanStatus.active,
    required this.createdAt,
  });

  // ── Backward compat ───────────────────────────────────────────────────────

  bool get isActive => status == BettingPlanStatus.active;

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Effective balance = current (live) balance + total kept aside.
  /// Kept amounts are already "secured wins" that count toward the target.
  double get effectiveBalance => currentBalance + totalKept;

  double get progressPercent =>
      targetCapital > startingCapital
          ? ((effectiveBalance - startingCapital) /
                  (targetCapital - startingCapital))
              .clamp(0.0, 1.0)
          : 0.0;

  double get remainingToTarget =>
      (targetCapital - effectiveBalance).clamp(0, double.infinity);

  int get completedSteps =>
      steps.where((s) => s.status != BettingPlanStepStatus.pending).length;

  int get wonSteps   => steps.where((s) => s.status == BettingPlanStepStatus.won).length;
  int get lostSteps  => steps.where((s) => s.status == BettingPlanStepStatus.lost).length;

  BettingPlanStep? get nextPendingStep =>
      steps.where((s) => s.status == BettingPlanStepStatus.pending).isNotEmpty
          ? steps.firstWhere((s) => s.status == BettingPlanStepStatus.pending)
          : null;

  bool get isTargetReached => effectiveBalance >= targetCapital;

  /// Total amount kept aside from steps that have already been WON.
  /// Pending/lost steps contribute 0 — their `kept` is only realized on a win.
  double get totalKept => steps
      .where((s) => s.status == BettingPlanStepStatus.won)
      .fold(0.0, (s, step) => s + step.kept);

  /// Net profit = (current balance + realized kept) - starting capital.
  double get netProfit => (currentBalance + totalKept) - startingCapital;

  /// What phase the plan is currently in — computed from effective balance
  /// vs phase targets. Each phase is cleared when balance crosses its target,
  /// so the "current" phase is the first one whose target has NOT been hit yet.
  int get currentPhase {
    if (phases.isEmpty) return 1;
    final sorted = [...phases]..sort((a, b) => a.target.compareTo(b.target));
    final bal = effectiveBalance;
    for (final p in sorted) {
      if (bal < p.target) return p.number;
    }
    // All phase targets reached — park the user on the final phase.
    return sorted.last.number;
  }

  /// Current phase target (if phases defined).
  PlanPhase? get activePhase =>
      phases.where((p) => p.number == currentPhase).isNotEmpty
          ? phases.firstWhere((p) => p.number == currentPhase)
          : null;

  /// Phase key → total realized value from WON steps in that phase.
  /// For each won step the phase accrues (kept + potentialReturn).
  /// Pending and lost steps contribute nothing — kept is only valid on a win.
  Map<int, double> get phaseTotals {
    final totals = <int, double>{};
    for (final s in steps) {
      if (s.status != BettingPlanStepStatus.won) continue;
      final delta = s.kept + s.potentialReturn;
      totals[s.phase] = (totals[s.phase] ?? 0) + delta;
    }
    return totals;
  }

  /// Overall plan total = sum of all phase totals.
  double get plannedNet =>
      phaseTotals.values.fold(0.0, (a, b) => a + b);

  // ── Copy ───────────────────────────────────────────────────────────────────

  BettingPlan copyWith({
    String?              name,
    double?              currentBalance,
    List<BettingPlanStep>? steps,
    List<PlanPhase>?     phases,
    BettingPlanStatus?   status,
    // Kept for backward compat — setting isActive maps to status
    bool?                isActive,
  }) {
    BettingPlanStatus resolvedStatus = status ?? this.status;
    if (isActive != null) {
      resolvedStatus = isActive ? BettingPlanStatus.active : BettingPlanStatus.abandoned;
    }
    return BettingPlan(
      id:              id,
      name:            name             ?? this.name,
      startingCapital: startingCapital,
      targetCapital:   targetCapital,
      currentBalance:  currentBalance   ?? this.currentBalance,
      steps:           steps            ?? this.steps,
      phases:          phases           ?? this.phases,
      status:          resolvedStatus,
      createdAt:       createdAt,
    );
  }

  // ── Settle a step ──────────────────────────────────────────────────────────

  BettingPlan settleStep(int stepNum, BettingPlanStepStatus result) {
    final updatedSteps = steps.map((s) {
      if (s.step != stepNum) return s;
      return s.copyWith(status: result, settledAt: DateTime.now());
    }).toList();

    final settled = updatedSteps.firstWhere((s) => s.step == stepNum);
    double newBalance = currentBalance;

    if (result == BettingPlanStepStatus.won) {
      // Won: balance = balance - stake + return - kept
      // The kept amount is "withdrawn" from the returns
      newBalance = currentBalance - settled.stake + settled.potentialReturn - settled.kept;
    } else if (result == BettingPlanStepStatus.lost) {
      // Lost: balance goes to zero (stake is lost), plan fails
      newBalance = currentBalance - settled.stake;
    }

    // Determine new plan status
    BettingPlanStatus newStatus = status;
    if (result == BettingPlanStepStatus.lost) {
      // One step lost = entire plan is lost
      newStatus = BettingPlanStatus.lost;
    } else if (result == BettingPlanStepStatus.won) {
      // Only realized (won) kept counts toward the target.
      final realizedKeptAfter = updatedSteps
          .where((s) => s.status == BettingPlanStepStatus.won)
          .fold<double>(0, (s, st) => s + st.kept);
      if ((newBalance + realizedKeptAfter) >= targetCapital) {
        newStatus = BettingPlanStatus.won;
      }
    }

    return copyWith(
      steps:          updatedSteps,
      currentBalance: newBalance,
      status:         newStatus,
    );
  }


  // ── Quick rollover plan builder ────────────────────────────────────────────

  static BettingPlan buildFromRule({
    required String id,
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double odds,
    required double reinvestPercent, // 0–100
    List<PlanPhase> phases = const [],
    int maxSteps = 30,
  }) {
    final steps = <BettingPlanStep>[];
    double balance = startingCapital;
    int stepNum = 1;
    int currentPhase = 1;

    while (balance < targetCapital && stepNum <= maxSteps) {
      // Determine which phase we're in based on balance
      if (phases.isNotEmpty) {
        for (final p in phases) {
          if (balance < p.target) { currentPhase = p.number; break; }
          currentPhase = p.number + 1;
        }
        if (currentPhase > phases.length) currentPhase = phases.length;
      }

      final stake = balance;
      final reinv = reinvestPercent / 100;
      final profit = stake * odds - stake;
      final keptAmount = profit * (1 - reinv);

      steps.add(BettingPlanStep(
        step:  stepNum,
        stake: double.parse(stake.toStringAsFixed(2)),
        odds:  odds,
        kept:  double.parse(keptAmount.toStringAsFixed(2)),
        phase: currentPhase,
      ));

      balance = stake + profit * reinv;
      stepNum++;
    }

    return BettingPlan(
      id:              id,
      name:            name,
      startingCapital: startingCapital,
      targetCapital:   targetCapital,
      currentBalance:  startingCapital,
      steps:           steps,
      phases:          phases,
      status:          BettingPlanStatus.active,
      createdAt:       DateTime.now(),
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id':              id,
    'name':            name,
    'startingCapital': startingCapital,
    'targetCapital':   targetCapital,
    'currentBalance':  currentBalance,
    'steps':           steps.map((s) => s.toMap()).toList(),
    'phases':          phases.map((p) => p.toMap()).toList(),
    'status':          status.index,
    'createdAt':       createdAt.toIso8601String(),
  };

  factory BettingPlan.fromMap(Map<String, dynamic> m) {
    // Handle old data that used isActive bool instead of status enum
    BettingPlanStatus resolvedStatus;
    if (m.containsKey('status') && m['status'] is int) {
      resolvedStatus = BettingPlanStatus.values[m['status'] as int];
    } else {
      final wasActive = m['isActive'] as bool? ?? true;
      resolvedStatus = wasActive ? BettingPlanStatus.active : BettingPlanStatus.abandoned;
    }

    return BettingPlan(
      id:              m['id'] as String,
      name:            m['name'] as String,
      startingCapital: (m['startingCapital'] as num).toDouble(),
      targetCapital:   (m['targetCapital'] as num).toDouble(),
      currentBalance:  (m['currentBalance'] as num).toDouble(),
      steps:           (m['steps'] as List)
          .map((s) => BettingPlanStep.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      phases:          (m['phases'] as List?)
              ?.map((p) => PlanPhase.fromMap(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          const [],
      status:          resolvedStatus,
      createdAt:       DateTime.parse(m['createdAt'] as String),
    );
  }
}
