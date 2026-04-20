// lib/features/life/viewmodel/life_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/habit_model.dart';
import '../model/workout_model.dart';
import '../model/health_log_model.dart';
import '../model/recovery_model.dart';
import '../repository/life_repository.dart';

class LifeState {
  final List<HabitModel> habits;
  final List<WorkoutModel> todayWorkouts;
  final HealthLogModel? todayHealthLog;
  final RecoverySession? activeRecovery;
  final String activeTab;
  final bool isLoading;

  const LifeState({
    required this.habits,
    required this.todayWorkouts,
    this.todayHealthLog,
    this.activeRecovery,
    required this.activeTab,
    required this.isLoading,
  });

  factory LifeState.initial() {
    return const LifeState(
      habits: [],
      todayWorkouts: [],
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
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get completedHabitsToday =>
      habits.where((h) => h.completedToday).length;

  bool get hasWorkedOutToday => todayWorkouts.isNotEmpty;

  bool get isInRecovery => activeRecovery != null;
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

    state = state.copyWith(
      habits: habits,
      todayWorkouts: workouts,
      todayHealthLog: healthLog,
      activeRecovery: recovery,
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
    final updated = state.habits.map((h) {
      if (h.id != id) return h;
      return h.complete();
    }).toList();
    final habit = updated.firstWhere((h) => h.id == id);
    await _repo.saveHabit(habit);
    state = state.copyWith(habits: updated);
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
  }

  // ── Health Log ────────────────────────────────────────────────────────────

  Future<void> updateHealthLog({
    int? sleepHours,
    int? waterGlasses,
    int? steps,
    EnergyLevel? energyLevel,
    String? meals,
  }) async {
    final existing = state.todayHealthLog;
    final log = existing != null
        ? existing.copyWith(
            sleepHours: sleepHours,
            waterGlasses: waterGlasses,
            steps: steps,
            energyLevel: energyLevel,
            meals: meals,
          )
        : HealthLogModel(
            id: const Uuid().v4(),
            loggedAt: DateTime.now(),
            sleepHours: sleepHours,
            waterGlasses: waterGlasses,
            steps: steps,
            energyLevel: energyLevel ?? EnergyLevel.moderate,
            meals: meals,
          );
    await _repo.saveHealthLog(log);
    state = state.copyWith(todayHealthLog: log);
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
    state = state.copyWith(activeRecovery: session);
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
    state = state.copyWith(clearRecovery: true);
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
