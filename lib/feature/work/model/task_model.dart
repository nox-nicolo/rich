// lib/features/work/model/task_model.dart

// Ordered from highest to lowest so index matches intensity
enum TaskPriority { critical, high, medium, low }

enum TaskStatus { pending, inProgress, completed, blocked }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.critical:
        return 'CRITICAL';
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.low:
        return 'LOW';
    }
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;

  /// Immutable — the date the task was first created. Never changes.
  final DateTime createdAt;

  /// The "active day" for this task. Null on first creation (falls back to
  /// createdAt). Set to today whenever a carry-over moves the task forward so
  /// createdAt is preserved as the true origin date.
  final DateTime? scheduledFor;

  /// Number of times this task was carried forward to the next day.
  final int carriedOverCount;

  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final String? blockedReason;
  final List<String> tags;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.scheduledFor,
    this.carriedOverCount = 0,
    this.completedAt,
    this.dueDate,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.blockedReason,
    this.tags = const [],
  });

  TaskModel copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? scheduledFor,
    int? carriedOverCount,
    DateTime? completedAt,
    DateTime? dueDate,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    String? blockedReason,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      carriedOverCount: carriedOverCount ?? this.carriedOverCount,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      blockedReason: blockedReason ?? this.blockedReason,
      tags: tags ?? this.tags,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isBlocked => status == TaskStatus.blocked;
  bool get isHighPriority =>
      priority == TaskPriority.high || priority == TaskPriority.critical;

  bool get hasSchedule => scheduledStart != null && scheduledEnd != null;

  /// The date this task is "active for". Used for day-filtering and carry-over
  /// anchoring. Prefers scheduledFor (set on recycle), then scheduledStart,
  /// then createdAt.
  DateTime get activeDate {
    if (scheduledFor != null) return scheduledFor!;
    if (scheduledStart != null) return scheduledStart!;
    return createdAt;
  }

  int? get plannedMinutes =>
      hasSchedule ? scheduledEnd!.difference(scheduledStart!).inMinutes : null;

  int? get actualMinutes {
    if (actualStart == null || completedAt == null) return null;
    return completedAt!.difference(actualStart!).inMinutes;
  }

  int? get overrunMinutes {
    final p = plannedMinutes;
    final a = actualMinutes;
    if (p == null || a == null) return null;
    return a - p;
  }

  // Stable notification ids derived from task id (positive 31-bit ints).
  // Task alarms use several ids so a scheduled task can keep nudging until
  // the user opens it, then the viewmodel cancels the remaining pings.
  int get notificationId => id.hashCode & 0x7fffffff;
  int get reminderNotificationId => (notificationId + 1) & 0x7fffffff;
  int get startNotificationId => (notificationId + 2) & 0x7fffffff;
  int get endNotificationId => (notificationId + 3) & 0x7fffffff;
  int ringNotificationId(int index) =>
      (notificationId + 100 + index) & 0x7fffffff;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'carriedOverCount': carriedOverCount,
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'scheduledStart': scheduledStart?.toIso8601String(),
      'scheduledEnd': scheduledEnd?.toIso8601String(),
      'actualStart': actualStart?.toIso8601String(),
      'blockedReason': blockedReason,
      'tags': tags,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> m) {
    DateTime? parse(String key) {
      final v = m[key];
      return v == null ? null : DateTime.parse(v as String);
    }

    return TaskModel(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      priority: TaskPriority.values[m['priority'] as int],
      status: TaskStatus.values[m['status'] as int],
      createdAt: DateTime.parse(m['createdAt'] as String),
      scheduledFor: parse('scheduledFor'),
      carriedOverCount: (m['carriedOverCount'] as int?) ?? 0,
      completedAt: parse('completedAt'),
      dueDate: parse('dueDate'),
      scheduledStart: parse('scheduledStart'),
      scheduledEnd: parse('scheduledEnd'),
      actualStart: parse('actualStart'),
      blockedReason: m['blockedReason'] as String?,
      tags: List<String>.from(m['tags'] as List? ?? []),
    );
  }
}
