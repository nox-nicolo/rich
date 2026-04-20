// lib/features/betting/model/betting_rule_model.dart

enum BettingRuleCategory {
  stake,
  entry,
  exit,
  emotional,
  bankroll,
}

extension BettingRuleCategoryX on BettingRuleCategory {
  String get label {
    switch (this) {
      case BettingRuleCategory.stake:
        return 'Stake';
      case BettingRuleCategory.entry:
        return 'Entry';
      case BettingRuleCategory.exit:
        return 'Exit';
      case BettingRuleCategory.emotional:
        return 'Emotional';
      case BettingRuleCategory.bankroll:
        return 'Bankroll';
    }
  }
}

class BettingRuleModel {
  final String id;
  final String title;
  final String description;
  final BettingRuleCategory category;
  final bool active;
  final bool isHardRule;

  const BettingRuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.active = true,
    this.isHardRule = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.index,
      'active': active,
      'isHardRule': isHardRule,
    };
  }

  factory BettingRuleModel.fromMap(Map<String, dynamic> m) {
    return BettingRuleModel(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      category: BettingRuleCategory.values[m['category'] as int],
      active: m['active'] as bool? ?? true,
      isHardRule: m['isHardRule'] as bool? ?? false,
    );
  }
}

final defaultBettingRules = [
  const BettingRuleModel(
    id: 'BR001',
    title: 'Never chase losses',
    description:
        'A losing bet is information. Chasing is destruction. Stop and reset.',
    category: BettingRuleCategory.emotional,
    isHardRule: true,
  ),
  const BettingRuleModel(
    id: 'BR002',
    title: 'Max stake is 2% of bankroll',
    description:
        'No single bet should risk more than 2% of your total bankroll.',
    category: BettingRuleCategory.stake,
    isHardRule: true,
  ),
  const BettingRuleModel(
    id: 'BR003',
    title: 'No emotional slips',
    description:
        'If the bet is driven by feeling not logic, it does not qualify.',
    category: BettingRuleCategory.emotional,
    isHardRule: true,
  ),
  const BettingRuleModel(
    id: 'BR004',
    title: 'Daily stop limit is 5% of bankroll',
    description:
        'When the daily stop is hit, betting ends. No exceptions.',
    category: BettingRuleCategory.bankroll,
    isHardRule: true,
  ),
  const BettingRuleModel(
    id: 'BR005',
    title: 'Only bet when value is clear',
    description:
        'If you cannot articulate the edge, there is no bet to make.',
    category: BettingRuleCategory.entry,
  ),
  const BettingRuleModel(
    id: 'BR006',
    title: 'Review every slip before confirming',
    description:
        'Read your bet back. Does it follow your rules? Only then confirm.',
    category: BettingRuleCategory.entry,
  ),
];
