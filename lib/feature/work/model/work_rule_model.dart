// lib/features/work/model/work_rule_model.dart

enum WorkRuleCategory {
  communication,
  focus,
  decisionMaking,
  timeManagement,
  boundaries,
}

extension WorkRuleCategoryX on WorkRuleCategory {
  String get label {
    switch (this) {
      case WorkRuleCategory.communication:
        return 'Communication';
      case WorkRuleCategory.focus:
        return 'Focus';
      case WorkRuleCategory.decisionMaking:
        return 'Decision Making';
      case WorkRuleCategory.timeManagement:
        return 'Time Management';
      case WorkRuleCategory.boundaries:
        return 'Boundaries';
    }
  }
}

class WorkRuleModel {
  final String id;
  final String title;
  final String description;
  final WorkRuleCategory category;
  final bool active;

  const WorkRuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.active = true,
  });

  WorkRuleModel copyWith({bool? active}) {
    return WorkRuleModel(
      id: id,
      title: title,
      description: description,
      category: category,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.index,
      'active': active,
    };
  }

  factory WorkRuleModel.fromMap(Map<String, dynamic> m) {
    return WorkRuleModel(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      category: WorkRuleCategory.values[m['category'] as int],
      active: m['active'] as bool? ?? true,
    );
  }
}

final defaultWorkRules = [
  const WorkRuleModel(
    id: 'WR001',
    title: 'Respond, do not react',
    description:
        'Take a breath before replying to any message that triggers emotion.',
    category: WorkRuleCategory.communication,
  ),
  const WorkRuleModel(
    id: 'WR002',
    title: 'No context switching during deep work',
    description:
        'Once a deep work block starts, no email, no Slack, no interruptions.',
    category: WorkRuleCategory.focus,
  ),
  const WorkRuleModel(
    id: 'WR003',
    title: 'Decide with data, not pressure',
    description:
        'If a decision feels rushed or emotionally loaded, delay it.',
    category: WorkRuleCategory.decisionMaking,
  ),
  const WorkRuleModel(
    id: 'WR004',
    title: 'Three priorities per day maximum',
    description:
        'Choose three. Finish them. Everything else is secondary.',
    category: WorkRuleCategory.timeManagement,
  ),
  const WorkRuleModel(
    id: 'WR005',
    title: 'Protect the shutdown ritual',
    description:
        'End each workday with a deliberate shutdown. Close loops, note next steps.',
    category: WorkRuleCategory.boundaries,
  ),
];
