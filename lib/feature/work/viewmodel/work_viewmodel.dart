// lib/features/work/viewmodel/work_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/task_model.dart';
import '../model/focus_session_model.dart';
import '../model/meeting_model.dart';
import '../model/work_rule_model.dart';
import '../repository/work_repository.dart';
import '../../../providers/rule_context_provider.dart';
import '../../rules_engine/model/user_mode.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

class WorkState {
  final List<TaskModel> todayTasks;
  final List<FocusSessionModel> todaySessions;
  final List<MeetingModel> upcomingMeetings;
  final List<WorkRuleModel> rules;
  final FocusSessionModel? activeSession;
  final int timerSeconds;
  final bool timerRunning;
  final bool isDeepWorkActive;
  final String activeTab;
  final bool isLoading;

  const WorkState({
    required this.todayTasks,
    required this.todaySessions,
    required this.upcomingMeetings,
    required this.rules,
    this.activeSession,
    required this.timerSeconds,
    required this.timerRunning,
    required this.isDeepWorkActive,
    required this.activeTab,
    required this.isLoading,
  });

  factory WorkState.initial() {
    return WorkState(
      todayTasks: const [],
      todaySessions: const [],
      upcomingMeetings: const [],
      rules: defaultWorkRules,
      timerSeconds: 0,
      timerRunning: false,
      isDeepWorkActive: false,
      activeTab: 'TASKS',
      isLoading: true,
    );
  }

  WorkState copyWith({
    List<TaskModel>? todayTasks,
    List<FocusSessionModel>? todaySessions,
    List<MeetingModel>? upcomingMeetings,
    List<WorkRuleModel>? rules,
    FocusSessionModel? activeSession,
    bool clearSession = false,
    int? timerSeconds,
    bool? timerRunning,
    bool? isDeepWorkActive,
    String? activeTab,
    bool? isLoading,
  }) {
    return WorkState(
      todayTasks: todayTasks ?? this.todayTasks,
      todaySessions: todaySessions ?? this.todaySessions,
      upcomingMeetings: upcomingMeetings ?? this.upcomingMeetings,
      rules: rules ?? this.rules,
      activeSession:
          clearSession ? null : (activeSession ?? this.activeSession),
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRunning: timerRunning ?? this.timerRunning,
      isDeepWorkActive: isDeepWorkActive ?? this.isDeepWorkActive,
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get hasActiveSession => activeSession != null;

  int get completedTaskCount =>
      todayTasks.where((t) => t.isCompleted).length;

  int get pendingTaskCount =>
      todayTasks.where((t) => !t.isCompleted).length;

  List<TaskModel> get highPriorityTasks =>
      todayTasks.where((t) => t.isHighPriority && !t.isCompleted).toList();

  MeetingModel? get nextMeeting =>
      upcomingMeetings.isNotEmpty ? upcomingMeetings.first : null;
}

class WorkViewModel extends StateNotifier<WorkState> {
  final WorkRepository _repo;
  final Ref _ref;
  Timer? _timer;

  WorkViewModel(this._repo, this._ref) : super(WorkState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final recycle = await _repo.recycleAndLoadToday();
    final sessions = _repo.loadTodaySessions();
    final meetings = _repo.loadUpcomingMeetings();
    final customRules = _repo.loadCustomRules();
    final deepWorkActive = _repo.loadDeepWorkActive();

    final allRules = [...defaultWorkRules, ...customRules];

    state = state.copyWith(
      todayTasks: recycle.todayTasks,
      todaySessions: sessions,
      upcomingMeetings: meetings,
      rules: allRules,
      isDeepWorkActive: deepWorkActive,
      isLoading: false,
    );

    // Re-schedule notifications for recycled tasks landing in the future
    final now = DateTime.now();
    for (final t in recycle.bumpedTasks) {
      if (t.scheduledStart != null && t.scheduledStart!.isAfter(now)) {
        await _scheduleTaskNotification(t);
      }
    }

    if (deepWorkActive) {
      _ref.read(ruleContextProvider.notifier).setDeepWork(true);
    }
  }

  Future<void> _scheduleTaskNotification(TaskModel task) async {
    if (task.scheduledStart == null) return;
    if (!task.scheduledStart!.isAfter(DateTime.now())) return;
    await NotificationService.instance.cancel(task.notificationId);
    await NotificationService.instance.schedule(
      id: task.notificationId,
      title: 'Time to start: ${task.title}',
      body: task.scheduledEnd != null
          ? 'Until ${_hhmm(task.scheduledEnd!)}'
          : 'Tap to focus',
      scheduledTime: task.scheduledStart!,
      channel: NotificationChannel.reminder,
    );
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> addTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    );
    await _repo.saveTask(task);
    state = state.copyWith(
      todayTasks: _sortTasks([...state.todayTasks, task]),
    );
    await _scheduleTaskNotification(task);
  }

  TaskModel? taskById(String id) {
    for (final t in state.todayTasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> markTaskStarted(String id) async {
    final prior = state.todayTasks.firstWhere((t) => t.id == id);
    if (prior.actualStart != null || prior.isCompleted) return;
    final updated = state.todayTasks.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        actualStart: DateTime.now(),
        status: TaskStatus.inProgress,
      );
    }).toList();
    await _repo.saveTask(updated.firstWhere((t) => t.id == id));
    state = state.copyWith(todayTasks: updated);
  }

