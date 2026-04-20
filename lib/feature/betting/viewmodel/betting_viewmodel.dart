// lib/features/betting/viewmodel/betting_viewmodel.dart

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
  final List<BetModel> recentBets;   // last 31 days, for history tab
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
    activeBets:              const [],
    todayBets:               const [],
    recentBets:              const [],
    bankroll:                BankrollModel.initial(),
    lockdown:                LockdownModel.unlocked(),
    rules:                   defaultBettingRules,
    plans:                   const [],
    activeTab:               'OVERVIEW',
    isLoading:               true,
    ruleConfirmationRequired: false,
  );

  BettingState copyWith({
    List<BetModel>?      activeBets,
    List<BetModel>?      todayBets,
    List<BetModel>?      recentBets,
    BankrollModel?       bankroll,
    LockdownModel?       lockdown,
    List<BettingRuleModel>? rules,
    List<BettingPlan>?   plans,
    String?              activeTab,
    bool?                isLoading,
    bool?                ruleConfirmationRequired,
  }) =>
      BettingState(
        activeBets:              activeBets              ?? this.activeBets,
        todayBets:               todayBets               ?? this.todayBets,
        recentBets:              recentBets              ?? this.recentBets,
        bankroll:                bankroll                ?? this.bankroll,
        lockdown:                lockdown                ?? this.lockdown,
        rules:                   rules                   ?? this.rules,
        plans:                   plans                   ?? this.plans,
        activeTab:               activeTab               ?? this.activeTab,
        isLoading:               isLoading               ?? this.isLoading,
        ruleConfirmationRequired: ruleConfirmationRequired ?? this.ruleConfirmationRequired,
      );

  double get totalExposure   => activeBets.fold(0, (s, b) => s + b.stake);
  double get todayProfitLoss => todayBets.fold(0, (s, b) => s + b.profitLoss);
  int    get todayLossCount  => todayBets.where((b) => b.status == BetStatus.lost).length;

  bool get isLocked     => lockdown.isLocked;
  bool get canPlaceBet  => !isLocked && !bankroll.isAtDailyStopLimit;

  BettingPlan? get activePlan =>
      plans.where((p) => p.isActive).isNotEmpty
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
    final todayBets  = _repo.loadTodayBets();
    final recentBets = _repo.loadRecentBets();
    final bankroll   = _repo.loadBankroll();
    final plans      = _repo.loadPlans();
    var   lockdown   = _repo.loadLockdown();

    if (lockdown.hasCooldown && !lockdown.cooldownActive) {
      lockdown = lockdown.unlock();
      _repo.saveLockdown(lockdown);
    }

    state = state.copyWith(
      activeBets:  activeBets,
      todayBets:   todayBets,
      recentBets:  recentBets,
      bankroll:    bankroll,
      plans:       plans,
      lockdown:    lockdown,
      isLoading:   false,
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
      id:              const Uuid().v4(),
      description:     description,
      type:            type,
      status:          BetStatus.active,
      stake:           stake,
      odds:            odds,
      placedAt:        DateTime.now(),
      reasoning:       reasoning,
      ruleChecked:     ruleChecked,
      potentialReturn: stake * odds,
    );

    await _repo.saveBet(bet);
    state = state.copyWith(
      activeBets:  [...state.activeBets, bet],
      todayBets:   [...state.todayBets, bet],
      recentBets:  [bet, ...state.recentBets],
      ruleConfirmationRequired: false,
    );
    return true;
  }

  // ── Settle Bet ────────────────────────────────────────────────────────────

  Future<void> settleBet(String id, BetStatus result,
      {double? cashoutAmount}) async {
    final bet = state.activeBets.firstWhere((b) => b.id == id);

    double? actualReturn;
    if (result == BetStatus.won) {
      actualReturn = bet.calculatedPotentialReturn;
    } else if (result == BetStatus.cashout && cashoutAmount != null) {
      actualReturn = cashoutAmount;
    }

    final settled = bet.copyWith(
      status:       result,
      settledAt:    DateTime.now(),
      actualReturn: actualReturn,
    );

    await _repo.saveBet(settled);

    final updatedActive = state.activeBets.where((b) => b.id != id).toList();
    final updatedToday  = state.todayBets.map((b) => b.id == id ? settled : b).toList();

    var newBankroll = state.bankroll;
    if (result == BetStatus.won) {
      newBankroll = newBankroll.adjustBalance(settled.calculatedPotentialReturn - settled.stake);
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
          reason:           LockdownReason.consecutiveLosses,
          cooldownDuration: Duration(hours: AppConstants.bettingCooldownHours),
        );
      }
    } else if (result == BetStatus.won) {
      lockdown = lockdown.resetLosses();
    }
    await _repo.saveLockdown(lockdown);

    // Keep recentBets in sync (replace if exists, else add)
    final updatedRecent = state.recentBets.map((b) => b.id == id ? settled : b).toList();
    if (!updatedRecent.any((b) => b.id == id)) updatedRecent.add(settled);

    state = state.copyWith(
      activeBets:  updatedActive,
      todayBets:   updatedToday,
      recentBets:  updatedRecent,
      bankroll:    newBankroll,
      lockdown:    lockdown,
    );

    if (newBankroll.isAtDailyStopLimit) {
      await _applyLock(LockdownReason.dailyStopReached);
    }
  }

  // ── Betting Plans ─────────────────────────────────────────────────────────

  /// Create a plan manually (user will add steps one by one).
  Future<void> createPlan({
    required String name,
    required double startingCapital,
    required double targetCapital,
    List<PlanPhase> phases = const [],
  }) async {
    // Deactivate any existing active plan
    final deactivated = state.plans.map((p) =>
      p.isActive ? p.copyWith(status: BettingPlanStatus.abandoned) : p,
    ).toList();
    for (final p in deactivated.where((p) => p.status == BettingPlanStatus.abandoned &&
        state.plans.firstWhere((o) => o.id == p.id).isActive)) {
      await _repo.savePlan(p);
    }

    final plan = BettingPlan(
      id:              const Uuid().v4(),
      name:            name,
      startingCapital: startingCapital,
      targetCapital:   targetCapital,
      currentBalance:  startingCapital,
      steps:           const [],
      phases:          phases,
      status:          BettingPlanStatus.active,
      createdAt:       DateTime.now(),
    );
    await _repo.savePlan(plan);
    state = state.copyWith(plans: [plan, ...deactivated]);
  }

  /// Create a plan from a rollover rule (auto-generates steps).
  Future<void> createPlanFromRule({
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double odds,
    required double reinvestPercent,
    List<PlanPhase> phases = const [],
    int maxSteps = 30,
  }) async {
    final existing = state.plans.map((p) =>
      p.isActive ? p.copyWith(status: BettingPlanStatus.abandoned) : p,
    ).toList();
    for (final p in existing) { await _repo.savePlan(p); }

    final plan = BettingPlan.buildFromRule(
      id:              const Uuid().v4(),
      name:            name,
      startingCapital: startingCapital,
      targetCapital:   targetCapital,
      odds:            odds,
      reinvestPercent: reinvestPercent,
      phases:          phases,
      maxSteps:        maxSteps,
    );
    await _repo.savePlan(plan);
    state = state.copyWith(plans: [plan, ...existing]);
  }

  /// Add a single step to the active plan.
  Future<void> addStepToPlan({
    required double stake,
    required double odds,
    double kept = 0,
    int? phase,
  }) async {
    final plan = state.activePlan;
    if (plan == null) return;
    final newStep = BettingPlanStep(
      step:  plan.steps.length + 1,
      stake: stake,
      odds:  odds,
      kept:  kept,
      phase: phase ?? plan.currentPhase,
    );
    final updated = plan.copyWith(steps: [...plan.steps, newStep]);
    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  /// Mark a plan step as won or lost.
  /// If lost → plan is marked LOST (one step fails = plan fails).
  /// If won and target reached → plan is marked WON.
  Future<void> settlePlanStep(String planId, int stepNum, BettingPlanStepStatus result) async {
    final plan = state.plans.firstWhere((p) => p.id == planId);
    final updated = plan.settleStep(stepNum, result);

    if (updated.status == BettingPlanStatus.won) {
      await NotificationService.instance.show(
        id:      31,
        title:   'Plan WON!',
        body:    '${updated.name} — target of ${updated.targetCapital.toStringAsFixed(0)} TZS reached! Kept: ${updated.totalKept.toStringAsFixed(0)} TZS',
        channel: NotificationChannel.critical,
        payload: 'betting',
      );
    } else if (updated.status == BettingPlanStatus.lost) {
      await NotificationService.instance.show(
        id:      32,
        title:   'Plan LOST',
        body:    '${updated.name} — step $stepNum failed. Net: ${updated.netProfit >= 0 ? '+' : ''}${updated.netProfit.toStringAsFixed(0)} TZS (kept ${updated.totalKept.toStringAsFixed(0)} TZS)',
        channel: NotificationChannel.trading,
        payload: 'betting',
      );
    }

    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == planId ? updated : p).toList(),
    );

    final settledStep =
        updated.steps.firstWhere((s) => s.step == stepNum);
    await TrackingService.record(TrackingFeature.betting, {
      'stepsSettled': 1,
      'wins':         result == BettingPlanStepStatus.won  ? 1 : 0,
      'losses':       result == BettingPlanStepStatus.lost ? 1 : 0,
      'pnl': result == BettingPlanStepStatus.won
          ? (settledStep.potentialReturn - settledStep.stake)
          : -settledStep.stake,
      'kept': result == BettingPlanStepStatus.won ? settledStep.kept : 0.0,
    });
  }

  /// Replace the phase list on the active plan. Lets the user add phases
  /// to a plan that was created without any, or tweak an existing set.
  Future<void> updatePlanPhases(String planId, List<PlanPhase> phases) async {
    final plan = state.plans.firstWhere((p) => p.id == planId);
    final updated = plan.copyWith(phases: phases);
    await _repo.savePlan(updated);
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == planId ? updated : p).toList(),
    );
  }

  /// Delete a plan.
  Future<void> deletePlan(String id) async {
    await _repo.deletePlan(id);
    state = state.copyWith(plans: state.plans.where((p) => p.id != id).toList());
  }

  // ── Lockdown ──────────────────────────────────────────────────────────────

  Future<void> _applyLock(LockdownReason reason, {Duration? cooldown}) async {
    final locked = state.lockdown.lock(reason: reason, cooldownDuration: cooldown);
    await _repo.saveLockdown(locked);
    state = state.copyWith(lockdown: locked);
    await NotificationService.instance.show(
      id:      30,
      title:   'Betting Locked',
      body:    locked.reason?.description ?? 'Betting is locked.',
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

  /// Resets the bankroll entirely with a new starting amount.
  Future<void> setStartingCapital(double amount) async {
    final fresh = BankrollModel.initial(startingAmount: amount);
    await _repo.saveBankroll(fresh);
    state = state.copyWith(bankroll: fresh);
  }

  /// Adds funds to the existing bankroll (top-up, keeps history).
  Future<void> addCapital(double amount) async {
    final updated = BankrollModel(
      startingBalance: state.bankroll.startingBalance + amount,
      currentBalance:  state.bankroll.currentBalance  + amount,
      dailyStopLimit:  state.bankroll.dailyStopLimit,
      maxStakePercent: state.bankroll.maxStakePercent,
      weeklyTarget:    state.bankroll.weeklyTarget,
      lastUpdated:     DateTime.now(),
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
      dailyStopLimit:  dailyStopLimit,
      maxStakePercent: maxStakePercent,
      weeklyTarget:    weeklyTarget,
    );
    await _repo.saveBankroll(updated);
    state = state.copyWith(bankroll: updated);
  }

  void clearRuleConfirmation() {
    state = state.copyWith(ruleConfirmationRequired: false);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final bettingRepositoryProvider = Provider<BettingRepository>(
  (_) => BettingRepository(),
);

final bettingViewModelProvider =
    StateNotifierProvider<BettingViewModel, BettingState>(
  (ref) => BettingViewModel(ref.read(bettingRepositoryProvider), ref),
);
