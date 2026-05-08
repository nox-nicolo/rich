// lib/features/life/model/language_model.dart

// ── Supported Languages ───────────────────────────────────────────────────────

// Swahili is the native language — English replaces it as the first
// learnable language for Swahili-speaking users.
enum SupportedLanguage {
  english,
  mandarin,
  spanish,
  hindi,
  arabic,
  french,
  portuguese,
  russian,
  japanese,
  german,
}

extension SupportedLanguageX on SupportedLanguage {
  String get label {
    switch (this) {
      case SupportedLanguage.mandarin:   return 'Mandarin';
      case SupportedLanguage.spanish:    return 'Spanish';
      case SupportedLanguage.hindi:      return 'Hindi';
      case SupportedLanguage.arabic:     return 'Arabic';
      case SupportedLanguage.french:     return 'French';
      case SupportedLanguage.portuguese: return 'Portuguese';
      case SupportedLanguage.russian:    return 'Russian';
      case SupportedLanguage.japanese:   return 'Japanese';
      case SupportedLanguage.english:    return 'English';
      case SupportedLanguage.german:     return 'German';
    }
  }

  String get nativeName {
    switch (this) {
      case SupportedLanguage.mandarin:   return '普通话';
      case SupportedLanguage.spanish:    return 'Español';
      case SupportedLanguage.hindi:      return 'हिन्दी';
      case SupportedLanguage.arabic:     return 'العربية';
      case SupportedLanguage.french:     return 'Français';
      case SupportedLanguage.portuguese: return 'Português';
      case SupportedLanguage.russian:    return 'Русский';
      case SupportedLanguage.japanese:   return '日本語';
      case SupportedLanguage.english:    return 'English';
      case SupportedLanguage.german:     return 'Deutsch';
    }
  }

  String get flag {
    switch (this) {
      case SupportedLanguage.mandarin:   return '🇨🇳';
      case SupportedLanguage.spanish:    return '🇪🇸';
      case SupportedLanguage.hindi:      return '🇮🇳';
      case SupportedLanguage.arabic:     return '🇸🇦';
      case SupportedLanguage.french:     return '🇫🇷';
      case SupportedLanguage.portuguese: return '🇧🇷';
      case SupportedLanguage.russian:    return '🇷🇺';
      case SupportedLanguage.japanese:   return '🇯🇵';
      case SupportedLanguage.english:    return '🇬🇧';
      case SupportedLanguage.german:     return '🇩🇪';
    }
  }

  String get difficulty {
    switch (this) {
      case SupportedLanguage.english:
      case SupportedLanguage.spanish:
      case SupportedLanguage.portuguese:
      case SupportedLanguage.french:
      case SupportedLanguage.german:
        return 'Moderate';
      case SupportedLanguage.russian:
      case SupportedLanguage.hindi:
        return 'Challenging';
      case SupportedLanguage.arabic:
      case SupportedLanguage.mandarin:
      case SupportedLanguage.japanese:
        return 'Advanced';
    }
  }

  String get speakers {
    switch (this) {
      case SupportedLanguage.mandarin:   return '1.1B speakers';
      case SupportedLanguage.spanish:    return '560M speakers';
      case SupportedLanguage.hindi:      return '600M speakers';
      case SupportedLanguage.arabic:     return '370M speakers';
      case SupportedLanguage.french:     return '280M speakers';
      case SupportedLanguage.portuguese: return '260M speakers';
      case SupportedLanguage.russian:    return '260M speakers';
      case SupportedLanguage.japanese:   return '125M speakers';
      case SupportedLanguage.english:    return '1.5B speakers';
      case SupportedLanguage.german:     return '100M speakers';
    }
  }
}

// ── Learning Phases ───────────────────────────────────────────────────────────

enum LanguagePhase { foundations, survival, conversational, fluency, nativeLevel }

extension LanguagePhaseX on LanguagePhase {
  String get label {
    switch (this) {
      case LanguagePhase.foundations:   return 'Foundations';
      case LanguagePhase.survival:      return 'Survival';
      case LanguagePhase.conversational: return 'Conversational';
      case LanguagePhase.fluency:       return 'Fluency';
      case LanguagePhase.nativeLevel:   return 'Near-Native';
    }
  }

