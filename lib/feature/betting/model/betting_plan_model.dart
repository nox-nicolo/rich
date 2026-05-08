// lib/feature/betting/model/betting_plan_model.dart

// ── Enums ────────────────────────────────────────────────────────────────────

enum BettingPlanStepStatus { pending, won, lost }

extension BettingPlanStepStatusX on BettingPlanStepStatus {
  String get label {
    switch (this) {
      case BettingPlanStepStatus.pending:
        return 'PENDING';
      case BettingPlanStepStatus.won:
        return 'WON';
      case BettingPlanStepStatus.lost:
        return 'LOST';
    }
  }
}

enum BettingPlanStatus { active, won, lost, abandoned }

extension BettingPlanStatusX on BettingPlanStatus {
  String get label {
    switch (this) {
      case BettingPlanStatus.active:
        return 'ACTIVE';
      case BettingPlanStatus.won:
        return 'WON';
      case BettingPlanStatus.lost:
        return 'LOST';
      case BettingPlanStatus.abandoned:
        return 'ABANDONED';
    }
  }
}

// ── Plan Phase ───────────────────────────────────────────────────────────────

class PlanPhase {
  final int number;
  final String name;
  final double target;

  const PlanPhase({
    required this.number,
    required this.name,
    required this.target,
  });

  Map<String, dynamic> toMap() => {
    'number': number,
    'name': name,
    'target': target,
  };

  factory PlanPhase.fromMap(Map<String, dynamic> m) => PlanPhase(
    number: m['number'] as int,
    name: m['name'] as String,
    target: (m['target'] as num).toDouble(),
  );
}

// ── A single step in the betting plan ────────────────────────────────────────

class BettingPlanStep {
  final int step;
  final double stake; // amount bet this step
  final double odds;
  final double
  kept; // amount pocketed from the gross return (exits rollover chain)
  final int phase; // 1-indexed phase this step belongs to
  final BettingPlanStepStatus status;
  final DateTime? settledAt;

  const BettingPlanStep({
    required this.step,
    required this.stake,
    required this.odds,
    this.kept = 0,
    this.phase = 1,
    this.status = BettingPlanStepStatus.pending,
    this.settledAt,
  });

  /// Gross return if this step wins: stake × odds.
  double get potentialReturn => stake * odds;

  /// Profit component only (gross return minus original stake).
  double get potentialProfit => potentialReturn - stake;

  /// Net amount that rolls into the NEXT bet if this step wins.
  /// = gross return − kept
  /// This is the only amount that stays in the rollover chain.
  double get rollover => potentialReturn - kept;

  /// Total available before this step = stake + kept (for display only).
  double get availableBefore => stake + kept;

  BettingPlanStep copyWith({
    double? stake,
    double? odds,
    double? kept,
    int? phase,
    BettingPlanStepStatus? status,
    DateTime? settledAt,
  }) => BettingPlanStep(
    step: step,
    stake: stake ?? this.stake,
    odds: odds ?? this.odds,
    kept: kept ?? this.kept,
    phase: phase ?? this.phase,
    status: status ?? this.status,
    settledAt: settledAt ?? this.settledAt,
  );

  Map<String, dynamic> toMap() => {
    'step': step,
    'stake': stake,
    'odds': odds,
    'kept': kept,
    'phase': phase,
    'status': status.index,
    'settledAt': settledAt?.toIso8601String(),
  };

