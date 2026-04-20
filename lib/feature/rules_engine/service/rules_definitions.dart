// lib/features/rules_engine/service/rules_definitions.dart

import '../model/rich_rule.dart';
import '../model/rule_action.dart';
import '../model/rich_feature.dart';
import '../model/user_mode.dart';
import '../../../core/constants/app_constants.dart';

class RulesDefinitions {
  RulesDefinitions._();

  static List<RichRule> get allRules => [
    meditationGate,
    tradingLocksBetting,
    highImpactNewsWhileWorking,
    consecutiveLossesCooldown,
    emotionalStateBlocksBetting,
    deepWorkMutesNotifications,
    tradingModeBlocksBetting,
  ];

  // ── R001 — Meditation Gate ────────────────────────────────────────────────
  // Trading stays locked until today's meditation is done.

  static final meditationGate = RichRule(
    id:          'R001',
    name:        'Meditation Gate',
    description: 'Complete Meditation to unlock Trading.',
    priority:    1,
    condition:   (ctx) => !ctx.meditationCompletedToday,
    actionsBuilder: (_) => [
      const RuleAction(
        type:          RuleActionType.lockFeature,
        targetFeature: RichFeature.trading,
        message:       'Complete your Meditation session to unlock Trading.',
      ),
    ],
  );

  // ── R002 — Trading Locks Betting ──────────────────────────────────────────
  // An active trading session immediately locks Betting.

  static final tradingLocksBetting = RichRule(
    id:          'R002',
    name:        'Trading Locks Betting',
    description: 'Betting is locked while Trading session is active.',
    priority:    2,
    condition:   (ctx) => ctx.isTradingSessionActive,
    actionsBuilder: (_) => [
      const RuleAction(
        type:          RuleActionType.lockFeature,
        targetFeature: RichFeature.betting,
        message:       'Close your Trading session before accessing Betting.',
      ),
    ],
  );

  // ── R003 — High Impact News + Working = Mute ──────────────────────────────
  // High-impact news during work mode silences all non-critical notifications.

  static final highImpactNewsWhileWorking = RichRule(
    id:          'R003',
    name:        'High Impact News — Working Mode',
    description: 'Notifications muted. High-impact news detected during work.',
    priority:    3,
    condition:   (ctx) =>
        ctx.currentMode == UserMode.working &&
        (ctx.latestNewsEvent?.isHighImpact ?? false),
    actionsBuilder: (_) => [
      const RuleAction(
        type:    RuleActionType.muteNotifications,
        message: 'High-impact news detected. All notifications muted during work.',
      ),
    ],
  );

  // ── R004 — Consecutive Losses Cooldown ────────────────────────────────────
  // 3+ consecutive betting losses triggers a cooldown and lock.

  static final consecutiveLossesCooldown = RichRule(
    id:          'R004',
    name:        'Loss Streak Protection',
    description: 'Betting locked after consecutive losses.',
    priority:    2,
    condition:   (ctx) =>
        ctx.consecutiveLosses >= AppConstants.maxConsecutiveLosses,
    actionsBuilder: (ctx) => [
      RuleAction(
        type:             RuleActionType.triggerCooldown,
        targetFeature:    RichFeature.betting,
        cooldownDuration: Duration(
            hours: AppConstants.bettingCooldownHours),
        message:
            '${ctx.consecutiveLosses} consecutive losses. '
            '${AppConstants.bettingCooldownHours}h cooldown active.',
      ),
      const RuleAction(
        type:          RuleActionType.lockFeature,
        targetFeature: RichFeature.betting,
        message:       'Betting locked. Loss streak protection active.',
      ),
    ],
  );

  // ── R005 — Emotional State Blocks Betting ────────────────────────────────
  // Unstable emotional state from mood check locks Betting.

  static final emotionalStateBlocksBetting = RichRule(
    id:          'R005',
    name:        'Emotional State Guard',
    description: 'Betting locked due to low emotional stability.',
    priority:    2,
    condition:   (ctx) => ctx.isEmotionallyUnstable,
    actionsBuilder: (_) => [
      const RuleAction(
        type:          RuleActionType.lockFeature,
        targetFeature: RichFeature.betting,
        message:
            'Emotional reset required before accessing Betting.',
      ),
    ],
  );

  // ── R006 — Deep Work Mutes Notifications ─────────────────────────────────
  // Active deep work block suppresses non-essential notifications.

  static final deepWorkMutesNotifications = RichRule(
    id:          'R006',
    name:        'Deep Work Focus Guard',
    description: 'Notifications muted during deep work.',
    priority:    4,
    condition:   (ctx) => ctx.isDeepWorkActive,
    actionsBuilder: (_) => [
      const RuleAction(
        type:    RuleActionType.muteNotifications,
        message: 'Deep work active. Disturbances muted.',
      ),
    ],
  );

  // ── R007 — Trading Mode Restricts Betting ────────────────────────────────
  // Being in Trading mode locks Betting regardless of session state.

  static final tradingModeBlocksBetting = RichRule(
    id:          'R007',
    name:        'Trading Mode Betting Restriction',
    description: 'Exit Trading mode before accessing Betting.',
    priority:    2,
    condition:   (ctx) => ctx.currentMode == UserMode.trading,
    actionsBuilder: (_) => [
      const RuleAction(
        type:          RuleActionType.lockFeature,
        targetFeature: RichFeature.betting,
        message:       'Exit Trading mode before accessing Betting.',
      ),
    ],
  );
}
