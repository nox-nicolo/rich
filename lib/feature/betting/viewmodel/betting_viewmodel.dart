// lib/features/betting/viewmodel/betting_viewmodel.dart
//
// KEY ROLLOVER RULES (fixes three prior bugs):
//
//  1. Next step's stake  = previous step's (return − kept), NOT full return.
//     Kept money exits the rollover chain immediately.
//
//  2. Phase / plan total = last step's net rollover (return − kept)
//                         + sum of ALL kept across every step in that scope.
//     Individual step returns must NEVER be summed — they double-count every
//     rollover because the winning return of step N becomes the stake of N+1.
//
//  3. Per-step tracking PnL = kept (realized pocket money for that step).
//     The remainder (return − kept) is still at risk in the next bet, so it
//     is not "profit" until the plan concludes.
//     Plan-level net PnL is recorded once, when the plan wins or loses.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/bet_model.dart';
import '../model/bankroll_model.dart';
import '../model/betting_rule_model.dart';
import '../model/lockdown_model.dart';
import '../model/betting_plan_model.dart';
import '../repository/betting_repository.dart';
import '../../../providers/rule_context_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BettingState {
  final List<BetModel> activeBets;
  final List<BetModel> todayBets;
  final List<BetModel> recentBets;
  final BankrollModel bankroll;
  final LockdownModel lockdown;
  final List<BettingRuleModel> rules;
  final List<BettingPlan> plans;
  final String activeTab;
  final bool isLoading;
  final bool ruleConfirmationRequired;

  const BettingState({
    required this.activeBets,
    required this.todayBets,
    required this.recentBets,
    required this.bankroll,
    required this.lockdown,
    required this.rules,
    required this.plans,
    required this.activeTab,
    required this.isLoading,
    required this.ruleConfirmationRequired,
  });

  factory BettingState.initial() => BettingState(
    activeBets: const [],
    todayBets: const [],
    recentBets: const [],
    bankroll: BankrollModel.initial(),
    lockdown: LockdownModel.unlocked(),
    rules: defaultBettingRules,
    plans: const [],
    activeTab: 'OVERVIEW',
    isLoading: true,
    ruleConfirmationRequired: false,
  );

  BettingState copyWith({
    List<BetModel>? activeBets,
    List<BetModel>? todayBets,
    List<BetModel>? recentBets,
    BankrollModel? bankroll,
    LockdownModel? lockdown,
    List<BettingRuleModel>? rules,
    List<BettingPlan>? plans,
    String? activeTab,
    bool? isLoading,
    bool? ruleConfirmationRequired,
  }) => BettingState(
    activeBets: activeBets ?? this.activeBets,
    todayBets: todayBets ?? this.todayBets,
    recentBets: recentBets ?? this.recentBets,
    bankroll: bankroll ?? this.bankroll,
    lockdown: lockdown ?? this.lockdown,
    rules: rules ?? this.rules,
    plans: plans ?? this.plans,
    activeTab: activeTab ?? this.activeTab,
    isLoading: isLoading ?? this.isLoading,
    ruleConfirmationRequired:
        ruleConfirmationRequired ?? this.ruleConfirmationRequired,
  );

  double get totalExposure => activeBets.fold(0, (s, b) => s + b.stake);
  double get todayProfitLoss => todayBets.fold(0, (s, b) => s + b.profitLoss);
  int get todayLossCount =>
      todayBets.where((b) => b.status == BetStatus.lost).length;

  bool get isLocked => lockdown.isLocked;
  bool get canPlaceBet => !isLocked && !bankroll.isAtDailyStopLimit;

  BettingPlan? get activePlan => plans.where((p) => p.isActive).isNotEmpty
      ? plans.firstWhere((p) => p.isActive)
      : null;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class BettingViewModel extends StateNotifier<BettingState> {
  final BettingRepository _repo;
  final Ref _ref;

  BettingViewModel(this._repo, this._ref) : super(BettingState.initial()) {
    _load();
  }

  void _load() {
    final activeBets = _repo.loadActiveBets();
    final todayBets = _repo.loadTodayBets();
    final recentBets = _repo.loadRecentBets();
    final bankroll = _repo.loadBankroll();
    final plans = _repo.loadPlans();
    var lockdown = _repo.loadLockdown();

    if (lockdown.hasCooldown && !lockdown.cooldownActive) {
      lockdown = lockdown.unlock();
      _repo.saveLockdown(lockdown);
    }

    state = state.copyWith(
      activeBets: activeBets,
      todayBets: todayBets,
      recentBets: recentBets,
      bankroll: bankroll,
      plans: plans,
      lockdown: lockdown,
      isLoading: false,
    );

    _checkRuleEngineState();
  }

  void _checkRuleEngineState() {
    final ruleCtx = _ref.read(ruleContextProvider);
    if (ruleCtx.isTradingSessionActive && !state.lockdown.isLocked) {
      _applyLock(LockdownReason.tradingSessionActive);
    }
    if (ruleCtx.isEmotionallyUnstable && !state.lockdown.isLocked) {
      _applyLock(LockdownReason.emotionalState);
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  // ── Place Bet ─────────────────────────────────────────────────────────────

  Future<bool> placeBet({
    required String description,
    required double stake,
    required double odds,
    required BetType type,
    required String reasoning,
    required bool ruleChecked,
  }) async {
    if (!state.canPlaceBet) return false;
    if (!ruleChecked) {
      state = state.copyWith(ruleConfirmationRequired: true);
      return false;
    }
    if (stake > state.bankroll.maxStakeAmount) return false;

    final bet = BetModel(
      id: const Uuid().v4(),
      description: description,
      type: type,
      status: BetStatus.active,
      stake: stake,
      odds: odds,
      placedAt: DateTime.now(),
      reasoning: reasoning,
      ruleChecked: ruleChecked,
      potentialReturn: stake * odds,
    );

    await _repo.saveBet(bet);
    state = state.copyWith(
      activeBets: [...state.activeBets, bet],
      todayBets: [...state.todayBets, bet],
      recentBets: [bet, ...state.recentBets],
      ruleConfirmationRequired: false,
    );
    return true;
  }

  // ── Settle Bet ────────────────────────────────────────────────────────────

  Future<void> settleBet(
    String id,
    BetStatus result, {
    double? cashoutAmount,
  }) async {
    final bet = state.activeBets.firstWhere((b) => b.id == id);

    double? actualReturn;
    if (result == BetStatus.won) {
      actualReturn = bet.calculatedPotentialReturn;
    } else if (result == BetStatus.cashout && cashoutAmount != null) {
      actualReturn = cashoutAmount;
    }

    final settled = bet.copyWith(
      status: result,
      settledAt: DateTime.now(),
      actualReturn: actualReturn,
    );

    await _repo.saveBet(settled);

    final updatedActive = state.activeBets.where((b) => b.id != id).toList();
    final updatedToday = state.todayBets
        .map((b) => b.id == id ? settled : b)
        .toList();

    var newBankroll = state.bankroll;
    if (result == BetStatus.won) {
      newBankroll = newBankroll.adjustBalance(
        settled.calculatedPotentialReturn - settled.stake,
      );
    } else if (result == BetStatus.lost) {
      newBankroll = newBankroll.adjustBalance(-settled.stake);
    } else if (result == BetStatus.cashout && cashoutAmount != null) {
      newBankroll = newBankroll.adjustBalance(cashoutAmount - settled.stake);
    }
    await _repo.saveBankroll(newBankroll);

    var lockdown = state.lockdown;
    if (result == BetStatus.lost) {
      lockdown = lockdown.incrementLoss();
      if (lockdown.consecutiveLosses >= AppConstants.maxConsecutiveLosses) {
        lockdown = lockdown.lock(
          reason: LockdownReason.consecutiveLosses,
          cooldownDuration: Duration(hours: AppConstants.bettingCooldownHours),
        );
      }
    } else if (result == BetStatus.won) {
      lockdown = lockdown.resetLosses();
    }
    await _repo.saveLockdown(lockdown);

    final updatedRecent = state.recentBets
        .map((b) => b.id == id ? settled : b)
        .toList();
    if (!updatedRecent.any((b) => b.id == id)) updatedRecent.add(settled);

    state = state.copyWith(
      activeBets: updatedActive,
      todayBets: updatedToday,
      recentBets: updatedRecent,
      bankroll: newBankroll,
      lockdown: lockdown,
    );

    if (newBankroll.isAtDailyStopLimit) {
      await _applyLock(LockdownReason.dailyStopReached);
    }
  }

  // ── Betting Plans ─────────────────────────────────────────────────────────

  Future<void> createPlan({
    required String name,
    required double startingCapital,
    required double targetCapital,
    List<PlanPhase> phases = const [],
  }) async {
    final effectiveTarget = phases.isEmpty
        ? targetCapital
        : phases.fold(0.0, (sum, phase) => sum + phase.target);
    final deactivated = state.plans
        .map(
          (p) =>
              p.isActive ? p.copyWith(status: BettingPlanStatus.abandoned) : p,
        )
        .toList();
    for (final p in deactivated.where(
      (p) =>
          p.status == BettingPlanStatus.abandoned &&
          state.plans.firstWhere((o) => o.id == p.id).isActive,
    )) {
      await _repo.savePlan(p);
    }

    final plan = BettingPlan(
      id: const Uuid().v4(),
      name: name,
      startingCapital: startingCapital,
      targetCapital: effectiveTarget,
      currentBalance: startingCapital,
      steps: const [],
      phases: phases,
      status: BettingPlanStatus.active,
      createdAt: DateTime.now(),
    );
    await _repo.savePlan(plan);
    state = state.copyWith(plans: [plan, ...deactivated]);
  }

  /// Create a plan from a rollover rule.
  ///
  /// ROLLOVER RULE (enforced here and must also be enforced in BettingPlan.buildFromRule):
  ///   step[0].stake = startingCapital
  ///   step[n+1].stake = step[n].return − step[n].kept
  ///                   = (step[n].stake × odds) − step[n].kept
  ///
  /// The kept amount exits the rollover chain immediately. It must NOT be
  /// included in the next stake, and it must NOT be added to the running
  /// balance until the plan is settled (it accumulates separately).
  Future<void> createPlanFromRule({
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double odds,
    required double
    reinvestPercent, // 0.0–1.0; kept = (1 − reinvestPercent) × return
    List<PlanPhase> phases = const [],
    int maxSteps = 30,
  }) async {
    final effectiveTarget = phases.isEmpty
        ? targetCapital
        : phases.fold(0.0, (sum, phase) => sum + phase.target);
    final existing = state.plans
        .map(
          (p) =>
              p.isActive ? p.copyWith(status: BettingPlanStatus.abandoned) : p,
        )
        .toList();
    for (final p in existing) {
      await _repo.savePlan(p);
    }

    // BettingPlan.buildFromRule MUST implement the rollover rule above.
    // See model documentation for the correct algorithm.
    final plan = BettingPlan.buildFromRule(
      id: const Uuid().v4(),
      name: name,
      startingCapital: startingCapital,
      targetCapital: effectiveTarget,
      odds: odds,
      reinvestPercent: reinvestPercent,
      phases: phases,
      maxSteps: maxSteps,
    );
    await _repo.savePlan(plan);
    state = state.copyWith(plans: [plan, ...existing]);
  }

  Future<void> reusePlan(BettingPlan source) async {
    final deactivated = state.plans
        .map(
          (p) =>
              p.isActive ? p.copyWith(status: BettingPlanStatus.abandoned) : p,
        )
        .toList();
    for (final p in deactivated) {
      final original = state.plans.firstWhere((o) => o.id == p.id);
      if (p.status == BettingPlanStatus.abandoned && original.isActive) {
        await _repo.savePlan(p);
      }
    }

    final freshSteps = source.steps
        .map(
          (s) => BettingPlanStep(
            step: s.step,
            stake: s.stake,
            odds: s.odds,
            kept: s.kept,
            phase: s.phase,
            status: BettingPlanStepStatus.pending,
          ),
        )
        .toList();

    final plan = BettingPlan(
      id: const Uuid().v4(),
      name: source.name,
      startingCapital: source.startingCapital,
      targetCapital: source.targetCapital,
      currentBalance: source.startingCapital,
      steps: freshSteps,
      phases: List<PlanPhase>.from(source.phases),
      status: BettingPlanStatus.active,
      createdAt: DateTime.now(),
    );
    await _repo.savePlan(plan);
    state = state.copyWith(plans: [plan, ...deactivated]);
  }

  Future<void> addStepToPlan({
    required double stake,
    required double odds,
    double kept = 0,
    int? phase,
  }) async {
    final plan = state.activePlan;
    if (plan == null) return;
    final newStep = BettingPlanStep(
      step: plan.steps.length + 1,
      stake: stake,
      odds: odds,
      kept: kept,
      phase: phase ?? plan.currentPhase,
    );
    final updated = plan.copyWith(steps: [...plan.steps, newStep]);
    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  /// Settle a single plan step and update tracking.
  ///
  /// CORRECT MONEY FLOW:
  ///   Won step:  rollover to next bet = step.return − step.kept
  ///              realized pocket money = step.kept
  ///   Lost step: plan is over, total money = sum of all kept so far
  ///
  /// WHAT NOT TO DO:
  ///   ❌ Do NOT record (potentialReturn − stake) as PnL per step — this
  ///      double-counts every rollover because the return becomes the next stake.
  ///   ❌ Do NOT sum individual step returns to get the plan total.
  ///
  /// WHAT TO DO:
  ///   ✅ Per-step PnL = kept (the only money that leaves the rollover chain).
  ///   ✅ Plan-level PnL recorded once at conclusion:
  ///        finalBalance = last_won_step.return − last_won_step.kept + totalKept
  ///        netPnl       = finalBalance − startingCapital
  ///
  ///   The model's finalBalance / netProfit MUST follow the same formula.
  Future<void> settlePlanStep(
    String planId,
    int stepNum,
    BettingPlanStepStatus result,
  ) async {
    final plan = state.plans.firstWhere((p) => p.id == planId);
    // model.settleStep must:
    //   1. Mark the step won/lost.
    //   2. Set currentBalance = last_won_step.(return − kept) + totalKept,
    //      NOT by summing all individual step returns.
    //   3. Mark plan WON if currentBalance >= targetCapital,
    //      mark plan LOST if step is lost.
    final updated = plan.settleStep(stepNum, result);

    // ── Notifications ────────────────────────────────────────────────────────
    if (updated.status == BettingPlanStatus.won) {
      // finalBalance = last step's net rollover + all accumulated kept.
      // This is what the model must expose as updated.finalBalance.
      final finalBalance = updated.finalBalance; // model property (see below)
      await NotificationService.instance.show(
        id: 31,
        title: '🏆 Plan WON!',
        body:
            '${updated.name} — '
            'Final: ${finalBalance.toStringAsFixed(0)} TZS '
            '(kept ${updated.totalKept.toStringAsFixed(0)} TZS)',
        channel: NotificationChannel.critical,
        payload: 'betting',
      );
    } else if (updated.status == BettingPlanStatus.lost) {
      // Lost: you have only what was kept along the way.
      await NotificationService.instance.show(
        id: 32,
        title: 'Plan LOST — step $stepNum',
        body:
            '${updated.name} — '
            'Kept: ${updated.totalKept.toStringAsFixed(0)} TZS / '
            'Started: ${updated.startingCapital.toStringAsFixed(0)} TZS',
        channel: NotificationChannel.trading,
        payload: 'betting',
      );
    }

    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == planId ? updated : p).toList(),
    );

    final settledStep = updated.steps.firstWhere((s) => s.step == stepNum);

    // ── Per-step tracking ────────────────────────────────────────────────────
    // Only the kept amount is realized money per step. The rest rolls over and
    // is still at risk — recording it as profit here would inflate the totals.
    await TrackingService.record(TrackingFeature.betting, {
      'stepsSettled': 1,
      'wins': result == BettingPlanStepStatus.won ? 1 : 0,
      'losses': result == BettingPlanStepStatus.lost ? 1 : 0,
      // ✅ kept = money actually pocketed this step (exits the rollover chain)
      // ❌ NOT (potentialReturn − stake) — that double-counts rollovers
      'pnl': result == BettingPlanStepStatus.won
          ? settledStep.kept
          : -settledStep.stake,
      'kept': result == BettingPlanStepStatus.won ? settledStep.kept : 0.0,
    });

    // ── Plan-level tracking (recorded once at conclusion) ─────────────────
    // This is the single source of truth for the plan's net result.
    // finalBalance = last_won_step.(return − kept) + totalKept
    // netPnl       = finalBalance − startingCapital
    if (updated.status == BettingPlanStatus.won ||
        updated.status == BettingPlanStatus.lost) {
      final finalBalance = updated.status == BettingPlanStatus.won
          ? updated
                .finalBalance // last step net rollover + total kept
          : updated.totalKept; // lost: only kept money survives
      await TrackingService.record(TrackingFeature.betting, {
        'plansSettled': 1,
        'planWins': updated.status == BettingPlanStatus.won ? 1 : 0,
        'planLosses': updated.status == BettingPlanStatus.lost ? 1 : 0,
        'planFinalBalance': finalBalance,
        'planNetPnl': finalBalance - updated.startingCapital,
        'planTotalKept': updated.totalKept,
        'planStartingCapital': updated.startingCapital,
      });
    }
  }

  Future<void> updatePlanPhases(String planId, List<PlanPhase> phases) async {
    final plan = state.plans.firstWhere((p) => p.id == planId);
    final effectiveTarget = phases.isEmpty
        ? plan.targetCapital
        : phases.fold(0.0, (sum, phase) => sum + phase.target);
    final updated = plan.copyWith(
      phases: phases,
      targetCapital: effectiveTarget,
    );
    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == planId ? updated : p).toList(),
    );
  }

  Future<void> deletePlan(String id) async {
    await _repo.deletePlan(id);
    state = state.copyWith(
      plans: state.plans.where((p) => p.id != id).toList(),
    );
  }

  // ── Lockdown ──────────────────────────────────────────────────────────────

  Future<void> _applyLock(LockdownReason reason, {Duration? cooldown}) async {
    final locked = state.lockdown.lock(
      reason: reason,
      cooldownDuration: cooldown,
    );
    await _repo.saveLockdown(locked);
    state = state.copyWith(lockdown: locked);
    await NotificationService.instance.show(
      id: 30,
      title: 'Betting Locked',
      body: locked.reason?.description ?? 'Betting is locked.',
      channel: NotificationChannel.critical,
      payload: 'betting',
    );
  }

  Future<void> manualLock() => _applyLock(LockdownReason.manualLock);

  Future<void> unlock() async {
    if (state.lockdown.reason == LockdownReason.tradingSessionActive) return;
    if (state.lockdown.cooldownActive) return;
    final unlocked = state.lockdown.unlock();
    await _repo.saveLockdown(unlocked);
    state = state.copyWith(lockdown: unlocked);
  }

  // ── Bankroll ──────────────────────────────────────────────────────────────

  Future<void> setStartingCapital(double amount) async {
    final fresh = BankrollModel.initial(startingAmount: amount);
    await _repo.saveBankroll(fresh);
    state = state.copyWith(bankroll: fresh);
  }

  Future<void> addCapital(double amount) async {
    final updated = BankrollModel(
      startingBalance: state.bankroll.startingBalance + amount,
      currentBalance: state.bankroll.currentBalance + amount,
      dailyStopLimit: state.bankroll.dailyStopLimit,
      maxStakePercent: state.bankroll.maxStakePercent,
      weeklyTarget: state.bankroll.weeklyTarget,
      lastUpdated: DateTime.now(),
    );
    await _repo.saveBankroll(updated);
    state = state.copyWith(bankroll: updated);
  }

  Future<void> updateBankrollSettings({
    double? dailyStopLimit,
    double? maxStakePercent,
    double? weeklyTarget,
  }) async {
    final updated = state.bankroll.copyWith(
      dailyStopLimit: dailyStopLimit,
      maxStakePercent: maxStakePercent,
      weeklyTarget: weeklyTarget,
    );
    await _repo.saveBankroll(updated);
    state = state.copyWith(bankroll: updated);
  }

  void clearRuleConfirmation() =>
      state = state.copyWith(ruleConfirmationRequired: false);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final bettingRepositoryProvider = Provider<BettingRepository>(
  (_) => BettingRepository(),
);

