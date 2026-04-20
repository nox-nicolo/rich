// lib/features/work/model/meeting_model.dart

enum MeetingStatus { upcoming, inProgress, completed, cancelled }

extension MeetingStatusX on MeetingStatus {
  String get label {
    switch (this) {
      case MeetingStatus.upcoming:
        return 'Upcoming';
      case MeetingStatus.inProgress:
        return 'In Progress';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class MeetingModel {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final MeetingStatus status;
  final List<String> attendees;
  final String? agenda;
  final String? prepNotes;
  final String? outcome;
  final List<String> actionItems;
  final DateTime createdAt;
  final DateTime? actualStart;
  final DateTime? actualEnd;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.attendees = const [],
    this.agenda,
    this.prepNotes,
    this.outcome,
    this.actionItems = const [],
    required this.createdAt,
    this.actualStart,
    this.actualEnd,
  });

  MeetingModel copyWith({
    String? title,
    DateTime? scheduledAt,
    int? durationMinutes,
    MeetingStatus? status,
    List<String>? attendees,
    String? agenda,
    String? prepNotes,
    String? outcome,
    List<String>? actionItems,
    DateTime? actualStart,
    DateTime? actualEnd,
  }) {
    return MeetingModel(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      attendees: attendees ?? this.attendees,
      agenda: agenda ?? this.agenda,
      prepNotes: prepNotes ?? this.prepNotes,
      outcome: outcome ?? this.outcome,
      actionItems: actionItems ?? this.actionItems,
      createdAt: createdAt,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
    );
  }

  bool get isUpcoming => status == MeetingStatus.upcoming;
  bool get isInProgress => status == MeetingStatus.inProgress;
  bool get isCompleted => status == MeetingStatus.completed;

  bool get isSoon {
    final diff = scheduledAt.difference(DateTime.now());
    return diff.inMinutes <= 30 && diff.inMinutes >= 0;
  }

  bool get hasPrepNotes =>
      prepNotes != null && prepNotes!.trim().isNotEmpty;

  bool get hasAgenda => agenda != null && agenda!.trim().isNotEmpty;

  bool get hasMaterials => hasAgenda || hasPrepNotes;

  // Notification ids — namespaced from each other and from task ids
  // by XOR-ing with distinct constants. Always positive (31-bit).
  int get _hash => id.hashCode & 0x7fffffff;
  int get startNotificationId => _hash ^ 0x4d544731; // "MTG1"
  int get reminderNotificationId => _hash ^ 0x4d544732; // "MTG2"

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.index,
      'attendees': attendees,
      'agenda': agenda,
      'prepNotes': prepNotes,
      'outcome': outcome,
      'actionItems': actionItems,
      'createdAt': createdAt.toIso8601String(),
      'actualStart': actualStart?.toIso8601String(),
      'actualEnd': actualEnd?.toIso8601String(),
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> m) {
    DateTime? parse(String key) {
      final v = m[key];
      return v == null ? null : DateTime.parse(v as String);
    }

    return MeetingModel(
      id: m['id'] as String,
      title: m['title'] as String,
      scheduledAt: DateTime.parse(m['scheduledAt'] as String),
      durationMinutes: m['durationMinutes'] as int,
      status: MeetingStatus.values[m['status'] as int],
      attendees: List<String>.from(m['attendees'] as List? ?? []),
      agenda: m['agenda'] as String?,
      prepNotes: m['prepNotes'] as String?,
      outcome: m['outcome'] as String?,
      actionItems: List<String>.from(m['actionItems'] as List? ?? []),
      createdAt: DateTime.parse(m['createdAt'] as String),
      actualStart: parse('actualStart'),
      actualEnd: parse('actualEnd'),
    );
  }
}
