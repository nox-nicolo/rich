// lib/features/rules_engine/model/rule_context.dart

import 'rich_feature.dart';
import 'user_mode.dart';
import '../../trading/model/news_event.dart';

class RuleContext {
  final UserMode          currentMode;
  final bool              meditationCompletedToday;
  final bool              isTradingSessionActive;
  final bool              isBettingSessionActive;
  final int               consecutiveLosses;
  final bool              isEmotionallyUnstable;
  final bool              isDeepWorkActive;
  final NewsEvent?        latestNewsEvent;
  final Set<RichFeature>  lockedFeatures;
  final DateTime          now;
  final bool              notificationsMuted;

  const RuleContext({
    required this.currentMode,
    required this.meditationCompletedToday,
    required this.isTradingSessionActive,
    required this.isBettingSessionActive,
    required this.consecutiveLosses,
    required this.isEmotionallyUnstable,
    required this.isDeepWorkActive,
    required this.latestNewsEvent,
    required this.lockedFeatures,
    required this.now,
    required this.notificationsMuted,
  });

  // ── Default starting context ──────────────────────────────────────────────

  factory RuleContext.initial() => RuleContext(
    currentMode:              UserMode.idle,
    meditationCompletedToday: false,
    isTradingSessionActive:   false,
    isBettingSessionActive:   false,
    consecutiveLosses:        0,
    isEmotionallyUnstable:    false,
    isDeepWorkActive:         false,
    latestNewsEvent:          null,
    lockedFeatures:           const {RichFeature.trading},
    now:                      DateTime.now(),
    notificationsMuted:       false,
  );

  // ── CopyWith ──────────────────────────────────────────────────────────────

  RuleContext copyWith({
    UserMode?         currentMode,
    bool?             meditationCompletedToday,
    bool?             isTradingSessionActive,
    bool?             isBettingSessionActive,
    int?              consecutiveLosses,
    bool?             isEmotionallyUnstable,
    bool?             isDeepWorkActive,
    NewsEvent?        latestNewsEvent,
    Set<RichFeature>? lockedFeatures,
    DateTime?         now,
    bool?             notificationsMuted,
  }) {
    return RuleContext(
      currentMode:              currentMode              ?? this.currentMode,
      meditationCompletedToday: meditationCompletedToday ?? this.meditationCompletedToday,
      isTradingSessionActive:   isTradingSessionActive   ?? this.isTradingSessionActive,
      isBettingSessionActive:   isBettingSessionActive   ?? this.isBettingSessionActive,
      consecutiveLosses:        consecutiveLosses        ?? this.consecutiveLosses,
      isEmotionallyUnstable:    isEmotionallyUnstable    ?? this.isEmotionallyUnstable,
      isDeepWorkActive:         isDeepWorkActive         ?? this.isDeepWorkActive,
      latestNewsEvent:          latestNewsEvent          ?? this.latestNewsEvent,
      lockedFeatures:           lockedFeatures           ?? this.lockedFeatures,
      now:                      now                      ?? this.now,
      notificationsMuted:       notificationsMuted       ?? this.notificationsMuted,
    );
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  bool isLocked(RichFeature feature) =>
      lockedFeatures.contains(feature);

  bool get tradingIsLocked =>
      lockedFeatures.contains(RichFeature.trading);

  bool get bettingIsLocked =>
      lockedFeatures.contains(RichFeature.betting);

  bool get hasHighImpactNews =>
      latestNewsEvent?.isHighImpact ?? false;
}
