// lib/features/life/viewmodel/life_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/habit_model.dart';
import '../model/workout_model.dart';
import '../model/health_log_model.dart';
import '../model/recovery_model.dart';
import '../repository/life_repository.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

class LifeState {
  final List<HabitModel> habits;
  final List<WorkoutModel> todayWorkouts;
  final HealthLogModel? todayHealthLog;
  final RecoverySession? activeRecovery;
  final List<RecoverySession> recentRecoverySessions;
  final String activeTab;
  final bool isLoading;

  const LifeState({
    required this.habits,
    required this.todayWorkouts,
    this.todayHealthLog,
    this.activeRecovery,
    required this.recentRecoverySessions,
    required this.activeTab,
    required this.isLoading,
  });

  factory LifeState.initial() {
    return const LifeState(
      habits: [],
      todayWorkouts: [],
      recentRecoverySessions: [],
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
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get completedHabitsToday =>
      habits.where((h) => h.completedToday).length;

  bool get hasWorkedOutToday => todayWorkouts.isNotEmpty;

  bool get isInRecovery => activeRecovery != null;

  /// Sessions that started today, both finished and active.
  List<RecoverySession> get todayRecoverySessions {
    final now = DateTime.now();
    return recentRecoverySessions
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .toList();
  }

  /// Minutes of completed recovery time logged today (excludes the live one).
  int get todayRecoveryMinutes {
    int total = 0;
    for (final s in todayRecoverySessions) {
      if (s.endedAt == null) continue;
      total += s.endedAt!.difference(s.startedAt).inMinutes;
    }
    return total;
  }
}

class LifeViewModel extends StateNotifier<LifeState> {
  final LifeRepository _repo;

  LifeViewModel(this._repo) : super(LifeState.initial()) {
    _load();
  }

  void _load() {
    final habits = _repo.loadHabits();
    final workouts = _repo.loadTodayWorkouts();
    final healthLog = _repo.loadTodayHealthLog();
    final recovery = _repo.loadActiveRecoverySession();
    final recent = _repo.loadAllRecoverySessions()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    state = state.copyWith(
      habits: habits,
      todayWorkouts: workouts,
      todayHealthLog: healthLog,
      activeRecovery: recovery,
      recentRecoverySessions: recent.take(20).toList(),
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
    final alreadyDoneToday = prior.completedToday;
    final updated = state.habits.map((h) {
      if (h.id != id) return h;
      return h.complete();
    }).toList();
    final habit = updated.firstWhere((h) => h.id == id);
    await _repo.saveHabit(habit);
    state = state.copyWith(habits: updated);

    if (!alreadyDoneToday) {
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
    state = state.copyWith(
      todayWorkouts: [...state.todayWorkouts, workout],
    );

    await TrackingService.record(TrackingFeature.life, {
      'workouts':       1,
      'workoutMinutes': workout.durationMinutes,
    });
    VibrationService.strongPulse();

    // Auto-mark Workout routine item
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

  /// Energy is a roll-up of the day's recorded health signals — never set by
  /// the user directly. Recomputes whenever sleep/water/steps/workout change.
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
    if (state.todayWorkouts.isNotEmpty) score += 1;

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
      recentRecoverySessions: [session, ...state.recentRecoverySessions]
          .take(20)
          .toList(),
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

    final seconds =
        ended.endedAt!.difference(ended.startedAt).inSeconds;
    await TrackingService.record(TrackingFeature.life, {
      'recoverySessions': 1,
      'recoverySeconds':  seconds,
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final lifeRepositoryProvider = Provider<LifeRepository>(
  (_) => LifeRepository(),
);

final lifeViewModelProvider =
    StateNotifierProvider<LifeViewModel, LifeState>(
  (ref) => LifeViewModel(ref.read(lifeRepositoryProvider)),
);
