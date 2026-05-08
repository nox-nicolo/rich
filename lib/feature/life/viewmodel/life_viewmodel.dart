// lib/features/life/viewmodel/life_viewmodel.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/habit_model.dart';
import '../model/workout_model.dart';
import '../model/health_log_model.dart';
import '../model/recovery_model.dart';
import '../model/language_model.dart';
import '../repository/life_repository.dart';
import '../repository/language_repository.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/services/ai_lesson_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

class LifeState {
  final List<HabitModel> habits;
  final List<WorkoutModel> todayWorkouts;
  final HealthLogModel? todayHealthLog;
  final RecoverySession? activeRecovery;
  final List<RecoverySession> recentRecoverySessions;

  // ── Language ──────────────────────────────────────────────────────────────
  final LanguageProgress? activeLanguage;
  final List<LanguageProgress> allLanguages;
  final bool isGeneratingLesson; // true while AI lesson content is fetching
  final String? lessonError; // shown if AI generation fails

  final String activeTab;
  final bool isLoading;

  const LifeState({
    required this.habits,
    required this.todayWorkouts,
    this.todayHealthLog,
    this.activeRecovery,
    required this.recentRecoverySessions,
    this.activeLanguage,
    required this.allLanguages,
    this.isGeneratingLesson = false,
    this.lessonError,
    required this.activeTab,
    required this.isLoading,
  });

  factory LifeState.initial() {
    return const LifeState(
      habits: [],
      todayWorkouts: [],
      recentRecoverySessions: [],
      allLanguages: [],
      activeTab: 'HABITS',
      isLoading: true,
    );
  }

