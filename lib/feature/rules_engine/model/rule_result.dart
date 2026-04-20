// lib/features/rules_engine/model/rule_result.dart

import 'rule_action.dart';

class RuleResult {
  final String          ruleId;
  final bool            triggered;
  final List<RuleAction> actions;
  final String?         reason;

  const RuleResult({
    required this.ruleId,
    required this.triggered,
    required this.actions,
    this.reason,
  });

  // ── Factory constructors ──────────────────────────────────────────────────

  factory RuleResult.notTriggered(String ruleId) => RuleResult(
    ruleId:    ruleId,
    triggered: false,
    actions:   const [],
  );

  factory RuleResult.triggered({
    required String ruleId,
    required List<RuleAction> actions,
    String? reason,
  }) => RuleResult(
    ruleId:    ruleId,
    triggered: true,
    actions:   actions,
    reason:    reason,
  );

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get hasLockAction =>
      actions.any((a) => a.isLockAction);

  bool get hasMuteAction =>
      actions.any((a) => a.isMuteAction);

  bool get hasCooldownAction =>
      actions.any((a) => a.isCooldownAction);

  List<RuleAction> get lockActions =>
      actions.where((a) => a.isLockAction).toList();

  List<RuleAction> get unlockActions =>
      actions.where((a) => a.isUnlockAction).toList();
}