  String get range {
    switch (this) {
      case LanguagePhase.foundations:   return '0–20%';
      case LanguagePhase.survival:      return '20–40%';
      case LanguagePhase.conversational: return '40–60%';
      case LanguagePhase.fluency:       return '60–80%';
      case LanguagePhase.nativeLevel:   return '80–100%';
    }
  }

  int get minProgress {
    switch (this) {
      case LanguagePhase.foundations:   return 0;
      case LanguagePhase.survival:      return 20;
      case LanguagePhase.conversational: return 40;
      case LanguagePhase.fluency:       return 60;
      case LanguagePhase.nativeLevel:   return 80;
    }
  }
}

// ── Topic Model ───────────────────────────────────────────────────────────────

class TopicModel {
  final int order;          // 1–20
  final String id;
  final String title;
  final String description;
  final LanguagePhase phase;
  final bool isCompleted;
  final String? cachedLesson;  // AI-generated lesson, cached locally
  final DateTime? completedAt;

  const TopicModel({
    required this.order,
    required this.id,
    required this.title,
    required this.description,
    required this.phase,
    this.isCompleted = false,
    this.cachedLesson,
    this.completedAt,
  });

  bool get isUnlocked => true; // unlocking handled by index check in viewmodel

  TopicModel copyWith({
    bool? isCompleted,
    String? cachedLesson,
    DateTime? completedAt,
  }) =>
      TopicModel(
        order:        order,
        id:           id,
        title:        title,
        description:  description,
        phase:        phase,
        isCompleted:  isCompleted  ?? this.isCompleted,
        cachedLesson: cachedLesson ?? this.cachedLesson,
        completedAt:  completedAt  ?? this.completedAt,
      );

  Map<String, dynamic> toMap() => {
    'order':        order,
    'id':           id,
    'title':        title,
    'description':  description,
    'phase':        phase.index,
    'isCompleted':  isCompleted,
    'cachedLesson': cachedLesson,
    'completedAt':  completedAt?.toIso8601String(),
  };

  factory TopicModel.fromMap(Map<String, dynamic> m) => TopicModel(
    order:        m['order'] as int,
    id:           m['id'] as String,
    title:        m['title'] as String,
    description:  m['description'] as String,
    phase:        LanguagePhase.values[m['phase'] as int],
    isCompleted:  m['isCompleted'] as bool? ?? false,
    cachedLesson: m['cachedLesson'] as String?,
    completedAt:  m['completedAt'] != null
        ? DateTime.parse(m['completedAt'] as String)
        : null,
  );
}

// ── Vocabulary Item ───────────────────────────────────────────────────────────

class VocabularyItem {
  final String word;           // word in target language
  final String translation;    // in user's language
  final String phonetic;       // pronunciation guide
  final String example;        // sentence in target language
  final String exampleTranslation;
  final int masteryLevel;      // 0–5 (spaced repetition)
  final DateTime? nextReviewAt;

  const VocabularyItem({
    required this.word,
    required this.translation,
    required this.phonetic,
    required this.example,
    required this.exampleTranslation,
    this.masteryLevel = 0,
    this.nextReviewAt,
  });

  bool get isMastered => masteryLevel >= 5;

  bool get isDueForReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  /// Next review interval in days by mastery level:
  /// 0→1d, 1→3d, 2→7d, 3→14d, 4→30d, 5→mastered
  VocabularyItem markEasy() {
    final newLevel = (masteryLevel + 1).clamp(0, 5);
    final days = [1, 3, 7, 14, 30, 9999][newLevel];
    return copyWith(
      masteryLevel: newLevel,
      nextReviewAt: DateTime.now().add(Duration(days: days)),
    );
  }

  VocabularyItem markHard() {
    final newLevel = (masteryLevel - 1).clamp(0, 5);
    return copyWith(
      masteryLevel: newLevel,
      nextReviewAt: DateTime.now().add(const Duration(days: 1)),
    );
  }

  VocabularyItem copyWith({
    int? masteryLevel,
    DateTime? nextReviewAt,
  }) =>
      VocabularyItem(
        word:               word,
        translation:        translation,
        phonetic:           phonetic,
        example:            example,
        exampleTranslation: exampleTranslation,
        masteryLevel:       masteryLevel  ?? this.masteryLevel,
        nextReviewAt:       nextReviewAt  ?? this.nextReviewAt,
      );

  Map<String, dynamic> toMap() => {
    'word':               word,
    'translation':        translation,
    'phonetic':           phonetic,
    'example':            example,
    'exampleTranslation': exampleTranslation,
    'masteryLevel':       masteryLevel,
    'nextReviewAt':       nextReviewAt?.toIso8601String(),
  };

