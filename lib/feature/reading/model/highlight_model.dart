// lib/features/reading/model/highlight_model.dart

/// Three annotation types — each has a distinct color and behavior:
///   noted  → white/neutral  — plain highlight, saved to HIGHLIGHTS tab
///   vocab  → blue           — word/phrase, auto-added to VOCAB tab
///   idea   → green          — insight/idea, auto-added to VAULT tab
enum HighlightType { noted, vocab, idea }

extension HighlightTypeX on HighlightType {
  String get label {
    switch (this) {
      case HighlightType.noted:
        return 'NOTED';
      case HighlightType.vocab:
        return 'VOCAB';
      case HighlightType.idea:
        return 'IDEA';
    }
  }

  String get description {
    switch (this) {
      case HighlightType.noted:
        return 'Saved to Highlights';
      case HighlightType.vocab:
        return 'Added to Vocabulary';
      case HighlightType.idea:
        return 'Added to Vault';
    }
  }
}

class HighlightModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String content;
  final HighlightType type;
  final int? pageNumber;
  final DateTime savedAt;
  final String? personalNote;
  final bool reviewed;

  const HighlightModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.content,
    required this.type,
    this.pageNumber,
    required this.savedAt,
    this.personalNote,
    this.reviewed = false,
  });

  HighlightModel copyWith({
    String? personalNote,
    bool? reviewed,
  }) {
    return HighlightModel(
      id:           id,
      bookId:       bookId,
      bookTitle:    bookTitle,
      content:      content,
      type:         type,
      pageNumber:   pageNumber,
      savedAt:      savedAt,
      personalNote: personalNote ?? this.personalNote,
      reviewed:     reviewed    ?? this.reviewed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':           id,
      'bookId':       bookId,
      'bookTitle':    bookTitle,
      'content':      content,
      'type':         type.index,
      'pageNumber':   pageNumber,
      'savedAt':      savedAt.toIso8601String(),
      'personalNote': personalNote,
      'reviewed':     reviewed,
    };
  }

  factory HighlightModel.fromMap(Map<String, dynamic> m) {
    final rawType = m['type'] as int? ?? 0;
    return HighlightModel(
      id:           m['id'] as String,
      bookId:       m['bookId'] as String,
      bookTitle:    m['bookTitle'] as String,
      content:      m['content'] as String,
      type:         rawType < HighlightType.values.length
                      ? HighlightType.values[rawType]
                      : HighlightType.noted,
      pageNumber:   m['pageNumber'] as int?,
      savedAt:      DateTime.parse(m['savedAt'] as String),
      personalNote: m['personalNote'] as String?,
      reviewed:     m['reviewed'] as bool? ?? false,
    );
  }
}
