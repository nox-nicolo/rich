// lib/features/meditation/viewmodel/meditation_viewmodel.dart

import 'dart:async';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/meditation_session_model.dart';
import '../model/meditation_streak_model.dart';
import '../model/meditation_type.dart';
import '../repository/meditation_repository.dart';
import '../../../providers/rule_context_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';
import '../../dashboard/repository/dashboard_repository.dart';

class MeditationState {
  final MeditationStreak streak;
  final List<MeditationSession> todaySessions;
  final MeditationSession? activeSession;
  final int timerSeconds;
  final bool timerRunning;
  final MoodLevel selectedMood;
  final bool completedToday;
  final bool isLoading;

  const MeditationState({
    required this.streak,
    required this.todaySessions,
    this.activeSession,
    required this.timerSeconds,
    required this.timerRunning,
    required this.selectedMood,
    required this.completedToday,
    required this.isLoading,
  });

  factory MeditationState.initial() {
    return MeditationState(
      streak: MeditationStreak.empty(),
      todaySessions: const [],
      timerSeconds: 0,
      timerRunning: false,
      selectedMood: MoodLevel.neutral,
      completedToday: false,
      isLoading: true,
    );
  }

  MeditationState copyWith({
    MeditationStreak? streak,
    List<MeditationSession>? todaySessions,
    MeditationSession? activeSession,
    bool clearActive = false,
    int? timerSeconds,
    bool? timerRunning,
    MoodLevel? selectedMood,
    bool? completedToday,
    bool? isLoading,
  }) {
    return MeditationState(
      streak: streak ?? this.streak,
      todaySessions: todaySessions ?? this.todaySessions,
      activeSession:
          clearActive ? null : (activeSession ?? this.activeSession),
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRunning: timerRunning ?? this.timerRunning,
      selectedMood: selectedMood ?? this.selectedMood,
      completedToday: completedToday ?? this.completedToday,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get hasActiveSession => activeSession != null;

  bool isTypeCompletedToday(MeditationType type) {
    return todaySessions.any((s) => s.type == type && s.completed);
  }
}

class MeditationViewModel extends StateNotifier<MeditationState> {
  final MeditationRepository _repo;
  final Ref _ref;
  Timer? _timer;

  MeditationViewModel(this._repo, this._ref)
      : super(MeditationState.initial()) {
    _load();
  }

  void _load() {
    final streak = _repo.loadStreak();
    final todaySessions = _repo.loadTodaySessions();
    final completedToday = _repo.isCompletedToday();

    state = state.copyWith(
      streak: streak,
      todaySessions: todaySessions,
      completedToday: completedToday,
      isLoading: false,
    );

    if (completedToday) {
      // Defer until after the full frame renders — safe to modify other providers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ref.read(ruleContextProvider.notifier).completeMeditation();
      });
    }
  }

  void selectMood(MoodLevel mood) {
    state = state.copyWith(selectedMood: mood);
    _ref
        .read(ruleContextProvider.notifier)
        .setEmotionalState(mood.isUnstable);
  }

  void startSession(MeditationType type) {
    final session = MeditationSession(
      id: const Uuid().v4(),
      type: type,
      startedAt: DateTime.now(),
      durationSeconds: type.defaultDurationSeconds,
      completed: false,
      moodBefore: state.selectedMood,
    );
    state = state.copyWith(
      activeSession: session,
      timerSeconds: type.defaultDurationSeconds,
      timerRunning: false,
    );
  }

  void startTimer() {
    if (state.timerRunning || !state.hasActiveSession) return;
    state = state.copyWith(timerRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.timerSeconds - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(timerSeconds: 0, timerRunning: false);
        completeSession();
      } else {
        state = state.copyWith(timerSeconds: remaining);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(timerRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    final duration = state.activeSession?.durationSeconds ?? 0;
    state = state.copyWith(timerSeconds: duration, timerRunning: false);
  }

  void cancelSession() {
    _timer?.cancel();
    state = state.copyWith(clearActive: true, timerRunning: false);
  }

  Future<void> completeSession({String? note}) async {
    final session = state.activeSession;
    if (session == null) return;
    _timer?.cancel();

    final completed = session.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      moodAfter: state.selectedMood,
      note: note,
    );

    await _repo.saveSession(completed);

    await TrackingService.record(TrackingFeature.meditation, {
      'sessions':       1,
      'totalSeconds':   completed.durationSeconds,
    });
    VibrationService.strongPulse();

    final updated = [...state.todaySessions, completed];
    state = state.copyWith(
      todaySessions: updated,
      clearActive: true,
      timerRunning: false,
    );

    // Auto-mark the corresponding routine item without requiring user to tap
    final dashRepo = DashboardRepository();
    final routineKey = _routineKeyFor(completed.type);
    if (routineKey != null) {
      final progress = dashRepo.loadRoutineProgress();
      if (progress[routineKey] == false) {
        progress[routineKey] = true;
        await dashRepo.saveRoutineProgress(progress);
      }
    }

    // Any completed meditation closes the daily gate. Restricting it to
    // Prayer/Breathing/Stillness made the screen feel "new every day"
    // because finishing Reflection / Visualization / Reset never persisted
    // anything.
    if (!state.completedToday) {
      await _markGateComplete();
    }
  }

  String? _routineKeyFor(MeditationType type) {
    switch (type) {
      case MeditationType.prayer:      return 'Prayer';
      case MeditationType.breathing:   return 'Breathing';
      default:                         return null;
    }
  }

  Future<void> _markGateComplete() async {
    final newStreak = state.streak.increment();
    await _repo.saveStreak(newStreak);
    await _repo.markCompletedToday();
    state = state.copyWith(streak: newStreak, completedToday: true);
    _ref.read(ruleContextProvider.notifier).completeMeditation();
    await NotificationService.instance.show(
      id:      20,
      title:   'Gate Open',
      body:    'Meditation complete. Trading and Betting are now unlocked.',
      channel: NotificationChannel.general,
      payload: 'meditation',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final meditationRepositoryProvider = Provider<MeditationRepository>(
  (_) => MeditationRepository(),
);

final meditationViewModelProvider =
    StateNotifierProvider<MeditationViewModel, MeditationState>(
  (ref) => MeditationViewModel(
    ref.read(meditationRepositoryProvider),
    ref,
  ),
);
