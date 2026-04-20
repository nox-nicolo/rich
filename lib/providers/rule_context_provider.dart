// lib/providers/rule_context_provider.dart
//
// The single source of truth for the entire rule evaluation context.
// Every feature that needs to affect rule engine state writes here.
// The rule engine reads this to determine locks, mutes, and warnings.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/rules_engine/model/rule_context.dart';
import '../feature/rules_engine/model/rich_feature.dart';
import '../feature/rules_engine/model/user_mode.dart';
import '../feature/rules_engine/repository/rules_repository.dart';
import '../feature/trading/model/news_event.dart';

class RuleContextNotifier extends StateNotifier<RuleContext> {
  RuleContextNotifier(RulesRepository repo) : super(RuleContext.initial()) {
    // Load persisted meditation status so trading unlocks on cold start
    final meditationDone = repo.loadMeditationCompletedToday();
    if (meditationDone) {
      state = state.copyWith(meditationCompletedToday: true);
    }
  }

  // ── Mode ──────────────────────────────────────────────────────────────────

  void setMode(UserMode mode) {
    state = state.copyWith(currentMode: mode);
  }

  // ── Meditation ────────────────────────────────────────────────────────────

  void completeMeditation() {
    // Gate-driven unlock: trading & betting open the moment meditation completes.
    final unlocked = state.lockedFeatures
        .where((f) => f != RichFeature.trading && f != RichFeature.betting)
        .toSet();
    state = state.copyWith(
      meditationCompletedToday: true,
      lockedFeatures: unlocked,
    );
  }

  void resetMeditationGate() {
    state = state.copyWith(meditationCompletedToday: false);
  }

  // ── Trading ───────────────────────────────────────────────────────────────

  void setTradingSessionActive(bool active) {
    state = state.copyWith(isTradingSessionActive: active);
  }

  // ── Betting ───────────────────────────────────────────────────────────────

  void setBettingSessionActive(bool active) {
    state = state.copyWith(isBettingSessionActive: active);
  }

  void setConsecutiveLosses(int count) {
    state = state.copyWith(consecutiveLosses: count);
  }

  void incrementConsecutiveLosses() {
    state = state.copyWith(
        consecutiveLosses: state.consecutiveLosses + 1);
  }

  void resetConsecutiveLosses() {
    state = state.copyWith(consecutiveLosses: 0);
  }

  // ── Emotional State ───────────────────────────────────────────────────────

  void setEmotionalState(bool unstable) {
    state = state.copyWith(isEmotionallyUnstable: unstable);
  }

  // ── Work ──────────────────────────────────────────────────────────────────

  void setDeepWork(bool active) {
    state = state.copyWith(isDeepWorkActive: active);
  }

  // ── News ──────────────────────────────────────────────────────────────────

  void updateLatestNews(NewsEvent event) {
    state = state.copyWith(latestNewsEvent: event);
  }

  void clearLatestNews() {
    state = state.copyWith(latestNewsEvent: null);
  }

  // ── Locks ─────────────────────────────────────────────────────────────────

  void lockFeature(RichFeature feature) {
    state = state.copyWith(
      lockedFeatures: {...state.lockedFeatures, feature},
    );
  }

  void unlockFeature(RichFeature feature) {
    final updated = Set<RichFeature>.from(state.lockedFeatures)
      ..remove(feature);
    state = state.copyWith(lockedFeatures: updated);
  }

  void setLockedFeatures(Set<RichFeature> features) {
    state = state.copyWith(lockedFeatures: features);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void muteNotifications() {
    state = state.copyWith(notificationsMuted: true);
  }

  void unmuteNotifications() {
    state = state.copyWith(notificationsMuted: false);
  }

  // ── Apply external context update (from rule engine) ─────────────────────

  void applyUpdated(RuleContext updated) {
    state = updated;
  }

  // ── Reset for new day ─────────────────────────────────────────────────────

  void resetForNewDay() {
    state = RuleContext.initial();
  }
}

final _rulesRepositoryProvider = Provider<RulesRepository>(
  (_) => RulesRepository(),
);

final ruleContextProvider =
    StateNotifierProvider<RuleContextNotifier, RuleContext>(
  (ref) => RuleContextNotifier(ref.read(_rulesRepositoryProvider)),
);
