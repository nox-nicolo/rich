// lib/feature/writing/viewmodel/writing_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/writing_session_model.dart';
import '../repository/writing_repository.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class WritingState {
  final List<WritingSession> allSessions;
  final int todayWordCount;
  final int weeklyWordCount;
  final int monthlyWordCount;
  final int streak;
  final String activeTab; // 'WRITE' | 'LOG' | 'STATS'
  final bool isLoading;

  /// If non-null, the WRITE tab is continuing an existing saved session
  /// rather than starting a fresh one. The write UI pre-fills itself from
  /// the matching [WritingSession] and saving performs an update-in-place
  /// (same id, accumulated duration).
  final String? editingSessionId;

  const WritingState({
    required this.allSessions,
    required this.todayWordCount,
    required this.weeklyWordCount,
    required this.monthlyWordCount,
    required this.streak,
    required this.activeTab,
    required this.isLoading,
    this.editingSessionId,
  });

  factory WritingState.initial() => const WritingState(
    allSessions:     [],
    todayWordCount:  0,
    weeklyWordCount: 0,
    monthlyWordCount: 0,
    streak:          0,
    activeTab:       'WRITE',
    isLoading:       true,
  );

  /// The session currently being edited, or null for a fresh entry.
  WritingSession? get editingSession {
    if (editingSessionId == null) return null;
    for (final s in allSessions) {
      if (s.id == editingSessionId) return s;
    }
    return null;
  }

  List<WritingSession> get todaySessions =>
      allSessions.where((s) => s.isToday).toList();

  int get totalSessions => allSessions.length;

  int get bestDayWordCount {
    if (allSessions.isEmpty) return 0;
    final byDay = <String, int>{};
    for (final s in allSessions) {
      final key = '${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}';
      byDay[key] = (byDay[key] ?? 0) + s.wordCount;
    }
    return byDay.values.fold(0, (a, b) => a > b ? a : b);
  }

  double get avgWordsPerSession {
    if (allSessions.isEmpty) return 0;
    final total = allSessions.fold(0, (sum, s) => sum + s.wordCount);
    return total / allSessions.length;
  }

  /// [clearEditing] lets callers explicitly null out [editingSessionId],
  /// which the usual `x ?? this.x` idiom can't express for nullable fields.
  WritingState copyWith({
    List<WritingSession>? allSessions,
    int? todayWordCount,
    int? weeklyWordCount,
    int? monthlyWordCount,
    int? streak,
    String? activeTab,
    bool? isLoading,
    String? editingSessionId,
    bool clearEditing = false,
  }) => WritingState(
    allSessions:      allSessions     ?? this.allSessions,
    todayWordCount:   todayWordCount  ?? this.todayWordCount,
    weeklyWordCount:  weeklyWordCount ?? this.weeklyWordCount,
    monthlyWordCount: monthlyWordCount ?? this.monthlyWordCount,
    streak:           streak          ?? this.streak,
    activeTab:        activeTab       ?? this.activeTab,
    isLoading:        isLoading       ?? this.isLoading,
    editingSessionId: clearEditing
        ? null
        : (editingSessionId ?? this.editingSessionId),
  );
}


// ── ViewModel ─────────────────────────────────────────────────────────────────

class WritingViewModel extends StateNotifier<WritingState> {
  final WritingRepository _repo;

  // Active session tracking
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  WritingViewModel(this._repo) : super(WritingState.initial()) {
    _load();
  }

  void _load() {
    final sessions = _repo.loadAllSessions();
    final todayWC  = sessions
        .where((s) => s.isToday)
        .fold(0, (sum, s) => sum + s.wordCount);

    state = state.copyWith(
      allSessions:      sessions,
      todayWordCount:   todayWC,
      weeklyWordCount:  _repo.weeklyWordCount(),
      monthlyWordCount: _repo.monthlyWordCount(),
      streak:           _repo.loadStreak(),
      isLoading:        false,
    );
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) {
    // Leaving the WRITE tab without explicitly saving should NOT cancel an
    // in-progress edit — the user might just be peeking at stats. The edit
    // is only cancelled via [cancelEditing] or after [updateSession].
    state = state.copyWith(activeTab: tab);
  }

  // ── Continue-writing flow ─────────────────────────────────────────────────

  /// Reopen an existing session for continued writing. The WRITE tab will
  /// pre-fill from the session and the save action becomes an in-place
  /// update. Also jumps the user to the WRITE tab so the transition is
  /// one tap instead of two.
  void startEditingSession(String id) {
    _sessionTimer?.cancel();
    _elapsedSeconds = 0;
    state = state.copyWith(editingSessionId: id, activeTab: 'WRITE');
    beginWriting();
  }