final bettingViewModelProvider =
    StateNotifierProvider<BettingViewModel, BettingState>(
      (ref) => BettingViewModel(ref.read(bettingRepositoryProvider), ref),
    );

// ══════════════════════════════════════════════════════════════════════════════
// MODEL CHANGES REQUIRED — betting_plan_model.dart
// ══════════════════════════════════════════════════════════════════════════════
//
// ── buildFromRule (step generation) ──────────────────────────────────────────
//
//   double stake = startingCapital;
//   for (int i = 0; i < maxSteps; i++) {
//     final grossReturn = stake * odds;
//     final kept        = grossReturn * (1 - reinvestPercent); // money taken out
//     final rollover    = grossReturn - kept;                  // next stake
//
//     steps.add(BettingPlanStep(
//       step:  i + 1,
//       stake: stake,
//       odds:  odds,
//       kept:  kept,
//       // potentialReturn stored on step = grossReturn (stake × odds)
//     ));
//
//     if (rollover >= targetCapital) break;
//     stake = rollover;   // ← next stake = return − kept, NOT full return
//   }
//
// ── settleStep (balance update) ───────────────────────────────────────────────
//
//   BettingPlan settleStep(int stepNum, BettingPlanStepStatus result) {
//     // 1. Mark the step.
//     final updatedSteps = steps.map((s) =>
//       s.step == stepNum ? s.copyWith(status: result) : s
//     ).toList();
//
//     // 2. Recalculate balance.
//     //    RULE: last won step determines the rollover; all kept amounts accumulate.
//     //    Do NOT sum individual step returns.
//     final wonSteps  = updatedSteps.where((s) => s.status == BettingPlanStepStatus.won);
//     final lastWon   = wonSteps.isNotEmpty ? wonSteps.last : null;
//     final totalKept = updatedSteps
//         .where((s) => s.status == BettingPlanStepStatus.won)
//         .fold(0.0, (sum, s) => sum + s.kept);
//
//     final newBalance = lastWon != null
//         ? (lastWon.potentialReturn - lastWon.kept) + totalKept
//         //   ↑ net rollover from last won step   ↑ all kept so far
//         : totalKept; // lost before any win: only kept money survives
//
//     // 3. Determine plan status.
//     BettingPlanStatus newStatus = status;
//     if (result == BettingPlanStepStatus.lost) {
//       newStatus = BettingPlanStatus.lost;
//     } else if (newBalance >= targetCapital) {
//       newStatus = BettingPlanStatus.won;
//     }
//
//     return copyWith(
//       steps:          updatedSteps,
//       currentBalance: newBalance,
//       status:         newStatus,
//     );
//   }
//
// ── Computed properties to expose ────────────────────────────────────────────
//
//   // Money actually in hand right now (last won step rollover + all kept)
//   double get finalBalance {
//     final wonSteps  = steps.where((s) => s.status == BettingPlanStepStatus.won);
//     final lastWon   = wonSteps.isNotEmpty ? wonSteps.last : null;
//     final totalKept = wonSteps.fold(0.0, (sum, s) => sum + s.kept);
//     if (lastWon == null) return totalKept;
//     return (lastWon.potentialReturn - lastWon.kept) + totalKept;
//   }
//
//   double get totalKept => steps
//       .where((s) => s.status == BettingPlanStepStatus.won)
//       .fold(0.0, (sum, s) => sum + s.kept);
//
//   double get netProfit => finalBalance - startingCapital;
//
// ── Phase-level final balance (if plan has phases) ────────────────────────────
//
//   double finalBalanceForPhase(int phaseIndex) {
//     final phaseSteps = steps.where((s) => s.phase == phaseIndex);
//     final wonSteps   = phaseSteps.where((s) => s.status == BettingPlanStepStatus.won);
//     final lastWon    = wonSteps.isNotEmpty ? wonSteps.last : null;
//     final phaseKept  = wonSteps.fold(0.0, (sum, s) => sum + s.kept);
//     if (lastWon == null) return phaseKept;
//     return (lastWon.potentialReturn - lastWon.kept) + phaseKept;
//   }
//
// ══════════════════════════════════════════════════════════════════════════════
