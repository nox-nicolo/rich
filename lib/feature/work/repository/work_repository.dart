// lib/features/work/repository/work_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/task_model.dart';
import '../model/focus_session_model.dart';
import '../model/meeting_model.dart';
import '../model/work_rule_model.dart';

/// Per-day summary of tasks that were active on a given date.
/// Returned by recycleAndLoadToday() for dates that have now rolled over
/// so the ViewModel can persist them to the tracking/reports system.
class DayTaskSnapshot {
  final DateTime date;
  final int scheduled; // total tasks active that day
  final int done;      // completed that day
  final int pending;   // not done, not blocked — carried forward
  final int blocked;   // blocked

  const DayTaskSnapshot({
    required this.date,
    required this.scheduled,
    required this.done,
    required this.pending,
    required this.blocked,
  });

  Map<String, int> toTrackingData() => {
    'tasksScheduled': scheduled,
    'tasksDone': done,
    'tasksPending': pending,
    'tasksBlocked': blocked,
  };
}

class RecycleResult {
  final List<TaskModel> todayTasks;
  final List<TaskModel> bumpedTasks;
  /// One snapshot per prior day that had tasks. Used for report recording.
  final List<DayTaskSnapshot> priorSnapshots;

  const RecycleResult({
    required this.todayTasks,
    required this.bumpedTasks,
    this.priorSnapshots = const [],
  });
}