  Future<void> completeTask(String id) async {
    final prior = state.todayTasks.firstWhere((t) => t.id == id);
    final alreadyCompleted = prior.isCompleted;
    final now = DateTime.now();
    final updated = state.todayTasks.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
        // If user completed without ever opening focus screen, treat now as start
        actualStart: t.actualStart ?? t.scheduledStart ?? now,
      );
    }).toList();
    final task = updated.firstWhere((t) => t.id == id);
    await _repo.saveTask(task);
    await NotificationService.instance.cancel(task.notificationId);
    state = state.copyWith(todayTasks: updated);

    if (!alreadyCompleted) {
      final payload = <String, dynamic>{'tasksCompleted': 1};
      final planned = task.plannedMinutes;
      final actual = task.actualMinutes;
      if (planned != null) payload['taskPlannedSeconds'] = planned * 60;
      if (actual != null) payload['taskActualSeconds'] = actual * 60;
      if (planned != null && actual != null) {
        payload['taskOverrunSeconds'] = (actual - planned) * 60;
      }
      await TrackingService.record(TrackingFeature.work, payload);
      VibrationService.strongPulse();
    }
  }

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    final out = [...tasks];
    out.sort((a, b) {
      if (a.hasSchedule && b.hasSchedule) {
        return a.scheduledStart!.compareTo(b.scheduledStart!);
      }
      if (a.hasSchedule) return -1;
      if (b.hasSchedule) return 1;
      return a.priority.index.compareTo(b.priority.index);
    });
    return out;
  }

  Future<void> blockTask(String id, String reason) async {
    final updated = state.todayTasks.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        status: TaskStatus.blocked,
        blockedReason: reason,
      );
    }).toList();
    final task = updated.firstWhere((t) => t.id == id);
    await _repo.saveTask(task);
    state = state.copyWith(todayTasks: updated);
  }

  Future<void> deleteTask(String id) async {
    final prior = state.todayTasks.firstWhere(
      (t) => t.id == id,
      orElse: () => TaskModel(
        id: id,
        title: '',
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _repo.deleteTask(id);
    await NotificationService.instance.cancel(prior.notificationId);
    state = state.copyWith(
      todayTasks: state.todayTasks.where((t) => t.id != id).toList(),
    );
  }

  // ── Focus Session ─────────────────────────────────────────────────────────

  void startFocusSession(FocusSessionType type, {String? taskId}) {
    final session = FocusSessionModel(
      id: const Uuid().v4(),
      type: type,
      startedAt: DateTime.now(),
      durationMinutes: type.defaultDurationMinutes,
      completed: false,
      taskFocusedOn: taskId,
    );
    state = state.copyWith(
      activeSession: session,
      timerSeconds: session.durationSeconds,
      timerRunning: false,
    );
    if (type.isDeepWork) {
      _setDeepWork(true);
    }
    _ref.read(ruleContextProvider.notifier).setMode(UserMode.working);
  }

  void startTimer() {
    if (state.timerRunning || !state.hasActiveSession) return;
    state = state.copyWith(timerRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.timerSeconds - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(timerSeconds: 0, timerRunning: false);
        completeFocusSession();
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

  void cancelFocusSession() {
    _timer?.cancel();
    _setDeepWork(false);
    state = state.copyWith(clearSession: true, timerRunning: false);
    _ref.read(ruleContextProvider.notifier).setMode(UserMode.idle);
  }

  Future<void> completeFocusSession({String? outcome}) async {
    final session = state.activeSession;
    if (session == null) return;
    _timer?.cancel();

    final completed = session.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      outcome: outcome,
    );
    await _repo.saveFocusSession(completed);
    _setDeepWork(false);

    state = state.copyWith(
      todaySessions: [...state.todaySessions, completed],
      clearSession: true,
      timerRunning: false,
    );
    _ref.read(ruleContextProvider.notifier).setMode(UserMode.idle);

    final actualSeconds = completed.completedAt != null
        ? completed.completedAt!.difference(completed.startedAt).inSeconds
        : completed.durationSeconds;
    await TrackingService.record(TrackingFeature.work, {
      'sessions':     1,
      'deepSessions': session.type.isDeepWork ? 1 : 0,
      'totalSeconds': actualSeconds,
    });
    VibrationService.strongPulse();

    // Auto-mark Deep Work routine item
    if (session.type.isDeepWork) {
      final dashRepo = DashboardRepository();
      final progress = dashRepo.loadRoutineProgress();
      if (progress['Deep Work'] == false) {
        progress['Deep Work'] = true;
        await dashRepo.saveRoutineProgress(progress);
      }
    }
  }

  void _setDeepWork(bool active) {
    state = state.copyWith(isDeepWorkActive: active);
    _repo.saveDeepWorkActive(active);
    _ref.read(ruleContextProvider.notifier).setDeepWork(active);
  }

  // ── Meetings ──────────────────────────────────────────────────────────────

  Future<void> addMeeting({
    required String title,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    String? agenda,
  }) async {
    final meeting = MeetingModel(
      id: const Uuid().v4(),
      title: title,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      status: MeetingStatus.upcoming,
      agenda: agenda,
      createdAt: DateTime.now(),
    );
    await _repo.saveMeeting(meeting);
    state = state.copyWith(
      upcomingMeetings: [...state.upcomingMeetings, meeting]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
    );
    await _scheduleMeetingNotifications(meeting);
  }

  Future<void> _scheduleMeetingNotifications(MeetingModel m) async {
    final now = DateTime.now();

    // 5-minute heads-up
    final reminderAt = m.scheduledAt.subtract(const Duration(minutes: 5));
    await NotificationService.instance.cancel(m.reminderNotificationId);
    if (reminderAt.isAfter(now)) {
      await NotificationService.instance.schedule(
        id: m.reminderNotificationId,
        title: '${m.title} starts in 5 min',
        body: 'At ${_hhmm(m.scheduledAt)}',
        scheduledTime: reminderAt,
        channel: NotificationChannel.reminder,
        payload: 'meeting:${m.id}',
      );
    }

    // Start ping
    await NotificationService.instance.cancel(m.startNotificationId);
    if (m.scheduledAt.isAfter(now)) {
      await NotificationService.instance.schedule(
        id: m.startNotificationId,
        title: '${m.title} starting now',
        body: 'Tap to open meeting',
        scheduledTime: m.scheduledAt,
        channel: NotificationChannel.reminder,
        payload: 'meeting:${m.id}',
      );
    }
  }

  Future<void> _cancelMeetingNotifications(MeetingModel m) async {
    await NotificationService.instance.cancel(m.reminderNotificationId);
    await NotificationService.instance.cancel(m.startNotificationId);
  }

  MeetingModel? meetingById(String id) {
    for (final m in state.upcomingMeetings) {
      if (m.id == id) return m;
    }
    return _repo.meetingById(id);
  }

  Future<void> startMeeting(String id) async {
    final m = meetingById(id);
    if (m == null || m.isCompleted) return;
    if (m.isInProgress) return;
    final updated = m.copyWith(
      status: MeetingStatus.inProgress,
      actualStart: DateTime.now(),
    );
    await _repo.saveMeeting(updated);
    await _cancelMeetingNotifications(updated);
    final list = state.upcomingMeetings.map((x) => x.id == id ? updated : x).toList();
    if (!list.any((x) => x.id == id)) list.add(updated);
    state = state.copyWith(
      upcomingMeetings: list..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
    );
  }

  Future<void> endMeeting(String id, {String? outcome}) async {
    final m = meetingById(id);
    if (m == null || m.isCompleted) return;
    final now = DateTime.now();
    final updated = m.copyWith(
      status: MeetingStatus.completed,
      actualStart: m.actualStart ?? now,
      actualEnd: now,
      outcome: outcome,
    );
    await _repo.saveMeeting(updated);
    await _cancelMeetingNotifications(updated);

    final actualMins = updated.actualEnd!
        .difference(updated.actualStart!)
        .inMinutes;
    await TrackingService.record(TrackingFeature.work, {
      'meetings': 1,
      'meetingActualMinutes': actualMins,
      'meetingPlannedMinutes': updated.durationMinutes,
    });
    VibrationService.strongPulse();

    state = state.copyWith(
      upcomingMeetings:
          state.upcomingMeetings.where((x) => x.id != id).toList(),
    );
  }

  Future<void> saveMeetingPrepNotes(
      String id, String notes) async {
    final updated = state.upcomingMeetings.map((m) {
      if (m.id != id) return m;
      return m.copyWith(prepNotes: notes);
    }).toList();
    final meeting = updated.firstWhere((m) => m.id == id);
    await _repo.saveMeeting(meeting);
    state = state.copyWith(upcomingMeetings: updated);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final workRepositoryProvider = Provider<WorkRepository>(
  (_) => WorkRepository(),
);

final workViewModelProvider =
    StateNotifierProvider<WorkViewModel, WorkState>(
  (ref) => WorkViewModel(ref.read(workRepositoryProvider), ref),
);
