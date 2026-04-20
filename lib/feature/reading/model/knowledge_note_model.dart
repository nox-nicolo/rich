// lib/features/reading/model/knowledge_note_model.dart

enum KnowledgeNoteType {
  summary,
  application,
  connection,
  lesson,
  question,
}

extension KnowledgeNoteTypeX on KnowledgeNoteType {
  String get label {
    switch (this) {
      case KnowledgeNoteType.summary:
        return 'Summary';
      case KnowledgeNoteType.application:
        return 'Application';
      case KnowledgeNoteType.connection:
        return 'Connection';
      case KnowledgeNoteType.lesson:
        return 'Lesson';
      case KnowledgeNoteType.question:
        return 'Question';
    }
  }

  String get prompt {
    switch (this) {
      case KnowledgeNoteType.summary:
        return 'What did I learn?';
      case KnowledgeNoteType.application:
        return 'How can I apply this today?';
      case KnowledgeNoteType.connection:
        return 'How does this connect to what I already know?';
      case KnowledgeNoteType.lesson:
        return 'What is the core lesson here?';
      case KnowledgeNoteType.question:
        return 'What question does this raise?';
    }
  }
}

class KnowledgeNoteModel {
  final String id;
  final String? bookId;
  final String? bookTitle;
  final String content;
  final KnowledgeNoteType type;
  final List<String> tags;
  final DateTime createdAt;
  final bool pinned;

  /// User's own expanded reflection on the idea — "what do I think about
  /// this?", "how does it apply to me?". Kept separate from [content] so
  /// the original quoted idea stays untouched while the personal view grows.
  final String? reflection;

  final DateTime? reflectionUpdatedAt;

  const KnowledgeNoteModel({
    required this.id,
    this.bookId,
    this.bookTitle,
    required this.content,
    required this.type,
    this.tags = const [],
    required this.createdAt,
    this.pinned = false,
    this.reflection,
    this.reflectionUpdatedAt,
  });

  KnowledgeNoteModel copyWith({
    String? content,
    List<String>? tags,
    bool? pinned,
    String? reflection,
    DateTime? reflectionUpdatedAt,
  }) {
    return KnowledgeNoteModel(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      content: content ?? this.content,
      type: type,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      pinned: pinned ?? this.pinned,
      reflection: reflection ?? this.reflection,
      reflectionUpdatedAt:
          reflectionUpdatedAt ?? this.reflectionUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'content': content,
      'type': type.index,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'pinned': pinned,
      'reflection': reflection,
      'reflectionUpdatedAt': reflectionUpdatedAt?.toIso8601String(),
    };
  }

  factory KnowledgeNoteModel.fromMap(Map<String, dynamic> m) {
    return KnowledgeNoteModel(
      id: m['id'] as String,
      bookId: m['bookId'] as String?,
      bookTitle: m['bookTitle'] as String?,
      content: m['content'] as String,
      type: KnowledgeNoteType.values[m['type'] as int],
      tags: List<String>.from(m['tags'] as List? ?? []),
      createdAt: DateTime.parse(m['createdAt'] as String),
      pinned: m['pinned'] as bool? ?? false,
      reflection: m['reflection'] as String?,
      reflectionUpdatedAt: m['reflectionUpdatedAt'] != null
          ? DateTime.parse(m['reflectionUpdatedAt'] as String)
          : null,
    );
  }
}