  factory BettingPlanStep.fromMap(Map<String, dynamic> m) => BettingPlanStep(
    step: m['step'] as int,
    stake: (m['stake'] as num).toDouble(),
    odds: (m['odds'] as num).toDouble(),
    kept: (m['kept'] as num?)?.toDouble() ?? 0,
    phase: (m['phase'] as int?) ?? 1,
    status: BettingPlanStepStatus.values[m['status'] as int],
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
  final double currentBalance; // live rollover amount (what's in the next bet)
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
    this.phases = const [],
    this.status = BettingPlanStatus.active,
    required this.createdAt,
  });

  // ── Status helpers ────────────────────────────────────────────────────────

  bool get isActive => status == BettingPlanStatus.active;

  // ── Core money getters ────────────────────────────────────────────────────

  /// Sum of kept amounts from every WON step.
  /// Kept from pending or lost steps is not realized — only won steps count.
  double get totalKept => steps
      .where((s) => s.status == BettingPlanStepStatus.won)
      .fold(0.0, (sum, s) => sum + s.kept);

  /// Total money in hand right now:
  ///   = rollover still in play (currentBalance) + all realized kept
  ///
  /// WHY: currentBalance holds the amount that rolled out of the last won step
  /// (i.e. last_won.potentialReturn − last_won.kept). Adding totalKept gives
  /// the complete picture of what you actually have.
  ///
  /// This is the single source of truth referenced by the viewmodel.
  double get finalBalance => currentBalance + totalKept;

  /// Alias kept for legacy callers / progress widgets.
  double get effectiveBalance => finalBalance;

  /// Net result vs starting capital.
  /// Positive = ahead. Negative = behind.
  /// NOTE: while the plan is still active, currentBalance is still at risk —
  /// the netProfit here is what you'd walk away with IF the current step wins.
  double get netProfit => finalBalance - startingCapital;

  // ── Progress ──────────────────────────────────────────────────────────────

  double get progressPercent {
    if (phases.isNotEmpty) {
      final target = effectiveTargetCapital;
      return target > 0 ? (plannedNet / target).clamp(0.0, 1.0) : 0.0;
    }
    return targetCapital > startingCapital
        ? ((finalBalance - startingCapital) / (targetCapital - startingCapital))
              .clamp(0.0, 1.0)
        : 0.0;
  }

  double get remainingToTarget =>
      (effectiveTargetCapital - (phases.isEmpty ? finalBalance : plannedNet))
          .clamp(0, double.infinity);

  // ── Step counters ─────────────────────────────────────────────────────────

  int get completedSteps =>
      steps.where((s) => s.status != BettingPlanStepStatus.pending).length;

  int get wonSteps =>
      steps.where((s) => s.status == BettingPlanStepStatus.won).length;
  int get lostSteps =>
      steps.where((s) => s.status == BettingPlanStepStatus.lost).length;

  BettingPlanStep? get nextPendingStep =>
      steps.where((s) => s.status == BettingPlanStepStatus.pending).isNotEmpty
      ? steps.firstWhere((s) => s.status == BettingPlanStepStatus.pending)
      : null;

  bool get isTargetReached => phases.isEmpty
      ? finalBalance >= targetCapital
      : plannedNet >= effectiveTargetCapital;

  // ── Phase helpers ─────────────────────────────────────────────────────────

  double get phasesTargetTotal =>
      phases.fold(0.0, (sum, phase) => sum + phase.target);

  double get effectiveTargetCapital =>
      phases.isEmpty ? targetCapital : phasesTargetTotal;

  int get currentPhase {
    if (phases.isEmpty) return 1;
    final sorted = [...phases]..sort((a, b) => a.number.compareTo(b.number));
    var cumulativeTarget = 0.0;
    for (final p in sorted) {
      cumulativeTarget += p.target;
      if (plannedNet < cumulativeTarget) return p.number;
    }
    return sorted.last.number;
  }

  PlanPhase? get activePhase =>
      phases.where((p) => p.number == currentPhase).isNotEmpty
      ? phases.firstWhere((p) => p.number == currentPhase)
      : null;

  /// Per-phase final money.
  ///
  /// RULE: only the LAST won step of each phase determines the rollover amount
  /// for that phase. Individual step returns must NOT be summed — they would
  /// double-count every rollover because step[n]'s return becomes step[n+1]'s stake.
  ///
  /// Formula per phase:
  ///   phaseTotal = last_won_step.potentialReturn + sum_of_all_kept_in_phase
  ///
  /// Example (3 steps, odds=2, kept=500 each):
  ///   Step1: stake=1000 → return=2000, kept=500, rollover=1500
  ///   Step2: stake=1500 → return=3000, kept=500, rollover=2500
  ///   Step3: stake=2500 → return=5000, kept=500, rollover=4500
  ///
  ///   ❌ Wrong (sums returns):  2000 + 3000 + 5000 = 10 000
  ///   ✅ Correct (last return + kept): 5000 + (500+500+500) = 6 500
  Map<int, double> get phaseTotals {
    // Group won steps by phase
    final wonByPhase = <int, List<BettingPlanStep>>{};
    for (final s in steps.where((s) => s.status == BettingPlanStepStatus.won)) {
      wonByPhase.putIfAbsent(s.phase, () => []).add(s);
    }

    final totals = <int, double>{};
    for (final entry in wonByPhase.entries) {
      final phaseWon = entry.value; // already ordered by insertion (step order)
      final lastWon = phaseWon.last;
      final phaseKept = phaseWon.fold(0.0, (sum, s) => sum + s.kept);
      totals[entry.key] = lastWon.potentialReturn + phaseKept;
    }
    return totals;
  }

  /// Per-phase final balance for a specific phase index.
  /// Useful for phase-level summary cards.
  double finalBalanceForPhase(int phaseIndex) {
    final phaseWon = steps
        .where(
          (s) => s.phase == phaseIndex && s.status == BettingPlanStepStatus.won,
        )
        .toList();
    if (phaseWon.isEmpty) return 0;
    final lastWon = phaseWon.last;
    final phaseKept = phaseWon.fold(0.0, (sum, s) => sum + s.kept);
    return lastWon.potentialReturn + phaseKept;
  }

  /// Overall "planned net" — sum of per-phase final balances.
  /// If the plan has no phases, this equals finalBalance.
  double get plannedNet => phases.isEmpty
      ? finalBalance
      : phaseTotals.values.fold(0.0, (a, b) => a + b);

  // ── Copy ──────────────────────────────────────────────────────────────────

  BettingPlan copyWith({
    String? name,
    double? targetCapital,
    double? currentBalance,
    List<BettingPlanStep>? steps,
    List<PlanPhase>? phases,
    BettingPlanStatus? status,
    bool? isActive, // backward compat
  }) {
    BettingPlanStatus resolvedStatus = status ?? this.status;
    if (isActive != null) {
      resolvedStatus = isActive
          ? BettingPlanStatus.active
          : BettingPlanStatus.abandoned;
    }
    return BettingPlan(
      id: id,
      name: name ?? this.name,
      startingCapital: startingCapital,
      targetCapital: targetCapital ?? this.targetCapital,
      currentBalance: currentBalance ?? this.currentBalance,
      steps: steps ?? this.steps,
      phases: phases ?? this.phases,
      status: resolvedStatus,
      createdAt: createdAt,
    );
  }

  // ── Settle a step ─────────────────────────────────────────────────────────
  //
  // MONEY FLOW:
  //   Win:  newBalance = currentBalance − stake + potentialReturn − kept
  //                    = currentBalance + rollover − stake
  //       If currentBalance == stake (pure rollover), this simplifies to:
  //                    = rollover  = potentialReturn − kept  ✓
  //
  //   Loss: newBalance = currentBalance − stake
  //       Plan is immediately marked LOST — one loss ends the chain.
  //
  // The `totalKept` getter accumulates kept from all won steps so
  // `finalBalance = currentBalance + totalKept` is always correct.

  BettingPlan settleStep(int stepNum, BettingPlanStepStatus result) {
    final updatedSteps = steps.map((s) {
      if (s.step != stepNum) return s;
      return s.copyWith(status: result, settledAt: DateTime.now());
    }).toList();

    final settled = updatedSteps.firstWhere((s) => s.step == stepNum);
    double newBalance = currentBalance;

    if (result == BettingPlanStepStatus.won) {
      // Net rollover = gross return − kept
      newBalance =
          currentBalance -
          settled.stake +
          settled.potentialReturn -
          settled.kept;
    } else if (result == BettingPlanStepStatus.lost) {
      newBalance = currentBalance - settled.stake;
    }

    BettingPlanStatus newStatus = status;
    if (result == BettingPlanStepStatus.lost) {
      newStatus = BettingPlanStatus.lost;
    } else if (result == BettingPlanStepStatus.won) {
      // finalBalance after this step = newBalance (rollover) + all realized kept
      final updatedForCheck = copyWith(
        steps: updatedSteps,
        currentBalance: newBalance,
      );
      if (updatedForCheck.isTargetReached) {
        newStatus = BettingPlanStatus.won;
      }
    }

    return copyWith(
      steps: updatedSteps,
      currentBalance: newBalance,
      status: newStatus,
    );
  }

  // ── Build plan from rollover rule ─────────────────────────────────────────
  //
  // ROLLOVER RULE (this is the fix vs the old implementation):
  //
  //   reinvestPercent applies to the GROSS RETURN, not just the profit.
  //
  //   Old (wrong):
  //     kept    = profit × (1 − reinv)           ← applied to profit only
  //     balance = stake + profit × reinv          ← original stake + portion of profit
  //
  //   Fixed:
  //     kept    = grossReturn × (1 − reinv)       ← applied to full return
  //     balance = grossReturn × reinv             ← next stake = return − kept
  //             = grossReturn − kept
  //
  //   Example: stake=1000, odds=2, reinvestPercent=50
  //     grossReturn = 2000
  //     kept        = 2000 × 0.50 = 1000
  //     next stake  = 2000 − 1000 = 1000  ✓
  //
  //   Old code gave: kept=500, next stake=1500  ✗

  static BettingPlan buildFromRule({
    required String id,
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double odds,
    required double reinvestPercent, // 0–100; what % of gross return rolls over
    List<PlanPhase> phases = const [],
    int maxSteps = 30,
  }) {
    final steps = <BettingPlanStep>[];
    double balance = startingCapital;
    int stepNum = 1;
    final reinv = reinvestPercent / 100; // fraction

    final effectiveTarget = phases.isEmpty
        ? targetCapital
        : phases.fold(0.0, (sum, phase) => sum + phase.target);

    while (balance < effectiveTarget && stepNum <= maxSteps) {
      final stake = balance;
      final grossReturn = stake * odds;
      // FIX: kept is a fraction of the GROSS RETURN, not just profit
      final keptAmount = grossReturn * (1 - reinv);
      // Next stake = what remains after pocketing the kept amount
      final rollover = grossReturn - keptAmount; // = grossReturn × reinv

      // Determine phase for this step
      int stepPhase = 1;
      if (phases.isNotEmpty) {
        final sorted = [...phases]
          ..sort((a, b) => a.number.compareTo(b.number));
        stepPhase = sorted.last.number; // default to last phase
        var cumulativeTarget = 0.0;
        for (final p in sorted) {
          cumulativeTarget += p.target;
          if (balance < cumulativeTarget) {
            stepPhase = p.number;
            break;
          }
        }
      }

      steps.add(
        BettingPlanStep(
          step: stepNum,
          stake: double.parse(stake.toStringAsFixed(2)),
          odds: odds,
          kept: double.parse(keptAmount.toStringAsFixed(2)),
          phase: stepPhase,
        ),
      );

      balance = rollover; // next stake = gross return − kept
      stepNum++;
    }

    return BettingPlan(
      id: id,
      name: name,
      startingCapital: startingCapital,
      targetCapital: effectiveTarget,
      currentBalance: startingCapital,
      steps: steps,
      phases: phases,
      status: BettingPlanStatus.active,
      createdAt: DateTime.now(),
    );
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startingCapital': startingCapital,
    'targetCapital': targetCapital,
    'currentBalance': currentBalance,
    'steps': steps.map((s) => s.toMap()).toList(),
    'phases': phases.map((p) => p.toMap()).toList(),
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BettingPlan.fromMap(Map<String, dynamic> m) {
    BettingPlanStatus resolvedStatus;
    if (m.containsKey('status') && m['status'] is int) {
      resolvedStatus = BettingPlanStatus.values[m['status'] as int];
    } else {
      final wasActive = m['isActive'] as bool? ?? true;
      resolvedStatus = wasActive
          ? BettingPlanStatus.active
          : BettingPlanStatus.abandoned;
    }

    return BettingPlan(
      id: m['id'] as String,
      name: m['name'] as String,
      startingCapital: (m['startingCapital'] as num).toDouble(),
      targetCapital: (m['targetCapital'] as num).toDouble(),
      currentBalance: (m['currentBalance'] as num).toDouble(),
      steps: (m['steps'] as List)
          .map(
            (s) => BettingPlanStep.fromMap(Map<String, dynamic>.from(s as Map)),
          )
          .toList(),
      phases:
          (m['phases'] as List?)
              ?.map(
                (p) => PlanPhase.fromMap(Map<String, dynamic>.from(p as Map)),
              )
              .toList() ??
          const [],
      status: resolvedStatus,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}
