// lib/features/rules_engine/model/rule_action.dart

import 'rich_feature.dart';
import 'user_mode.dart';

enum RuleActionType {
  lockFeature,
  unlockFeature,
  muteNotifications,
  unmuteNotifications,
  showWarning,
  requireConfirmation,
  triggerCooldown,
  sendReminder,
  setUserMode,
  enforceReview,
}

class RuleAction {
  final RuleActionType type;
  final RichFeature?   targetFeature;
  final String?        message;
  final Duration?      cooldownDuration;
  final UserMode?      targetMode;

  const RuleAction({
    required this.type,
    this.targetFeature,
    this.message,
    this.cooldownDuration,
    this.targetMode,
  });

  bool get isLockAction =>
      type == RuleActionType.lockFeature;

  bool get isUnlockAction =>
      type == RuleActionType.unlockFeature;

  bool get isMuteAction =>
      type == RuleActionType.muteNotifications;

  bool get isCooldownAction =>
      type == RuleActionType.triggerCooldown;
}