  LifeState copyWith({
    List<HabitModel>? habits,
    List<WorkoutModel>? todayWorkouts,
    HealthLogModel? todayHealthLog,
    RecoverySession? activeRecovery,
    bool clearRecovery = false,
    List<RecoverySession>? recentRecoverySessions,
    LanguageProgress? activeLanguage,
    bool clearActiveLanguage = false,
    List<LanguageProgress>? allLanguages,
    bool? isGeneratingLesson,
    String? lessonError,
    bool clearLessonError = false,
    String? activeTab,
    bool? isLoading,
  }) {
    return LifeState(
      habits: habits ?? this.habits,
      todayWorkouts: todayWorkouts ?? this.todayWorkouts,
      todayHealthLog: todayHealthLog ?? this.todayHealthLog,
      activeRecovery: clearRecovery
          ? null
          : (activeRecovery ?? this.activeRecovery),
      recentRecoverySessions:
          recentRecoverySessions ?? this.recentRecoverySessions,
      activeLanguage: clearActiveLanguage
          ? null
          : (activeLanguage ?? this.activeLanguage),
      allLanguages: allLanguages ?? this.allLanguages,
      isGeneratingLesson: isGeneratingLesson ?? this.isGeneratingLesson,
      lessonError: clearLessonError ? null : (lessonError ?? this.lessonError),
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  int get completedHabitsToday => habits.where((h) => h.completedToday).length;

  bool get hasWorkedOutToday => todayWorkouts.isNotEmpty;

  bool get isInRecovery => activeRecovery != null;

  bool get hasActiveLanguage => activeLanguage != null;

  List<RecoverySession> get todayRecoverySessions {
    final now = DateTime.now();
    return recentRecoverySessions
        .where(
          (s) =>
              s.startedAt.year == now.year &&
              s.startedAt.month == now.month &&
              s.startedAt.day == now.day,
        )
        .toList();
  }

  int get todayRecoveryMinutes {
    int total = 0;
    for (final s in todayRecoverySessions) {
      if (s.endedAt == null) continue;
      total += s.endedAt!.difference(s.startedAt).inMinutes;
    }
    return total;
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LifeViewModel extends StateNotifier<LifeState> {
  final LifeRepository _repo;
  final LanguageRepository _langRepo;

  LifeViewModel(this._repo, this._langRepo) : super(LifeState.initial()) {
    _load();
  }

  void _load() {
    final habits = _repo.loadHabits();
    final workouts = _repo.loadTodayWorkouts();
    final healthLog = _repo.loadTodayHealthLog();
    final recovery = _repo.loadActiveRecoverySession();
    final recent = _repo.loadAllRecoverySessions()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final allLangs = _langRepo.loadAllProgress();
    final activeLang = allLangs.where((l) => l.isActive).isNotEmpty
        ? allLangs.firstWhere((l) => l.isActive)
        : null;

    state = state.copyWith(
      habits: habits,
      todayWorkouts: workouts,
      todayHealthLog: healthLog,
      activeRecovery: recovery,
      recentRecoverySessions: recent.take(20).toList(),
      activeLanguage: activeLang,
      allLanguages: allLangs,
      isLoading: false,
    );
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  // ── Habits ────────────────────────────────────────────────────────────────

  Future<void> addHabit({
    required String name,
    String? description,
    required HabitCategory category,
    HabitFrequency frequency = HabitFrequency.daily,
  }) async {
    final habit = HabitModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      category: category,
      frequency: frequency,
      currentStreak: 0,
      longestStreak: 0,
      totalCompletions: 0,
      createdAt: DateTime.now(),
    );
    await _repo.saveHabit(habit);
    state = state.copyWith(habits: [...state.habits, habit]);
  }

  Future<void> completeHabit(String id) async {
    final prior = state.habits.firstWhere((h) => h.id == id);
    final alreadyDone = prior.completedToday;
    final updated = state.habits.map((h) {
      if (h.id != id) return h;
      return h.complete();
    }).toList();
    final habit = updated.firstWhere((h) => h.id == id);
    await _repo.saveHabit(habit);
    state = state.copyWith(habits: updated);
    if (!alreadyDone) {
      await TrackingService.record(TrackingFeature.life, {
        'habitsCompleted': 1,
      });
      VibrationService.strongPulse();
    }
  }

  Future<void> deleteHabit(String id) async {
    await _repo.deleteHabit(id);
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != id).toList(),
    );
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  Future<void> logWorkout({
    required WorkoutType type,
    required WorkoutIntensity intensity,
    required int durationMinutes,
    String? notes,
    int? steps,
  }) async {
    final workout = WorkoutModel(
      id: const Uuid().v4(),
      type: type,
      intensity: intensity,
      durationMinutes: durationMinutes,
      completedAt: DateTime.now(),
      notes: notes,
      steps: steps,
    );
    await _repo.saveWorkout(workout);
    state = state.copyWith(todayWorkouts: [...state.todayWorkouts, workout]);
    await TrackingService.record(TrackingFeature.life, {
      'workouts': 1,
      'workoutMinutes': workout.durationMinutes,
    });
    VibrationService.strongPulse();

    final dashRepo = DashboardRepository();
    final progress = dashRepo.loadRoutineProgress();
    if (progress['Workout'] == false) {
      progress['Workout'] = true;
      await dashRepo.saveRoutineProgress(progress);
    }
    await _autoDeriveEnergy();
  }

  // ── Health Log ────────────────────────────────────────────────────────────

  Future<void> updateHealthLog({
    int? sleepHours,
    int? waterGlasses,
    int? steps,
    String? meals,
  }) async {
    final existing = state.todayHealthLog;
    final log = existing != null
        ? existing.copyWith(
            sleepHours: sleepHours,
            waterGlasses: waterGlasses,
            steps: steps,
            meals: meals,
          )
        : HealthLogModel(
            id: const Uuid().v4(),
            loggedAt: DateTime.now(),
            sleepHours: sleepHours,
            waterGlasses: waterGlasses,
            steps: steps,
            energyLevel: EnergyLevel.moderate,
            meals: meals,
          );
    await _repo.saveHealthLog(log);
    state = state.copyWith(todayHealthLog: log);
    await _autoDeriveEnergy();
  }

  Future<void> _autoDeriveEnergy() async {
    final log = state.todayHealthLog;
    if (log == null) return;
    int score = 0;
    final sleep = log.sleepHours;
    if (sleep != null) {
      if (sleep >= 8) {
        score += 2;
      } else if (sleep >= 7) {
        score += 1;
      }
    }
    final water = log.waterGlasses;
    if (water != null) {
      if (water >= 8) {
        score += 2;
      } else if (water >= 5) {
        score += 1;
      }
    }
    final steps = log.steps;
    if (steps != null) {
      if (steps >= 8000) {
        score += 2;
      } else if (steps >= 4000) {
        score += 1;
      }
    }
    if (state.todayWorkouts.isNotEmpty) {
      score += 1;
    }

    final EnergyLevel derived;
    if (score >= 6) {
      derived = EnergyLevel.peak;
    } else if (score >= 4) {
      derived = EnergyLevel.high;
    } else if (score >= 2) {
      derived = EnergyLevel.moderate;
    } else {
      derived = EnergyLevel.low;
    }

    if (derived == log.energyLevel) return;
    final updated = log.copyWith(energyLevel: derived);
    await _repo.saveHealthLog(updated);
    state = state.copyWith(todayHealthLog: updated);
    await TrackingService.setKeys(TrackingFeature.life, {
      'energyLevel': derived.index,
    });
  }

  // ── Recovery ──────────────────────────────────────────────────────────────

  Future<void> startRecovery(RecoveryMode mode) async {
    final session = RecoverySession(
      id: const Uuid().v4(),
      mode: mode,
      startedAt: DateTime.now(),
      durationMinutes: 60,
      active: true,
    );
    await _repo.saveRecoverySession(session);
    state = state.copyWith(
      activeRecovery: session,
      recentRecoverySessions: [
        session,
        ...state.recentRecoverySessions,
      ].take(20).toList(),
    );
  }

  Future<void> endRecovery({String? note}) async {
    final session = state.activeRecovery;
    if (session == null) return;
    final ended = session.copyWith(
      endedAt: DateTime.now(),
      active: false,
      note: note,
    );
    await _repo.saveRecoverySession(ended);
    final updated = state.recentRecoverySessions
        .map((s) => s.id == ended.id ? ended : s)
        .toList();
    state = state.copyWith(
      clearRecovery: true,
      recentRecoverySessions: updated,
    );
    final seconds = ended.endedAt!.difference(ended.startedAt).inSeconds;
    await TrackingService.record(TrackingFeature.life, {
      'recoverySessions': 1,
      'recoverySeconds': seconds,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LANGUAGE LEARNING
  // ══════════════════════════════════════════════════════════════════════════

  /// Start learning a new language.
  /// Deactivates any currently active language first (one at a time rule).
  Future<void> enrollLanguage(SupportedLanguage language) async {
    // Deactivate current active language
    if (state.activeLanguage != null) {
      final paused = state.activeLanguage!.copyWith(isActive: false);
      await _langRepo.saveProgress(paused);
    }

    // Check if user already has progress in this language
    final existing = state.allLanguages
        .where((l) => l.language == language)
        .toList();

    LanguageProgress progress;
    if (existing.isNotEmpty) {
      // Resume — reactivate existing progress
      progress = existing.first.copyWith(isActive: true);
    } else {
      // Fresh start
      progress = _langRepo.createFreshProgress(
        id: const Uuid().v4(),
        language: language,
      );
    }

    await _langRepo.saveProgress(progress);

    final updatedAll = [
      ...state.allLanguages.where((l) => l.language != language),
      progress,
    ];

    state = state.copyWith(activeLanguage: progress, allLanguages: updatedAll);
  }

  /// Pause the active language (user can resume later).
  Future<void> pauseLanguage() async {
    final lang = state.activeLanguage;
    if (lang == null) return;
    final paused = lang.copyWith(isActive: false);
    await _langRepo.saveProgress(paused);
    final updatedAll = state.allLanguages
        .map((l) => l.id == paused.id ? paused : l)
        .toList();
    state = state.copyWith(clearActiveLanguage: true, allLanguages: updatedAll);
  }

  /// Open a topic — fetch an AI lesson if not cached yet.
  /// Returns the lesson text (cached or freshly generated).
  Future<String> loadLesson(String topicId, {bool forceRefresh = false}) async {
    final lang = state.activeLanguage;
    if (lang == null) return _offlineLesson(topicId);

    final topicIndex = lang.topics.indexWhere((t) => t.id == topicId);
    if (topicIndex < 0) return _offlineLesson(topicId);

    final topic = lang.topics[topicIndex];

    // ── Already cached — return immediately ──────────────────────────────
    if (!forceRefresh && topic.cachedLesson != null) return topic.cachedLesson!;

    // ── Generate via free AI text API ─────────────────────────────────────
    state = state.copyWith(isGeneratingLesson: true, clearLessonError: true);

    try {
      final ai = AiLessonService.instance;
      final lesson = await ai
          .generateLesson(
            languageName: lang.language.label,
            topicTitle: topic.title,
            topicDescription: topic.description,
            currentProgressPercent: lang.progressPercent,
          )
          .timeout(const Duration(seconds: 95), onTimeout: () => null);

      if (lesson != null) {
        // Cache the lesson so we do not call the API again for this topic.
        final updatedTopics = List<TopicModel>.from(lang.topics);
        updatedTopics[topicIndex] = topic.copyWith(cachedLesson: lesson);
        final updatedLang = lang.copyWith(topics: updatedTopics);
        await _langRepo.saveProgress(updatedLang);

        final updatedAll = state.allLanguages
            .map((l) => l.id == updatedLang.id ? updatedLang : l)
            .toList();

        state = state.copyWith(
          activeLanguage: updatedLang,
          allLanguages: updatedAll,
          isGeneratingLesson: false,
        );
        return lesson;
      }

      // AI failed or timed out — show offline fallback.
      state = state.copyWith(
        isGeneratingLesson: false,
        lessonError: _aiLessonFailureMessage(ai.lastError),
      );
      return _offlineLesson(topicId);
    } catch (_) {
      state = state.copyWith(
        isGeneratingLesson: false,
        lessonError: 'Could not load the AI lesson. Showing offline content.',
      );
      return _offlineLesson(topicId);
    }
  }

  void stopLessonGeneration(String message) {
    state = state.copyWith(isGeneratingLesson: false, lessonError: message);
  }

  String _aiLessonFailureMessage(String? error) {
    final detail = error?.replaceFirst('Exception: ', '').trim();
    if (detail == null || detail.isEmpty) {
      return 'The AI lesson service did not respond. Showing offline content for now.';
    }
    return 'The AI lesson service did not respond: $detail';
  }

  /// Mark a topic as completed. Unlocks the next topic.
  /// Awards XP and records tracking.
  Future<void> completeTopic(String topicId) async {
    final lang = state.activeLanguage;
    if (lang == null) return;

    final topicIndex = lang.topics.indexWhere((t) => t.id == topicId);
    if (topicIndex < 0) return;

    final topic = lang.topics[topicIndex];
    if (topic.isCompleted) return;

    // Generate vocabulary for the completed topic and add to bank
    final newVocab = await _fetchTopicVocabulary(
      languageName: lang.language.label,
      topicTitle: topic.title,
      existing: lang.vocabulary,
    );

    final updatedTopics = List<TopicModel>.from(lang.topics);
    updatedTopics[topicIndex] = topic.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    const xpPerTopic = 50;
    final updatedLang = lang.copyWith(
      topics: updatedTopics,
      vocabulary: newVocab,
      totalXp: lang.totalXp + xpPerTopic,
      lastStudiedAt: DateTime.now(),
    );

    await _langRepo.saveProgress(updatedLang);
    final updatedAll = state.allLanguages
        .map((l) => l.id == updatedLang.id ? updatedLang : l)
        .toList();

    state = state.copyWith(
      activeLanguage: updatedLang,
      allLanguages: updatedAll,
    );

    VibrationService.strongPulse();

    await TrackingService.record(TrackingFeature.life, {
      'languageTopicsCompleted': 1,
      'languageXpEarned': xpPerTopic,
    });
  }

  /// Update vocabulary mastery after a flashcard session.
  Future<void> updateVocabularyMastery(List<VocabularyItem> updated) async {
    final lang = state.activeLanguage;
    if (lang == null) return;
    final updatedLang = lang.copyWith(vocabulary: updated);
    await _langRepo.saveProgress(updatedLang);
    final updatedAll = state.allLanguages
        .map((l) => l.id == updatedLang.id ? updatedLang : l)
        .toList();
    state = state.copyWith(
      activeLanguage: updatedLang,
      allLanguages: updatedAll,
    );
  }

  void clearLessonError() => state = state.copyWith(clearLessonError: true);

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<VocabularyItem>> _fetchTopicVocabulary({
    required String languageName,
    required String topicTitle,
    required List<VocabularyItem> existing,
  }) async {
    try {
      final raw = await AiLessonService.instance.generateVocabularyForTopic(
        languageName: languageName,
        topicTitle: topicTitle,
      );
      if (raw == null) return existing;

      // Strip possible markdown code fences
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> parsed = jsonDecode(clean) as List;
      final newWords = parsed
          .map(
            (v) => VocabularyItem.fromMap(Map<String, dynamic>.from(v as Map)),
          )
          .toList();

      // Merge — skip words already in the bank (by word string)
      final existingWords = existing.map((v) => v.word).toSet();
      final merged = [
        ...existing,
        ...newWords.where((v) => !existingWords.contains(v.word)),
      ];
      return merged;
    } catch (_) {
      return existing;
    }
  }

  String _offlineLesson(String topicId) {
    // Fallback content shown when AI generation is unavailable.
    final lang = state.activeLanguage;
    final topic = lang?.topics.where((t) => t.id == topicId).isNotEmpty == true
        ? lang!.topics.firstWhere((t) => t.id == topicId)
        : null;
    return '''
## ${topic?.title ?? 'Lesson'}

${topic?.description ?? 'Study this topic carefully.'}

## OFFLINE MODE
The AI tutor is currently unavailable. Here's what to do:

1. **Review vocabulary** - tap the Flashcards tab and study the words for this topic.
2. **Practice pronunciation** - tap any word to hear it spoken aloud.
3. **Come back** - when the AI service and internet are available, this lesson will load the full AI-generated content.

Your progress is saved. Retry the AI lesson before completing this topic.
''';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final lifeRepositoryProvider = Provider<LifeRepository>(
  (_) => LifeRepository(),
);

final languageRepositoryProvider = Provider<LanguageRepository>(
  (_) => LanguageRepository(),
);

final lifeViewModelProvider = StateNotifierProvider<LifeViewModel, LifeState>(
  (ref) => LifeViewModel(
    ref.read(lifeRepositoryProvider),
    ref.read(languageRepositoryProvider),
  ),
);