  factory VocabularyItem.fromMap(Map<String, dynamic> m) => VocabularyItem(
    word:               m['word'] as String,
    translation:        m['translation'] as String,
    phonetic:           m['phonetic'] as String,
    example:            m['example'] as String,
    exampleTranslation: m['exampleTranslation'] as String,
    masteryLevel:       m['masteryLevel'] as int? ?? 0,
    nextReviewAt:       m['nextReviewAt'] != null
        ? DateTime.parse(m['nextReviewAt'] as String)
        : null,
  );
}

// ── Language Progress ─────────────────────────────────────────────────────────

class LanguageProgress {
  final String id;
  final SupportedLanguage language;
  final List<TopicModel> topics;           // all 20 topics with completion state
  final List<VocabularyItem> vocabulary;   // mastery state per word
  final int totalXp;
  final DateTime startedAt;
  final DateTime? lastStudiedAt;
  final bool isActive;  // only one language active at a time

  const LanguageProgress({
    required this.id,
    required this.language,
    required this.topics,
    required this.vocabulary,
    this.totalXp = 0,
    required this.startedAt,
    this.lastStudiedAt,
    this.isActive = true,
  });

  // Progress 0–100 based on completed topics
  int get progressPercent =>
      topics.isEmpty ? 0 : ((completedTopics / topics.length) * 100).round();

  int get completedTopics =>
      topics.where((t) => t.isCompleted).length;

  LanguagePhase get currentPhase {
    final p = progressPercent;
    if (p >= 80) return LanguagePhase.nativeLevel;
    if (p >= 60) return LanguagePhase.fluency;
    if (p >= 40) return LanguagePhase.conversational;
    if (p >= 20) return LanguagePhase.survival;
    return LanguagePhase.foundations;
  }

  // First incomplete topic = current study target
  TopicModel? get currentTopic =>
      topics.where((t) => !t.isCompleted).isNotEmpty
          ? topics.firstWhere((t) => !t.isCompleted)
          : null;

  // A topic is unlocked if all previous topics are completed
  bool isTopicUnlocked(int topicIndex) => topicIndex == 0
      ? true
      : topics[topicIndex - 1].isCompleted;

  int get wordsLearned =>
      vocabulary.where((v) => v.masteryLevel >= 1).length;

  int get wordsMastered =>
      vocabulary.where((v) => v.isMastered).length;

  List<VocabularyItem> get dueForReview =>
      vocabulary.where((v) => v.isDueForReview && v.masteryLevel > 0).toList();

  LanguageProgress copyWith({
    List<TopicModel>? topics,
    List<VocabularyItem>? vocabulary,
    int? totalXp,
    DateTime? lastStudiedAt,
    bool? isActive,
  }) =>
      LanguageProgress(
        id:             id,
        language:       language,
        topics:         topics      ?? this.topics,
        vocabulary:     vocabulary  ?? this.vocabulary,
        totalXp:        totalXp     ?? this.totalXp,
        startedAt:      startedAt,
        lastStudiedAt:  lastStudiedAt ?? this.lastStudiedAt,
        isActive:       isActive    ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
    'id':             id,
    'language':       language.index,
    'topics':         topics.map((t) => t.toMap()).toList(),
    'vocabulary':     vocabulary.map((v) => v.toMap()).toList(),
    'totalXp':        totalXp,
    'startedAt':      startedAt.toIso8601String(),
    'lastStudiedAt':  lastStudiedAt?.toIso8601String(),
    'isActive':       isActive,
  };

  factory LanguageProgress.fromMap(Map<String, dynamic> m) => LanguageProgress(
    id:       m['id'] as String,
    language: SupportedLanguage.values[m['language'] as int],
    topics: (m['topics'] as List)
        .map((t) => TopicModel.fromMap(Map<String, dynamic>.from(t as Map)))
        .toList(),
    vocabulary: (m['vocabulary'] as List)
        .map((v) => VocabularyItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList(),
    totalXp:       m['totalXp'] as int? ?? 0,
    startedAt:     DateTime.parse(m['startedAt'] as String),
    lastStudiedAt: m['lastStudiedAt'] != null
        ? DateTime.parse(m['lastStudiedAt'] as String)
        : null,
    isActive: m['isActive'] as bool? ?? true,
  );
}
