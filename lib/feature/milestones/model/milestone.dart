// lib/feature/milestones/model/milestone.dart
//
// A long-cycle goal — distinct from a daily/weekly habit. Each milestone
// lives in one of two buckets:
//   - sixMonth: "thing I will do in six months"
//   - yearly:   "thing I will do this year"
//
// When a six-month milestone hits its target date still active, it is
// auto-rolled into the yearly bucket with the target extended by another
// six months. This is handled in the viewmodel on every load — the model
// itself is a plain value object.

import 'dart:convert';

enum Horizon { sixMonth, yearly }

extension HorizonX on Horizon {
  String get label {
    switch (this) {
      case Horizon.sixMonth:
        return '6-Month';
      case Horizon.yearly:
        return 'Yearly';
    }
  }

  int get months {
    switch (this) {
      case Horizon.sixMonth:
        return 6;
      case Horizon.yearly:
        return 12;
    }
  }

  String get key => name;

  static Horizon fromString(String value) {
    return Horizon.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Horizon.sixMonth,
    );
  }
}

enum MilestoneStatus { active, done, dropped }

extension MilestoneStatusX on MilestoneStatus {
  String get label {
    switch (this) {
      case MilestoneStatus.active:
        return 'Active';
      case MilestoneStatus.done:
        return 'Done';
      case MilestoneStatus.dropped:
        return 'Dropped';
    }
  }

  String get key => name;

  static MilestoneStatus fromString(String value) {
    return MilestoneStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MilestoneStatus.active,
    );
  }
}

class Milestone {
  final String id;
  final String title;
  final String? note;
  final List<String> processSteps;
  final Horizon horizon;
  final MilestoneStatus status;
  final double progress; // 0..1
  final DateTime createdAt;
  final DateTime targetDate;
  final DateTime updatedAt;

  const Milestone({
    required this.id,
    required this.title,
    this.note,
    this.processSteps = const [],
    required this.horizon,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.targetDate,
    required this.updatedAt,
  });

  Milestone copyWith({
    String? id,
    String? title,
    String? note,
    bool clearNote = false,
    List<String>? processSteps,
    Horizon? horizon,
    MilestoneStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? targetDate,
    DateTime? updatedAt,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      processSteps: processSteps ?? this.processSteps,
      horizon: horizon ?? this.horizon,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == MilestoneStatus.active;
  bool get isOverdue => isActive && DateTime.now().isAfter(targetDate);

  // Progress we'd expect to see right now based on time elapsed since
  // creation. Used to flag an "at risk" milestone whose actual progress is
  // lagging its schedule.
  double get expectedProgress {
    final total = targetDate.difference(createdAt).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool get isAtRisk =>
      isActive && progress < expectedProgress - 0.15 && !isOverdue;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'note': note,
    'processSteps': processSteps,
    'horizon': horizon.name,
    'status': status.name,
    'progress': progress,
    'createdAt': createdAt.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Milestone.fromMap(Map<String, dynamic> m) {
    return Milestone(
      id: m['id'] ?? '',
      title: m['title'] ?? '',
      note: m['note'] as String?,
      processSteps: (m['processSteps'] as List? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      horizon: HorizonX.fromString(m['horizon'] ?? 'sixMonth'),
      status: MilestoneStatusX.fromString(m['status'] ?? 'active'),
      progress: (m['progress'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      targetDate: DateTime.tryParse(m['targetDate'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Milestone.fromJson(String source) =>
      Milestone.fromMap(jsonDecode(source));
}

// Dart's stdlib doesn't have clean month arithmetic. This clamps the day
// to the last valid day of the destination month so "Jan 31 + 1 month"
// becomes Feb 28/29 rather than overflowing into March.
DateTime addMonths(DateTime d, int months) {
  final total = d.month + months;
  final year = d.year + ((total - 1) ~/ 12);
  final month = ((total - 1) % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = d.day < lastDay ? d.day : lastDay;
  return DateTime(year, month, day, d.hour, d.minute, d.second);
}

/// Calendar-aligned default target for a milestone horizon:
///   - sixMonth → end of the current half (Jun 30 in H1, Dec 31 in H2)
///   - yearly   → Dec 31 of the current year (never crosses into next year)
DateTime defaultTargetFor(Horizon h, {DateTime? from}) {
  final now = from ?? DateTime.now();
  switch (h) {
    case Horizon.sixMonth:
      return now.month <= 6
          ? DateTime(now.year, 6, 30, 23, 59, 59)
          : DateTime(now.year, 12, 31, 23, 59, 59);
    case Horizon.yearly:
      return DateTime(now.year, 12, 31, 23, 59, 59);
  }
}

/// Last selectable date for the picker, given a horizon. Same as the default
/// target so users can't pick a date that escapes the calendar period.
DateTime maxTargetFor(Horizon h, {DateTime? from}) =>
    defaultTargetFor(h, from: from);

/// Human label for the period a milestone in [h] currently belongs to.
String periodLabelFor(Horizon h, {DateTime? from}) {
  final now = from ?? DateTime.now();
  switch (h) {
    case Horizon.sixMonth:
      return now.month <= 6
          ? 'H1 ${now.year} · JAN–JUN'
          : 'H2 ${now.year} · JUL–DEC';
    case Horizon.yearly:
      return '${now.year}';
  }
}
