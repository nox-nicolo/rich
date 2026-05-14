// lib/feature/mentor/model/mentor_models.dart

enum MentorRole { user, assistant }

extension MentorRoleX on MentorRole {
  String get key => name;

  static MentorRole fromString(String value) {
    return MentorRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => MentorRole.assistant,
    );
  }
}

class MentorMessage {
  final String id;
  final MentorRole role;
  final String text;
  final DateTime createdAt;

  const MentorMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.key,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MentorMessage.fromMap(Map<String, dynamic> map) {
    return MentorMessage(
      id: map['id'] as String? ?? '',
      role: MentorRoleX.fromString(map['role'] as String? ?? 'assistant'),
      text: map['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MentorContextSnapshot {
  final String coreGoals;
  final String currentStreaks;
  final String savingsProgress;
  final String missedActivities;
  final String activeGoals;
  final String patterns;

  const MentorContextSnapshot({
    required this.coreGoals,
    required this.currentStreaks,
    required this.savingsProgress,
    required this.missedActivities,
    required this.activeGoals,
    required this.patterns,
  });

  String toPromptContext() {
    return '''
CORE GOALS:
$coreGoals

CURRENT STREAKS:
$currentStreaks

SAVINGS PROGRESS:
$savingsProgress

MISSED ACTIVITIES:
$missedActivities

ACTIVE GOALS:
$activeGoals

14-DAY PATTERNS:
$patterns
''';
  }
}
