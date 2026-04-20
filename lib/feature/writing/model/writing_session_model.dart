// lib/feature/writing/model/writing_session_model.dart

enum WritingCategory {
  journaling,
  creative,
  planning,
  ideaDump,
  learningNotes,
  emotional,
  strategy,
  other,
}

extension WritingCategoryX on WritingCategory {
  String get label {
    switch (this) {
      case WritingCategory.journaling:    return 'Journaling';
      case WritingCategory.creative:      return 'Creative';
      case WritingCategory.planning:      return 'Planning';
      case WritingCategory.ideaDump:      return 'Idea Dump';
      case WritingCategory.learningNotes: return 'Learning Notes';
      case WritingCategory.emotional:     return 'Emotional';
      case WritingCategory.strategy:      return 'Strategy';
      case WritingCategory.other:         return 'Other';
    }
  }
}

class WritingSession {
  final String id;
  final String? title;
  final String content;
  final int wordCount;
  final int durationSeconds;
  final WritingCategory category;
  final int moodBefore; // 1–5
  final int moodAfter;  // 1–5
  final String? purpose;
  final String? reflection;
  final DateTime createdAt;

  /// Last time this session's content/metadata was edited. Only set when
  /// the user reopens a previously-saved session and updates it — allows
  /// the log to show "edited Xm ago" distinct from original creation time.
  final DateTime? updatedAt;

  const WritingSession({
    required this.id,
    this.title,
    required this.content,
    required this.wordCount,
    required this.durationSeconds,
    required this.category,
    required this.moodBefore,
    required this.moodAfter,
    this.purpose,
    this.reflection,
    required this.createdAt,
    this.updatedAt,
  });

  /// Build a new session from this one with the fields the user touched
  /// overwritten. Used by [WritingViewModel.updateSession] so continuing a
  /// session preserves id / createdAt and accumulates duration rather than
  /// overwriting it.
  WritingSession copyWith({
    String? title,
    String? content,
    int? wordCount,
    int? durationSeconds,
    WritingCategory? category,
    int? moodBefore,
    int? moodAfter,
    String? purpose,
    String? reflection,
    DateTime? updatedAt,
  }) {
    return WritingSession(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      category: category ?? this.category,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      purpose: purpose ?? this.purpose,
      reflection: reflection ?? this.reflection,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':              id,
    'title':           title,
    'content':         content,
    'wordCount':       wordCount,
    'durationSeconds': durationSeconds,
    'category':        category.index,
    'moodBefore':      moodBefore,
    'moodAfter':       moodAfter,
    'purpose':         purpose,
    'reflection':      reflection,
    'createdAt':       createdAt.toIso8601String(),
    'updatedAt':       updatedAt?.toIso8601String(),
  };

  factory WritingSession.fromMap(Map<String, dynamic> m) => WritingSession(
    id:              m['id'] as String,
    title:           m['title'] as String?,
    content:         m['content'] as String,
    wordCount:       m['wordCount'] as int,
    durationSeconds: m['durationSeconds'] as int,
    category:        WritingCategory.values[m['category'] as int],
    moodBefore:      m['moodBefore'] as int,
    moodAfter:       m['moodAfter'] as int,
    purpose:         m['purpose'] as String?,
    reflection:      m['reflection'] as String?,
    createdAt:       DateTime.parse(m['createdAt'] as String),
    updatedAt:       m['updatedAt'] != null
        ? DateTime.parse(m['updatedAt'] as String)
        : null,
  );

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
}