  /// Abandon an in-progress edit and return to a blank write screen. Does
  /// NOT touch the underlying session — the user's prior content is
  /// preserved because nothing was written through [updateSession].
  void cancelEditing() {
    _sessionTimer?.cancel();
    _elapsedSeconds = 0;
    state = state.copyWith(clearEditing: true);
    beginWriting();
  }

  // ── Session timer ─────────────────────────────────────────────────────────

  void beginWriting() {
    _elapsedSeconds = 0;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
    });
  }

  // ── Save session ──────────────────────────────────────────────────────────

  Future<void> saveSession({
    required String content,
    required WritingCategory category,
    required int moodBefore,
    required int moodAfter,
    String? title,
    String? purpose,
    String? reflection,
  }) async {
    _sessionTimer?.cancel();

    final wc = _countWords(content);
    if (wc == 0) return;

    final session = WritingSession(
      id:              const Uuid().v4(),
      title:           title,
      content:         content,
      wordCount:       wc,
      durationSeconds: _elapsedSeconds,
      category:        category,
      moodBefore:      moodBefore,
      moodAfter:       moodAfter,
      purpose:         purpose,
      reflection:      reflection,
      createdAt:       DateTime.now(),
    );

    await _repo.saveSession(session);
    await _repo.updateStreak();

    await TrackingService.record(TrackingFeature.writing, {
      'entries':      1,
      'words':        session.wordCount,
      'totalSeconds': session.durationSeconds,
    });

    // Notify: writing session saved
    await NotificationService.instance.show(
      id:      60,
      title:   'Writing Session Saved',
      body:    '${session.wordCount} words logged.',
      channel: NotificationChannel.general,
      payload: 'writing',
    );

    // Auto-mark Journaling routine item
    final dashRepo = DashboardRepository();
    final progress = dashRepo.loadRoutineProgress();
    if (progress['Journaling'] == false) {
      progress['Journaling'] = true;
      await dashRepo.saveRoutineProgress(progress);
    }

    _load();
    _elapsedSeconds = 0;
  }

  /// Overwrite an existing session with new content/metadata. The session's
  /// id and original `createdAt` are preserved; the fresh elapsed time is
  /// ADDED to the existing duration so "5 min session" keeps climbing each
  /// time the user continues.
  ///
  /// Unlike [saveSession] this does NOT touch the streak (streaks should
  /// only advance on genuine new-entry days) and does not push a
  /// notification — editing silently persists.
  Future<void> updateSession({
    required String id,
    required String content,
    required WritingCategory category,
    required int moodBefore,
    required int moodAfter,
    String? title,
    String? purpose,
    String? reflection,
  }) async {
    _sessionTimer?.cancel();

    final wc = _countWords(content);
    if (wc == 0) return;

    WritingSession? existing;
    for (final s in state.allSessions) {
      if (s.id == id) {
        existing = s;
        break;
      }
    }
    if (existing == null) return;

    final updated = WritingSession(
      id:              existing.id,
      title:           title,
      content:         content,
      wordCount:       wc,
      durationSeconds: existing.durationSeconds + _elapsedSeconds,
      category:        category,
      moodBefore:      moodBefore,
      moodAfter:       moodAfter,
      purpose:         purpose,
      reflection:      reflection,
      createdAt:       existing.createdAt,
      updatedAt:       DateTime.now(),
    );

    await _repo.saveSession(updated);

    final wordsDelta =
        updated.wordCount > existing.wordCount ? updated.wordCount - existing.wordCount : 0;
    if (wordsDelta > 0 || _elapsedSeconds > 0) {
      await TrackingService.record(TrackingFeature.writing, {
        'words':        wordsDelta,
        'totalSeconds': _elapsedSeconds,
      });
    }

    // Clear the editing handle so the next fresh "SAVE" creates a new
    // session instead of clobbering this one again.
    state = state.copyWith(clearEditing: true);
    _load();
    _elapsedSeconds = 0;
    beginWriting();
  }

  Future<void> deleteSession(String id) async {
    await _repo.deleteSession(id);
    // If the user deleted the session they were editing, drop the handle.
    final wasEditing = state.editingSessionId == id;
    if (wasEditing) {
      state = state.copyWith(clearEditing: true);
    }
    _load();
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}


// ── Providers ─────────────────────────────────────────────────────────────────

final writingRepositoryProvider = Provider<WritingRepository>(
  (_) => WritingRepository(),
);

final writingViewModelProvider =
    StateNotifierProvider<WritingViewModel, WritingState>(
  (ref) => WritingViewModel(ref.read(writingRepositoryProvider)),
);