class WorkRepository {
  static const String _tasksKey = 'work_tasks_list';
  static const String _sessionsKey = 'work_focus_sessions';
  static const String _meetingsKey = 'work_meetings';
  static const String _rulesKey = 'work_rules';
  static const String _deepWorkActiveKey = 'deep_work_active';

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> saveTask(TaskModel task) async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> existing =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    final index = existing.indexWhere(
        (e) => (e as Map)['id'] == task.id);
    if (index >= 0) {
      existing[index] = task.toMap();
    } else {
      existing.add(task.toMap());
    }
    await box.put(_tasksKey, existing);
  }

  Future<void> deleteTask(String id) async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> existing =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_tasksKey, existing);
  }

  // Carry incomplete tasks from prior days into today. Preserves createdAt on
  // all tasks — only scheduledFor is bumped forward. Builds per-day snapshots
  // for the reporting system so every day's task state is recorded.
  Future<RecycleResult> recycleAndLoadToday() async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);

    final all = raw
        .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Group stale incomplete tasks by their active date for snapshot building
    final Map<String, List<TaskModel>> staleByDay = {};

    final bumped = <TaskModel>[];
    final updated = <TaskModel>[];

    for (final t in all) {
      if (t.isCompleted) {
        updated.add(t);
        continue;
      }

      final anchorDate = _dayOf(t.activeDate);

      if (!anchorDate.isBefore(todayDate)) {
        // Today or future — no change needed
        updated.add(t);
        continue;
      }

      // Stale: record in snapshot map keyed by active day
      final dayKey = _isoDate(anchorDate);
      staleByDay.putIfAbsent(dayKey, () => []).add(t);

      // Bump forward to today (preserving createdAt)
      final daysDelta = todayDate.difference(anchorDate).inDays;

      TaskModel bumpedTask;
      if (t.hasSchedule) {
        var newStart = t.scheduledStart!.add(Duration(days: daysDelta));
        var newEnd = t.scheduledEnd!.add(Duration(days: daysDelta));
        // If today's slot is already past, push one more day
        if (newStart.isBefore(now)) {
          newStart = newStart.add(const Duration(days: 1));
          newEnd = newEnd.add(const Duration(days: 1));
        }
        bumpedTask = t.copyWith(
          scheduledStart: newStart,
          scheduledEnd: newEnd,
          scheduledFor: _dayOf(newStart),
          carriedOverCount: t.carriedOverCount + 1,
          // actualStart intentionally not copied — resets for the new day
        );
        // copyWith doesn't clear actualStart; re-create to clear it
        bumpedTask = TaskModel(
          id: bumpedTask.id,
          title: bumpedTask.title,
          description: bumpedTask.description,
          priority: bumpedTask.priority,
          status: bumpedTask.status,
          createdAt: bumpedTask.createdAt,
          scheduledFor: bumpedTask.scheduledFor,
          carriedOverCount: bumpedTask.carriedOverCount,
          completedAt: bumpedTask.completedAt,
          dueDate: bumpedTask.dueDate,
          scheduledStart: newStart,
          scheduledEnd: newEnd,
          actualStart: null,
          blockedReason: bumpedTask.blockedReason,
          tags: bumpedTask.tags,
        );
      } else {
        // Untimed — only bump scheduledFor; createdAt stays as the origin
        bumpedTask = TaskModel(
          id: t.id,
          title: t.title,
          description: t.description,
          priority: t.priority,
          status: t.status,
          createdAt: t.createdAt,        // immutable — origin date preserved
          scheduledFor: todayDate,        // active day = today
          carriedOverCount: t.carriedOverCount + 1,
          completedAt: t.completedAt,
          dueDate: t.dueDate,
          scheduledStart: null,
          scheduledEnd: null,
          actualStart: null,
          blockedReason: t.blockedReason,
          tags: t.tags,
        );
      }

      updated.add(bumpedTask);
      bumped.add(bumpedTask);
    }

    if (bumped.isNotEmpty) {
      await box.put(_tasksKey, updated.map((t) => t.toMap()).toList());
    }

    // Build per-day snapshots for every prior day that had stale tasks.
    // Completed tasks from those days are fetched separately to count done.
    final completedAll = all.where((t) => t.isCompleted).toList();
    final priorSnapshots = <DayTaskSnapshot>[];

    for (final entry in staleByDay.entries) {
      final date = DateTime.parse(entry.key);
      final incompleteOnDay = entry.value;

      // Count completed tasks whose completedAt falls on the same day
      final doneOnDay = completedAll.where((t) {
        if (t.completedAt == null) return false;
        return _isoDate(_dayOf(t.completedAt!)) == entry.key;
      }).length;

      final pending = incompleteOnDay
          .where((t) => !t.isBlocked)
          .length;
      final blocked = incompleteOnDay
          .where((t) => t.isBlocked)
          .length;

      priorSnapshots.add(DayTaskSnapshot(
        date: date,
        scheduled: incompleteOnDay.length + doneOnDay,
        done: doneOnDay,
        pending: pending,
        blocked: blocked,
      ));
    }

    final todayTasks = updated.where((t) {
      final anchor = _dayOf(t.activeDate);
      return anchor.year == todayDate.year &&
          anchor.month == todayDate.month &&
          anchor.day == todayDate.day;
    }).toList()
      ..sort(_taskOrder);

    return RecycleResult(
      todayTasks: todayTasks,
      bumpedTasks: bumped,
      priorSnapshots: priorSnapshots,
    );
  }

  // Synchronous load — no recycling (used as fallback).
  List<TaskModel> loadTodayTasks() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    final today = _dayOf(DateTime.now());
    return raw
        .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((t) {
          final anchor = _dayOf(t.activeDate);
          return anchor.year == today.year &&
              anchor.month == today.month &&
              anchor.day == today.day;
        })
        .toList()
      ..sort(_taskOrder);
  }

  List<TaskModel> loadAllTasks() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    return raw
        .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// All tasks (any status) whose active date falls within [from, to).
  /// Used by reports to surface every task — completed, pending, or blocked.
  List<TaskModel> loadAllTasksBetween(DateTime from, DateTime to) {
    return loadAllTasks().where((t) {
      final anchor = _dayOf(t.activeDate);
      return !anchor.isBefore(from) && anchor.isBefore(to);
    }).toList();
  }

  // For monthly reports — returns completed tasks within the given range.
  List<TaskModel> loadCompletedBetween(DateTime from, DateTime to) {
    return loadAllTasks().where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return !t.completedAt!.isBefore(from) && t.completedAt!.isBefore(to);
    }).toList();
  }

  // ── Focus Sessions ────────────────────────────────────────────────────────

  Future<void> saveFocusSession(FocusSessionModel session) async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> existing =
        List.from(box.get(_sessionsKey, defaultValue: []) as List);
    existing.add(session.toMap());
    if (existing.length > 100) existing.removeAt(0);
    await box.put(_sessionsKey, existing);
  }

  List<FocusSessionModel> loadTodaySessions() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_sessionsKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) => FocusSessionModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .toList();
  }

  // ── Meetings ──────────────────────────────────────────────────────────────

  Future<void> saveMeeting(MeetingModel meeting) async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> existing =
        List.from(box.get(_meetingsKey, defaultValue: []) as List);
    final index = existing.indexWhere(
        (e) => (e as Map)['id'] == meeting.id);
    if (index >= 0) {
      existing[index] = meeting.toMap();
    } else {
      existing.add(meeting.toMap());
    }
    await box.put(_meetingsKey, existing);
  }

  List<MeetingModel> loadUpcomingMeetings() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_meetingsKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) => MeetingModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .where((m) {
          if (m.status == MeetingStatus.inProgress) return true;
          return m.status == MeetingStatus.upcoming &&
              m.scheduledAt.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  MeetingModel? meetingById(String id) {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_meetingsKey, defaultValue: []) as List);
    for (final e in raw) {
      final map = Map<String, dynamic>.from(e as Map);
      if (map['id'] == id) return MeetingModel.fromMap(map);
    }
    return null;
  }

  // ── Deep Work State ───────────────────────────────────────────────────────

  Future<void> saveDeepWorkActive(bool active) async {
    await HiveService.put(
        HiveBoxes.workTasks, _deepWorkActiveKey, active);
  }

  bool loadDeepWorkActive() {
    return HiveService.get<bool>(
            HiveBoxes.workTasks, _deepWorkActiveKey) ??
        false;
  }

  // ── Work Rules ────────────────────────────────────────────────────────────

  Future<void> saveCustomRule(WorkRuleModel rule) async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> existing =
        List.from(box.get(_rulesKey, defaultValue: []) as List);
    existing.add(rule.toMap());
    await box.put(_rulesKey, existing);
  }

  List<WorkRuleModel> loadCustomRules() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_rulesKey, defaultValue: []) as List);
    return raw
        .map((e) => WorkRuleModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _dayOf(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static int _taskOrder(TaskModel a, TaskModel b) {
    if (a.hasSchedule && b.hasSchedule) {
      return a.scheduledStart!.compareTo(b.scheduledStart!);
    }
    if (a.hasSchedule) return -1;
    if (b.hasSchedule) return 1;
    return a.priority.index.compareTo(b.priority.index);
  }
}
