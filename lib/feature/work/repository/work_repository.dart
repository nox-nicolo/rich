// lib/features/work/repository/work_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/task_model.dart';
import '../model/focus_session_model.dart';
import '../model/meeting_model.dart';
import '../model/work_rule_model.dart';

class RecycleResult {
  final List<TaskModel> todayTasks;
  final List<TaskModel> bumpedTasks; // tasks whose scheduledStart was moved forward

  const RecycleResult({required this.todayTasks, required this.bumpedTasks});
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

  // Recycle pending tasks from prior days into today (or next day if today's
  // slot has already passed). Persists any bumps. Returns today's list plus
  // the list of tasks that were bumped (so the caller can reschedule
  // notifications for them).
  Future<RecycleResult> recycleAndLoadToday() async {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);

    final all = raw
        .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final bumped = <TaskModel>[];
    final updated = <TaskModel>[];

    for (final t in all) {
      if (t.isCompleted) {
        updated.add(t);
        continue;
      }

      // The "active date" is the scheduled date if present, else createdAt
      final anchor = t.scheduledStart ?? t.createdAt;
      final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);

      if (!anchorDate.isBefore(todayDate)) {
        updated.add(t);
        continue;
      }

      // Compute days to bump so the anchor lands on today
      int daysDelta = todayDate.difference(anchorDate).inDays;

      TaskModel bumpedTask;
      if (t.hasSchedule) {
        var newStart = t.scheduledStart!.add(Duration(days: daysDelta));
        var newEnd = t.scheduledEnd!.add(Duration(days: daysDelta));
        // If today's slot is already in the past, push to next day
        if (newStart.isBefore(now)) {
          newStart = newStart.add(const Duration(days: 1));
          newEnd = newEnd.add(const Duration(days: 1));
        }
        bumpedTask = t.copyWith(
          scheduledStart: newStart,
          scheduledEnd: newEnd,
          actualStart: null, // reset for the new day
        );
      } else {
        // Untimed — just shift createdAt forward so it shows today
        // (createdAt is final, so we re-create the model)
        final newCreated = DateTime(
          todayDate.year,
          todayDate.month,
          todayDate.day,
          t.createdAt.hour,
          t.createdAt.minute,
        );
        bumpedTask = TaskModel(
          id: t.id,
          title: t.title,
          description: t.description,
          priority: t.priority,
          status: t.status,
          createdAt: newCreated,
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

    // Persist if anything changed
    if (bumped.isNotEmpty) {
      await box.put(_tasksKey, updated.map((t) => t.toMap()).toList());
    }

    final todayTasks = updated.where((t) {
      final anchor = t.scheduledStart ?? t.createdAt;
      return anchor.year == todayDate.year &&
          anchor.month == todayDate.month &&
          anchor.day == todayDate.day;
    }).toList()
      ..sort((a, b) {
        // Scheduled tasks first, ordered by start time; then by priority
        if (a.hasSchedule && b.hasSchedule) {
          return a.scheduledStart!.compareTo(b.scheduledStart!);
        }
        if (a.hasSchedule) return -1;
        if (b.hasSchedule) return 1;
        return a.priority.index.compareTo(b.priority.index);
      });

    return RecycleResult(todayTasks: todayTasks, bumpedTasks: bumped);
  }

  // Kept for backwards compatibility — synchronous, no recycling.
  List<TaskModel> loadTodayTasks() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    final now = DateTime.now();
    return raw
        .map((e) =>
            TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((t) {
          final anchor = t.scheduledStart ?? t.createdAt;
          return anchor.year == now.year &&
              anchor.month == now.month &&
              anchor.day == now.day;
        })
        .toList()
      ..sort((a, b) {
        if (a.hasSchedule && b.hasSchedule) {
          return a.scheduledStart!.compareTo(b.scheduledStart!);
        }
        if (a.hasSchedule) return -1;
        if (b.hasSchedule) return 1;
        return a.priority.index.compareTo(b.priority.index);
      });
  }

  List<TaskModel> loadAllTasks() {
    final box = HiveService.box(HiveBoxes.workTasks);
    final List<dynamic> raw =
        List.from(box.get(_tasksKey, defaultValue: []) as List);
    return raw
        .map((e) =>
            TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
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
}
