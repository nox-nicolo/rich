// lib/features/trading/viewmodel/trading_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/trading_models.dart';
import '../model/trading_target_model.dart';
import '../model/trading_growth_plan_model.dart';
import '../model/trading_account_model.dart';
import '../repository/trading_repository.dart';
import '../../../providers/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';
import '../service/news_websocket_service.dart';
import '../service/trading_account_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class TradingState {
  final List<TradingRule> rules;
  final List<JournalEntry> todayJournal;
  final List<BiasEntry> biasBoard;
  final List<TradingTarget> targets;
  final bool sessionActive;
  final TradingSession currentSession;
  final bool isLoading;
  final String? activeTab;
  final double startingCapital;
  final List<TradingGrowthPlan> growthPlans;
  // ── Trading account (broker bridge) ──
  final TradingAccountConfig? accountConfig;
  final BrokerAccountInfo? brokerInfo;
  final List<BrokerTrade> brokerTrades;
  final bool accountSyncing;
  final String? accountError;

  const TradingState({
    required this.rules,
    required this.todayJournal,
    required this.biasBoard,
    required this.targets,
    required this.sessionActive,
    required this.currentSession,
    required this.isLoading,
    this.activeTab = 'NEWS',
    this.startingCapital = 0,
    this.growthPlans = const [],
    this.accountConfig,
    this.brokerInfo,
    this.brokerTrades = const [],
    this.accountSyncing = false,
    this.accountError,
  });

  factory TradingState.initial() => TradingState(
    rules:          defaultTradingRules,
    todayJournal:   [],
    biasBoard:      [],
    targets:        [],
    growthPlans:    [],
    sessionActive:  false,
    currentSession: _detectSession(),
    isLoading:      false,
    startingCapital: 0,
  );

  static TradingSession _detectSession() {
    for (final s in TradingSession.values) {
      if (s.isActive) return s;
    }
    return TradingSession.other;
  }

  TradingTarget? get activeTarget =>
      targets.where((t) => t.status == TargetStatus.active).isNotEmpty
          ? targets.firstWhere((t) => t.status == TargetStatus.active)
          : null;

  TradingGrowthPlan? get activeGrowthPlan =>
      growthPlans.where((p) => p.isActive).isNotEmpty
          ? growthPlans.firstWhere((p) => p.isActive)
          : null;

  TradingState copyWith({
    List<TradingRule>? rules,
    List<JournalEntry>? todayJournal,
    List<BiasEntry>? biasBoard,
    List<TradingTarget>? targets,
    List<TradingGrowthPlan>? growthPlans,
    bool? sessionActive,
    TradingSession? currentSession,
    bool? isLoading,
    String? activeTab,
    double? startingCapital,
    TradingAccountConfig? accountConfig,
    bool clearAccountConfig = false,
    BrokerAccountInfo? brokerInfo,
    List<BrokerTrade>? brokerTrades,
    bool? accountSyncing,
    String? accountError,
    bool clearAccountError = false,
  }) {
    return TradingState(
      rules:           rules          ?? this.rules,
      todayJournal:    todayJournal   ?? this.todayJournal,
      biasBoard:       biasBoard      ?? this.biasBoard,
      targets:         targets        ?? this.targets,
      growthPlans:     growthPlans    ?? this.growthPlans,
      sessionActive:   sessionActive  ?? this.sessionActive,
      currentSession:  currentSession ?? this.currentSession,
      isLoading:       isLoading      ?? this.isLoading,
      activeTab:       activeTab      ?? this.activeTab,
      startingCapital: startingCapital ?? this.startingCapital,
      accountConfig:   clearAccountConfig ? null : (accountConfig ?? this.accountConfig),
      brokerInfo:      brokerInfo     ?? this.brokerInfo,
      brokerTrades:    brokerTrades   ?? this.brokerTrades,
      accountSyncing:  accountSyncing ?? this.accountSyncing,
      accountError:    clearAccountError ? null : (accountError ?? this.accountError),
    );
  }
}


// ── ViewModel ─────────────────────────────────────────────────────────────────

class TradingViewModel extends StateNotifier<TradingState> {
  final Ref _ref;
  final TradingRepository _repo;
  NewsWebSocketService? _newsService;

  TradingViewModel(this._ref, this._repo) : super(TradingState.initial()) {
    _load();
  }

