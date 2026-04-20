// lib/features/rules_engine/model/rich_rule.dart

import 'rule_action.dart';
import 'rule_context.dart';
import 'rule_result.dart';

// ── Type aliases ──────────────────────────────────────────────────────────────

typedef RuleCondition      = bool Function(RuleContext context);
typedef RuleActionsBuilder = List<RuleAction> Function(RuleContext context);

// ── RichRule ──────────────────────────────────────────────────────────────────

class RichRule {
  final String             id;
  final String             name;
  final String             description;
  final RuleCondition      condition;
  final RuleActionsBuilder actionsBuilder;

  /// Lower number = higher priority.
  /// Priority 1 rules evaluate first.
  final int priority;

  /// Whether this rule is currently active.
  /// Inactive rules are skipped during evaluation.
  final bool active;

  const RichRule({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.actionsBuilder,
    this.priority = 10,
    this.active   = true,
  });

  // ── Evaluate ──────────────────────────────────────────────────────────────

  RuleResult evaluate(RuleContext context) {
    if (!active) return RuleResult.notTriggered(id);

    final triggered = condition(context);

    if (!triggered) return RuleResult.notTriggered(id);

    return RuleResult.triggered(
      ruleId:  id,
      actions: actionsBuilder(context),
      reason:  description,
    );
  }

  // ── CopyWith (for toggling active state) ──────────────────────────────────

  RichRule copyWith({bool? active}) => RichRule(
    id:             id,
    name:           name,
    description:    description,
    condition:      condition,
    actionsBuilder: actionsBuilder,
    priority:       priority,
    active:         active ?? this.active,
  );
}
