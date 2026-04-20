// lib/features/rules_engine/viewmodel/rules_engine_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/rule_context.dart';
import '../model/rule_result.dart';
import '../model/rule_action.dart';
import '../model/rich_feature.dart';
import '../model/user_mode.dart';
import '../repository/rules_repository.dart';
import '../service/rule_engine_service.dart';
import '../../trading/model/news_event.dart';
import '../../../core/services/notification_service.dart';

// ── ViewModel ─────────────────────────────────────────────────────────────────

class RulesEngineViewModel extends StateNotifier<RuleContext> {
  final RuleEngineService _engine;
  final RulesRepository   _repo;

  RulesEngineViewModel(this._engine, this._repo)
      : super(RuleContext.initial()) {
    _load();
  }

  // ── Load persisted state ──────────────────────────────────────────────────

  void _load() {
    final locked          = _repo.loadLockedFeatures();
    final muted           = _repo.loadMuted();
    final meditationDone  = _repo.loadMeditationCompletedToday();

    state = state.copyWith(
      lockedFeatures:           locked,
      notificationsMuted:       muted,
      meditationCompletedToday: meditationDone,
    );

    // Run the engine immediately on load
    _runEngine();
  }

  // ── Run Engine ────────────────────────────────────────────────────────────

  void _runEngine() {
    // Always start from an empty locked set — rules re-derive everything from scratch.
    // This prevents stale persisted locks from surviving when their condition clears.
    final fresh   = state.copyWith(lockedFeatures: {});
    final results = _engine.evaluate(fresh);
    state         = _engine.applyResults(fresh, results);

    _persist();
    _handleSideEffects(results);
  }

  // ── Persist state changes ─────────────────────────────────────────────────

  Future<void> _persist() async {
    await _repo.saveLockedFeatures(state.lockedFeatures);
    await _repo.saveMuted(state.notificationsMuted);
  }

  // ── Side effects (notifications, cooldowns) ───────────────────────────────

  void _handleSideEffects(List<RuleResult> results) {
    for (final result in results) {
      for (final action in result.actions) {

        if (action.isMuteAction) {
          NotificationService.instance.mute();
        }

        if (action.type == RuleActionType.unmuteNotifications) {
          NotificationService.instance.unmute();
        }

        if (action.isCooldownAction &&
            action.cooldownDuration != null) {
          final expiry = DateTime.now()
              .add(action.cooldownDuration!);
          _repo.saveCooldownExpiry(expiry);
        }
      }
    }
  }

  // ── Public State Mutations ────────────────────────────────────────────────

  void setMode(UserMode mode) {
    state = state.copyWith(currentMode: mode);
    _runEngine();
  }

  void completeMeditation() {
    state = state.copyWith(meditationCompletedToday: true);
    _repo.saveMeditationCompleted();
    _runEngine();
  }

  void setTradingSessionActive(bool active) {
    state = state.copyWith(isTradingSessionActive: active);
    _runEngine();
  }

  void setBettingSessionActive(bool active) {
    state = state.copyWith(isBettingSessionActive: active);
    _runEngine();
  }

  void setConsecutiveLosses(int count) {
    state = state.copyWith(consecutiveLosses: count);
    _runEngine();
  }

  void setEmotionalState(bool unstable) {
    state = state.copyWith(isEmotionallyUnstable: unstable);
    _runEngine();
  }

  void setDeepWork(bool active) {
    state = state.copyWith(isDeepWorkActive: active);
    _runEngine();
  }

  void updateLatestNews(NewsEvent event) {
    state = state.copyWith(latestNewsEvent: event);
    _runEngine();
  }

  void muteNotifications() {
    state = state.copyWith(notificationsMuted: true);
    NotificationService.instance.mute();
    _repo.saveMuted(true);
  }

  void unmuteNotifications() {
    state = state.copyWith(notificationsMuted: false);
    NotificationService.instance.unmute();
    _repo.saveMuted(false);
  }

  // ── Convenience Getters ───────────────────────────────────────────────────

  bool isLocked(RichFeature feature) =>
      _engine.isLocked(feature, state);

  String lockReason(RichFeature feature) =>
      _engine.lockReason(feature, state);

  String unlockInstruction(RichFeature feature) =>
      _engine.unlockInstruction(feature, state);

  bool get isCooldownActive => _repo.isCooldownActive;

  Duration? get remainingCooldown => _repo.remainingCooldown;

  // ── Reset for new day ─────────────────────────────────────────────────────

  Future<void> resetForNewDay() async {
    await _repo.resetForNewDay();
    state = RuleContext.initial();
    _runEngine();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final rulesRepositoryProvider = Provider<RulesRepository>(
  (_) => RulesRepository(),
);

final ruleEngineServiceProvider = Provider<RuleEngineService>(
  (_) => RuleEngineService(),
);

final ruleContextProvider =
    StateNotifierProvider<RulesEngineViewModel, RuleContext>(
  (ref) => RulesEngineViewModel(
    ref.read(ruleEngineServiceProvider),
    ref.read(rulesRepositoryProvider),
  ),
);

// ── Derived providers ─────────────────────────────────────────────────────────

final lockedFeaturesProvider = Provider<Set<RichFeature>>(
  (ref) => ref.watch(ruleContextProvider).lockedFeatures,
);

final isFeatureLockedProvider =
    Provider.family<bool, RichFeature>((ref, feature) {
  return ref.watch(lockedFeaturesProvider).contains(feature);
});

final activeRuleResultsProvider =
    Provider<List<RuleResult>>((ref) {
  final engine  = ref.read(ruleEngineServiceProvider);
  final context = ref.watch(ruleContextProvider);
  return engine.evaluate(context);
});

final userModeProvider = Provider<UserMode>(
  (ref) => ref.watch(ruleContextProvider).currentMode,
);
