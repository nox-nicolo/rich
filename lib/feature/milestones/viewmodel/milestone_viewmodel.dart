// lib/feature/milestones/viewmodel/milestone_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../model/milestone.dart';
import '../repository/milestone_repository.dart';

class MilestoneState {
  final List<Milestone> all;
  final bool isLoading;

  const MilestoneState({required this.all, required this.isLoading});

  factory MilestoneState.initial() =>
      const MilestoneState(all: [], isLoading: true);

  MilestoneState copyWith({List<Milestone>? all, bool? isLoading}) =>
      MilestoneState(
        all: all ?? this.all,
        isLoading: isLoading ?? this.isLoading,
      );

  // ── Buckets ──────────────────────────────────────────────────────────────

  List<Milestone> get sixMonth =>
      all.where((m) => m.horizon == Horizon.sixMonth).toList();

  List<Milestone> get yearly =>
      all.where((m) => m.horizon == Horizon.yearly).toList();

  List<Milestone> activeIn(Horizon h) =>
      all.where((m) => m.horizon == h && m.isActive).toList();

  int atRiskCount(Horizon h) =>
      all.where((m) => m.horizon == h && (m.isAtRisk || m.isOverdue)).length;
}

class MilestoneViewModel extends StateNotifier<MilestoneState> {
  final MilestoneRepository _repo;

  MilestoneViewModel(this._repo) : super(MilestoneState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final raw = _repo.loadAll();
    final rolled = await _autoRoll(raw);
    state = state.copyWith(all: rolled, isLoading: false);
  }

  // Any active 6-month milestone whose target date has passed becomes a
  // yearly milestone, with its target snapped to the current year-end so
  // long-term goals stay calendar-aligned instead of drifting forward.
  Future<List<Milestone>> _autoRoll(List<Milestone> input) async {
    final now = DateTime.now();
    final result = <Milestone>[];

    for (final m in input) {
      if (m.horizon == Horizon.sixMonth &&
          m.status == MilestoneStatus.active &&
          now.isAfter(m.targetDate)) {
        final rolled = m.copyWith(
          horizon: Horizon.yearly,
          targetDate: defaultTargetFor(Horizon.yearly, from: now),
          updatedAt: now,
        );
        await _repo.save(rolled);
        result.add(rolled);
      } else {
        result.add(m);
      }
    }
    return result;
  }

  Future<void> refresh() => _load();

  Future<void> create({
    required String title,
    String? note,
    List<String> processSteps = const [],
    required Horizon horizon,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final target = targetDate ?? defaultTargetFor(horizon, from: now);
    final m = Milestone(
      id: const Uuid().v4(),
      title: title.trim(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      processSteps: processSteps
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList(),
      horizon: horizon,
      status: MilestoneStatus.active,
      progress: 0,
      createdAt: now,
      targetDate: target,
      updatedAt: now,
    );
    await _repo.save(m);
    await _load();
  }

  Future<void> update(Milestone updated) async {
    await _repo.save(updated.copyWith(updatedAt: DateTime.now()));
    await _load();
  }

  Future<void> setProgress(String id, double progress) async {
    final existing = state.all.firstWhere((m) => m.id == id);
    final clamped = progress.clamp(0.0, 1.0);
    final markDone = clamped >= 1.0;
    await _repo.save(
      existing.copyWith(
        progress: clamped,
        status: markDone ? MilestoneStatus.done : existing.status,
        updatedAt: DateTime.now(),
      ),
    );
    await _load();
  }

  Future<void> markDone(String id) async {
    final existing = state.all.firstWhere((m) => m.id == id);
    await _repo.save(
      existing.copyWith(
        status: MilestoneStatus.done,
        progress: 1.0,
        updatedAt: DateTime.now(),
      ),
    );
    await _load();
  }

  Future<void> markDropped(String id) async {
    final existing = state.all.firstWhere((m) => m.id == id);
    await _repo.save(
      existing.copyWith(
        status: MilestoneStatus.dropped,
        updatedAt: DateTime.now(),
      ),
    );
    await _load();
  }

  Future<void> reactivate(String id) async {
    final existing = state.all.firstWhere((m) => m.id == id);
    await _repo.save(
      existing.copyWith(
        status: MilestoneStatus.active,
        updatedAt: DateTime.now(),
      ),
    );
    await _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _load();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final milestoneRepositoryProvider = Provider<MilestoneRepository>(
  (_) => MilestoneRepository(),
);

final milestoneViewModelProvider =
    StateNotifierProvider<MilestoneViewModel, MilestoneState>(
      (ref) => MilestoneViewModel(ref.read(milestoneRepositoryProvider)),
    );
