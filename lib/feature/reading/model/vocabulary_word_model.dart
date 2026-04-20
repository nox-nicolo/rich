// lib/feature/reading/model/vocabulary_word_model.dart
//
// Rich vocab entry — stores everything a mini-dictionary needs so the VOCAB
// tab can render a detailed card without hitting the network every time:
//   - phonetic transcription
//   - definitions grouped by part of speech (noun/verb/adj/adv/...)
//   - synonyms / antonyms
//   - example sentences
//   - a free-form personal note ("my take on this word")

class VocabularyWord {
  final String id;
  final String word;

  /// Short one-line meaning — used as the collapsed card summary. Usually
  /// the first definition of the first part of speech.
  final String meaning;

  /// IPA / spelling like /ɪɡˈzæmpəl/. May be null if the dictionary lookup
  /// failed or the API didn't return one.
  final String? phonetic;

  /// Definitions grouped by part of speech:
  ///   { 'noun': ['a representative form', ...],
  ///     'verb': ['be illustrative of', ...] }
  final Map<String, List<String>> meaningsByPos;

  /// First example sentence — kept separate from [examples] for backwards
  /// compatibility with older records.
  final String? exampleSentence;

  /// Every example sentence the dictionary returned.
  final List<String> examples;

  /// Related words — merged across all parts of speech.
  final List<String> synonyms;
  final List<String> antonyms;

  /// User's personal note on the word ("why I saved this", mnemonic, etc.)
  final String? personalNote;

  final String? sourceBookTitle;
  final String? sourceBookId;
  final int? sourcePage;
  final DateTime savedAt;
  final int reviewCount;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    this.meaningsByPos = const {},
    this.exampleSentence,
    this.examples = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    this.personalNote,
    this.sourceBookTitle,
    this.sourceBookId,
    this.sourcePage,
    required this.savedAt,
    this.reviewCount = 0,
  });

  /// True if the record has any enriched data beyond the bare summary —
  /// used to decide whether to show the "expand" chevron in the UI.
  bool get hasRichData =>
      meaningsByPos.isNotEmpty ||
      examples.isNotEmpty ||
      synonyms.isNotEmpty ||
      antonyms.isNotEmpty ||
      (phonetic != null && phonetic!.isNotEmpty);

  VocabularyWord copyWith({
    String? meaning,
    String? phonetic,
    Map<String, List<String>>? meaningsByPos,
    String? exampleSentence,
    List<String>? examples,
    List<String>? synonyms,
    List<String>? antonyms,
    String? personalNote,
    int? reviewCount,
  }) =>
      VocabularyWord(
        id: id,
        word: word,
        meaning: meaning ?? this.meaning,
        phonetic: phonetic ?? this.phonetic,
        meaningsByPos: meaningsByPos ?? this.meaningsByPos,
        exampleSentence: exampleSentence ?? this.exampleSentence,
        examples: examples ?? this.examples,
        synonyms: synonyms ?? this.synonyms,
        antonyms: antonyms ?? this.antonyms,
        personalNote: personalNote ?? this.personalNote,
        sourceBookTitle: sourceBookTitle,
        sourceBookId: sourceBookId,
        sourcePage: sourcePage,
        savedAt: savedAt,
        reviewCount: reviewCount ?? this.reviewCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'phonetic': phonetic,
        // Hive stores plain Maps/Lists — convert the typed value manually.
        'meaningsByPos':
            meaningsByPos.map((k, v) => MapEntry(k, List<String>.from(v))),
        'exampleSentence': exampleSentence,
        'examples': examples,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'personalNote': personalNote,
        'sourceBookTitle': sourceBookTitle,
        'sourceBookId': sourceBookId,
        'sourcePage': sourcePage,
        'savedAt': savedAt.toIso8601String(),
        'reviewCount': reviewCount,
      };

  factory VocabularyWord.fromMap(Map<String, dynamic> m) {
    // meaningsByPos is a nested Map<String, List<String>> — Hive gives back
    // Map<dynamic, dynamic> / List<dynamic> so we have to coerce each level.
    final rawMbp = m['meaningsByPos'];
    final meaningsByPos = <String, List<String>>{};
    if (rawMbp is Map) {
      rawMbp.forEach((k, v) {
        if (v is List) {
          meaningsByPos[k.toString()] =
              v.map((e) => e.toString()).toList();
        }
      });
    }

    List<String> asStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    return VocabularyWord(
      id: m['id'] as String,
      word: m['word'] as String,
      meaning: m['meaning'] as String,
      phonetic: m['phonetic'] as String?,
      meaningsByPos: meaningsByPos,
      exampleSentence: m['exampleSentence'] as String?,
      examples: asStringList(m['examples']),
      synonyms: asStringList(m['synonyms']),
      antonyms: asStringList(m['antonyms']),
      personalNote: m['personalNote'] as String?,
      sourceBookTitle: m['sourceBookTitle'] as String?,
      sourceBookId: m['sourceBookId'] as String?,
      sourcePage: m['sourcePage'] as int?,
      savedAt: DateTime.parse(m['savedAt'] as String),
      reviewCount: m['reviewCount'] as int? ?? 0,
    );
  }
}