  void _load() {
    final journal      = _repo.loadTodayJournal();
    final biases       = _repo.loadBiasBoard();
    final targets      = _repo.loadTargets();
    final session      = _repo.loadSessionActive();
    final capital      = _repo.loadStartingCapital();
    final growthPlans  = _repo.loadGrowthPlans();
    final userRules    = _repo.loadCustomRules();
    final account      = _repo.loadAccountConfig();
    final brokerInfo   = _repo.loadBrokerInfo();
    final brokerTrades = _repo.loadBrokerTrades();
    state = state.copyWith(
      todayJournal:    journal,
      biasBoard:       biases,
      targets:         targets,
      sessionActive:   session,
      startingCapital: capital,
      growthPlans:     growthPlans,
      rules:           userRules,
      accountConfig:   account,
      brokerInfo:      brokerInfo,
      brokerTrades:    brokerTrades,
    );

    // Always fetch news on load so the NEWS tab has data
    _connectNews();

    // If an account is already configured, refresh in the background so
    // the ACCOUNT tab shows recent broker activity right away. If the
    // previous session never finished provisioning, retry it now.
    if (account != null) {
      if (account.isValid) {
        // ignore: discarded_futures
        syncAccount();
      } else if (account.canProvision) {
        // ignore: discarded_futures
        connectAccount(account);
      }
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  void startSession() {
    state = state.copyWith(sessionActive: true);
    _repo.saveSessionActive(true);
    _ref.read(ruleContextProvider.notifier).setTradingSessionActive(true);
    _ref.read(ruleContextProvider.notifier).setMode(UserMode.trading);
    TrackingService.record(TrackingFeature.trading, {'sessions': 1});
    VibrationService.strongPulse();
    _connectNews();
    NotificationService.instance.show(
      id:      10,
      title:   'Trading Session Started',
      body:    state.activeTarget != null
          ? 'Target: \$${state.activeTarget!.sessionTarget.toStringAsFixed(2)} this session.'
          : 'Session is live. Follow your rules.',
      channel: NotificationChannel.trading,
      payload: 'trading',
    );
  }

  void endSession() {
    state = state.copyWith(sessionActive: false);
    _repo.saveSessionActive(false);
    _ref.read(ruleContextProvider.notifier).setTradingSessionActive(false);
    _ref.read(ruleContextProvider.notifier).setMode(UserMode.idle);
    _newsService?.disconnect();
    VibrationService.strongPulse();
    NotificationService.instance.show(
      id:      11,
      title:   'Trading Session Ended',
      body:    'Log your reflection before closing.',
      channel: NotificationChannel.trading,
      payload: 'trading',
    );
  }

  // ── News ──────────────────────────────────────────────────────────────────

  void _connectNews() {
    // Disconnect the previous instance so its poll timer doesn't leak.
    _newsService?.disconnect();
    _newsService = NewsWebSocketService(
      onNews: (event) {
        _ref.read(newsProvider.notifier).addEvent(event);
        _ref.read(ruleContextProvider.notifier).updateLatestNews(event);
      },
    );
    _newsService!.connect();
  }

  void tagNewsSentiment(String newsId, NewsSentiment sentiment) {
    _ref.read(newsProvider.notifier).tagSentiment(newsId, sentiment);
  }

  /// Pull-to-refresh entry point for the News tab. Ensures a service exists
  /// (cold tab, no active session) and forces a fresh fetch of both the
  /// articles feed and the economic calendar.
  Future<void> refreshNews() async {
    if (_newsService == null) _connectNews();
    await _newsService!.refreshNow();
  }

  // ── Journal ───────────────────────────────────────────────────────────────

  /// Save or update any journal entry. If an entry with the same id exists it
  /// is replaced — this is how post-trade details are added to an existing
  /// pre-trade entry.
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final existingIdx = state.todayJournal.indexWhere((e) => e.id == entry.id);
    final stamped = existingIdx >= 0
        ? entry.copyWith(updatedAt: DateTime.now())
        : entry;

    await _repo.saveJournalEntry(stamped);

    final updated = [...state.todayJournal];
    if (existingIdx >= 0) {
      updated[existingIdx] = stamped;
    } else {
      updated.add(stamped);
    }
    state = state.copyWith(todayJournal: updated);
  }

  /// Create a new pre-trade entry. Post-trade fields stay empty until the
  /// user closes the trade and updates the same entry.
  Future<void> createTradeEntry({
    required String instrument,
    required TradeDirection direction,
    required double lotSize,
    required double entry,
    required double stopLoss,
    required double takeProfit,
    String? setup,
    String? preNotes,
  }) async {
    final journalEntry = JournalEntry(
      id:         const Uuid().v4(),
      type:       JournalEntryType.trade,
      createdAt:  DateTime.now(),
      instrument: instrument,
      direction:  direction,
      lotSize:    lotSize,
      entry:      entry,
      stopLoss:   stopLoss,
      takeProfit: takeProfit,
      setup:      setup,
      preNotes:   preNotes,
      outcome:    TradeOutcome.pending,
    );
    await saveJournalEntry(journalEntry);
  }

  /// Close a trade entry — fills in the post-trade fields on the same record.
  Future<void> closeTradeEntry({
    required String id,
    required double exit,
    required TradeOutcome outcome,
    required double pnl,
    String? postNotes,
    String? lessonLearned,
  }) async {
    final idx = state.todayJournal.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final current = state.todayJournal[idx];
    final closed = current.copyWith(
      exit:          exit,
      outcome:       outcome,
      pnl:           pnl,
      postNotes:     postNotes,
      lessonLearned: lessonLearned,
    );
    await saveJournalEntry(closed);

    await TrackingService.record(TrackingFeature.trading, {
      'trades':  1,
      'wins':    outcome == TradeOutcome.win  ? 1 : 0,
      'losses':  outcome == TradeOutcome.loss ? 1 : 0,
      'pnl':     pnl,
    });
    VibrationService.strongPulse();
  }

  Future<void> deleteJournalEntry(String id) async {
    await _repo.deleteJournalEntry(id);
    state = state.copyWith(
      todayJournal: state.todayJournal.where((e) => e.id != id).toList(),
    );
  }

  // ── Rules (user-defined) ───────────────────────────────────────────────────

  Future<void> addRule({
    required String title,
    required String description,
    bool isNoTradeRule = false,
  }) async {
    final rule = TradingRule(
      id:           const Uuid().v4(),
      title:        title,
      description:  description,
      isNoTradeRule: isNoTradeRule,
    );
    final updated = [...state.rules, rule];
    state = state.copyWith(rules: updated);
    await _repo.saveAllRules(updated);
  }

  Future<void> deleteRule(String id) async {
    final updated = state.rules.where((r) => r.id != id).toList();
    state = state.copyWith(rules: updated);
    await _repo.deleteRule(id);
  }

  // ── Bias ──────────────────────────────────────────────────────────────────

  void addBias({
    required String instrument,
    required BiasDirection direction,
    required String reasoning,
  }) {
    final bias = BiasEntry(
      id:         const Uuid().v4(),
      instrument: instrument,
      direction:  direction,
      reasoning:  reasoning,
      createdAt:  DateTime.now(),
      expiresAt:  DateTime.now().add(const Duration(hours: 24)),
    );
    final updated = [...state.biasBoard, bias];
    state = state.copyWith(biasBoard: updated);
    _repo.saveBiasBoard(updated);
  }

  void removeBias(String id) {
    final updated = state.biasBoard.where((b) => b.id != id).toList();
    state = state.copyWith(biasBoard: updated);
    _repo.saveBiasBoard(updated);
  }

  // ── Targets ───────────────────────────────────────────────────────────────

  Future<void> addTarget(TradingTarget target) async {
    await _repo.saveTarget(target);
    state = state.copyWith(targets: [target, ...state.targets]);
  }

  Future<void> updateTargetCapital(String id, double newCapital) async {
    final updated = state.targets.map((t) {
      if (t.id != id) return t;
      final completed = newCapital >= t.targetCapital;
      return t.copyWith(
        currentCapital: newCapital,
        status: completed ? TargetStatus.completed : t.status,
      );
    }).toList();
    final target = updated.firstWhere((t) => t.id == id);
    await _repo.saveTarget(target);
    state = state.copyWith(targets: updated);
    if (target.status == TargetStatus.completed) {
      await NotificationService.instance.show(
        id:      12,
        title:   'Target Reached!',
        body:    '${target.title} — \$${target.targetCapital.toStringAsFixed(2)} achieved.',
        channel: NotificationChannel.critical,
        payload: 'trading',
      );
    }
  }

  Future<void> abandonTarget(String id) async {
    final updated = state.targets.map((t) {
      if (t.id != id) return t;
      return t.copyWith(status: TargetStatus.abandoned);
    }).toList();
    final target = updated.firstWhere((t) => t.id == id);
    await _repo.saveTarget(target);
    state = state.copyWith(targets: updated);
  }

  Future<void> deleteTarget(String id) async {
    await _repo.deleteTarget(id);
    state = state.copyWith(
      targets: state.targets.where((t) => t.id != id).toList(),
    );
  }

  // ── Growth Plans ──────────────────────────────────────────────────────────

  Future<void> createGrowthPlan({
    required String name,
    required double startingCapital,
    required double targetCapital,
    required double dailyGrowthPercent,
    required int    totalDays,
    double          stopLossPercent = 2.0,
  }) async {
    // Deactivate existing active plan
    final deactivated = state.growthPlans.map((p) =>
      p.isActive ? p.copyWith(isActive: false) : p,
    ).toList();
    for (final p in deactivated) { await _repo.saveGrowthPlan(p); }

    final plan = TradingGrowthPlan.build(
      id:                 const Uuid().v4(),
      name:               name,
      startingCapital:    startingCapital,
      targetCapital:      targetCapital,
      dailyGrowthPercent: dailyGrowthPercent,
      totalDays:          totalDays,
      stopLossPercent:    stopLossPercent,
    );
    await _repo.saveGrowthPlan(plan);
    state = state.copyWith(growthPlans: [plan, ...deactivated]);
  }

  Future<void> markGrowthDay(
    String planId, int day, GrowthDayStatus status, {double? actualEnd}
  ) async {
    final updated = state.growthPlans.map((p) {
      if (p.id != planId) return p;
      return p.markDay(day, status, actualEnd: actualEnd);
    }).toList();
    final plan = updated.firstWhere((p) => p.id == planId);
    await _repo.saveGrowthPlan(plan);
    state = state.copyWith(growthPlans: updated);

    if (plan.completedDays >= plan.totalDays) {
      await NotificationService.instance.show(
        id:      13,
        title:   'Growth Plan Complete!',
        body:    '${plan.name} — all ${plan.totalDays} days done.',
        channel: NotificationChannel.critical,
        payload: 'trading',
      );
    }
  }

  Future<void> deleteGrowthPlan(String id) async {
    await _repo.deleteGrowthPlan(id);
    state = state.copyWith(
      growthPlans: state.growthPlans.where((p) => p.id != id).toList(),
    );
  }

  // ── Trading Account (broker bridge) ───────────────────────────────────────

  /// Save the provided credentials, provision with MetaApi if needed,
  /// then immediately attempt a sync.
  Future<void> connectAccount(TradingAccountConfig config) async {
    // Persist the raw credentials first so the user doesn't lose what they
    // typed if provisioning fails.
    await _repo.saveAccountConfig(config);
    state = state.copyWith(
      accountConfig: config,
      accountSyncing: true,
      clearAccountError: true,
    );

    TradingAccountConfig working = config;

    // If we don't yet have a MetaApi accountId, ask MetaApi to provision
    // one from the MT credentials.
    if (working.accountId.isEmpty && working.canProvision) {
      final svc = TradingAccountService(working);
      try {
        final res = await svc.provisionAccount();
        if (!res.ok) {
          state = state.copyWith(
            accountSyncing: false,
            accountError: 'Provisioning failed: ${res.error}',
          );
          return;
        }
        working = working.copyWith(accountId: res.data);
        await _repo.saveAccountConfig(working);
        state = state.copyWith(accountConfig: working);
      } finally {
        svc.dispose();
      }
    }

    await syncAccount();
  }

  /// Drop all stored credentials and cached broker data.
  Future<void> disconnectAccount() async {
    await _repo.saveAccountConfig(null);
    await _repo.saveBrokerTrades([]);
    await _repo.saveBrokerInfo(null);
    state = state.copyWith(
      clearAccountConfig: true,
      brokerTrades: const [],
      brokerInfo: null,
      clearAccountError: true,
    );
  }

  /// Pull latest open positions, history and account info from the broker.
  Future<void> syncAccount() async {
    final cfg = state.accountConfig;
    if (cfg == null || !cfg.isValid) return;

    state = state.copyWith(accountSyncing: true, clearAccountError: true);

    final svc = TradingAccountService(cfg);
    try {
      final infoRes     = await svc.fetchAccountInformation();
      final openRes     = await svc.fetchOpenPositions();
      final historyRes  = await svc.fetchHistory();

      final err = infoRes.error ?? openRes.error ?? historyRes.error;
      if (err != null) {
        state = state.copyWith(accountSyncing: false, accountError: err);
        return;
      }

      // Merge open + history, deduped by id, newest first.
      final merged = <String, BrokerTrade>{};
      for (final t in [...?openRes.data, ...?historyRes.data]) {
        merged[t.id] = t;
      }
      final trades = merged.values.toList()
        ..sort((a, b) => b.openTime.compareTo(a.openTime));

      await _repo.saveBrokerTrades(trades);
      await _repo.saveBrokerInfo(infoRes.data);

      state = state.copyWith(
        accountSyncing: false,
        brokerInfo:     infoRes.data,
        brokerTrades:   trades,
      );
    } finally {
      svc.dispose();
    }
  }

  // ── Capital ───────────────────────────────────────────────────────────────

  Future<void> setStartingCapital(double amount) async {
    await _repo.saveStartingCapital(amount);
    state = state.copyWith(startingCapital: amount);
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  @override
  void dispose() {
    _newsService?.disconnect();
    super.dispose();
  }
}

final tradingRepositoryProvider = Provider<TradingRepository>(
  (_) => TradingRepository(),
);

final tradingViewModelProvider =
    StateNotifierProvider<TradingViewModel, TradingState>((ref) {
  return TradingViewModel(ref, ref.read(tradingRepositoryProvider));
});
