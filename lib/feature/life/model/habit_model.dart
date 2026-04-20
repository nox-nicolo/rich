// lib/features/life/model/habit_model.dart

enum HabitCategory {
  health,
  fitness,
  mindset,
  learning,
  relationships,
  discipline,
}

extension HabitCategoryX on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.mindset:
        return 'Mindset';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.relationships:
        return 'Relationships';
      case HabitCategory.discipline:
        return 'Discipline';
    }
  }
}

enum HabitFrequency { daily, weekly }

extension HabitFrequencyX on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
    }
  }
}

class HabitModel {
  final String id;
  final String name;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final bool active;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.frequency,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    this.lastCompletedDate,
    required this.createdAt,
    this.active = true,
  });

  bool get completedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  bool get streakAtRisk {
    if (lastCompletedDate == null) return false;
    final diff = DateTime.now().difference(lastCompletedDate!);
    return diff.inHours >= 20 && !completedToday;
  }

  HabitModel complete() {
    final now = DateTime.now();
    final newStreak = currentStreak + 1;
    return copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > longestStreak ? newStreak : longestStreak,
      totalCompletions: totalCompletions + 1,
      lastCompletedDate: now,
    );
  }

  HabitModel copyWith({
    String? name,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    DateTime? lastCompletedDate,
    bool? active,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'frequency': frequency.index,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompletions': totalCompletions,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'active': active,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> m) {
    return HabitModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      category: HabitCategory.values[m['category'] as int],
      frequency: HabitFrequency.values[m['frequency'] as int],
      currentStreak: m['currentStreak'] as int,
      longestStreak: m['longestStreak'] as int,
      totalCompletions: m['totalCompletions'] as int,
      lastCompletedDate: m['lastCompletedDate'] != null
          ? DateTime.parse(m['lastCompletedDate'] as String)
          : null,
      createdAt: DateTime.parse(m['createdAt'] as String),
      active: m['active'] as bool? ?? true,
    );
  }
}
