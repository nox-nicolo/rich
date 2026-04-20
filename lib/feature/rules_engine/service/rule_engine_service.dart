// lib/features/rules_engine/service/rule_engine_service.dart

import '../model/rich_rule.dart';
import '../model/rich_feature.dart';
import '../model/rule_action.dart';
import '../model/rule_context.dart';
import '../model/rule_result.dart';
import '../model/user_mode.dart';
import 'rules_definitions.dart';

class RuleEngineService {
  final List<RichRule> _rules;

  RuleEngineService()
      : _rules = List<RichRule>.from(RulesDefinitions.allRules)
          ..sort((a, b) => a.priority.compareTo(b.priority));

  // ── Evaluate ──────────────────────────────────────────────────────────────
  // Runs all active rules against the current context.
  // Returns only triggered results.

  List<RuleResult> evaluate(RuleContext context) {
    return _rules
        .map((rule) => rule.evaluate(context))
        .where((result) => result.triggered)
        .toList();
  }

  // ── Apply ─────────────────────────────────────────────────────────────────
  // Mutates context based on triggered rule results.
  // Returns a new context with all actions applied.

  RuleContext applyResults(
      RuleContext context, List<RuleResult> results) {
    var updated = context;
    final allActions =
        results.expand((r) => r.actions).toList();

    for (final action in allActions) {
      updated = _applyAction(updated, action);
    }
    return updated;
  }

  RuleContext _applyAction(
      RuleContext context, RuleAction action) {
    switch (action.type) {

      case RuleActionType.lockFeature:
        if (action.targetFeature == null) return context;
        return context.copyWith(
          lockedFeatures: {
            ...context.lockedFeatures,
            action.targetFeature!
          },
        );

      case RuleActionType.unlockFeature:
        if (action.targetFeature == null) return context;
        final updated =
            Set<RichFeature>.from(context.lockedFeatures)
              ..remove(action.targetFeature!);
        return context.copyWith(lockedFeatures: updated);

      case RuleActionType.muteNotifications:
        return context.copyWith(notificationsMuted: true);

      case RuleActionType.unmuteNotifications:
        return context.copyWith(notificationsMuted: false);

      case RuleActionType.setUserMode:
        if (action.targetMode == null) return context;
        return context.copyWith(
            currentMode: action.targetMode!);

      // Side-effect actions handled by the ViewModel layer:
      // showWarning, requireConfirmation, triggerCooldown,
      // sendReminder, enforceReview
      default:
        return context;
    }
  }

  // ── Evaluate + Apply in one step ─────────────────────────────────────────

  RuleContext evaluateAndApply(RuleContext context) {
    final results = evaluate(context);
    return applyResults(context, results);
  }

  // ── Lock Helpers ──────────────────────────────────────────────────────────

  bool isLocked(RichFeature feature, RuleContext context) =>
      context.lockedFeatures.contains(feature);

  /// Human-readable explanation of why a feature is locked.
  String lockReason(RichFeature feature, RuleContext context) {
    switch (feature) {
      case RichFeature.trading:
        if (!context.meditationCompletedToday) {
          return 'Complete your Meditation session to unlock Trading.';
        }
        return 'Trading is currently restricted.';

      case RichFeature.betting:
        if (context.isTradingSessionActive) {
          return 'Close your Trading session before accessing Betting.';
        }
        if (context.currentMode == UserMode.trading) {
          return 'Exit Trading mode before accessing Betting.';
        }
        if (context.consecutiveLosses >= 3) {
          return 'Loss streak protection active. '
              '${context.consecutiveLosses} consecutive losses.';
        }
        if (context.isEmotionallyUnstable) {
          return 'Emotional reset required before accessing Betting.';
        }
        return 'Betting is currently restricted.';

      default:
        return '${feature.label} is currently locked.';
    }
  }

  /// What the user must do to unlock a feature.
  String unlockInstruction(
      RichFeature feature, RuleContext context) {
    switch (feature) {
      case RichFeature.trading:
        return 'Complete a Meditation session (Prayer, Breathing, or Stillness).';

      case RichFeature.betting:
        if (context.isTradingSessionActive) {
          return 'End your active Trading session first.';
        }
        if (context.consecutiveLosses >= 3) {
          return 'Wait for the cooldown period to expire.';
        }
        if (context.isEmotionallyUnstable) {
          return 'Complete an emotional Reset session in Meditation.';
        }
        return 'Resolve the active restriction first.';

      default:
        return 'Resolve the active restriction to unlock ${feature.label}.';
    }
  }
}
