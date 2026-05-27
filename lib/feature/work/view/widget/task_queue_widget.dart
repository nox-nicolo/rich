// lib/features/work/view/widgets/task_queue_widget.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/task_model.dart';
import '../../viewmodel/work_viewmodel.dart';

class TaskQueueWidget extends ConsumerStatefulWidget {
  const TaskQueueWidget({super.key});

  @override
  ConsumerState<TaskQueueWidget> createState() => _TaskQueueWidgetState();
}

class _TaskQueueWidgetState extends ConsumerState<TaskQueueWidget> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workViewModelProvider);
    final vm = ref.read(workViewModelProvider.notifier);

    final pending = state.todayTasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => _taskOrderAt(a, b, _now));
    final completed = state.todayTasks.where((t) => t.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: "TODAY'S TASKS",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.completedTaskCount}/${state.todayTasks.length}',
                style: AppTypography.mono.copyWith(fontSize: 12),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _showAddTaskSheet(context, vm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (state.todayTasks.isEmpty)
          _EmptyState()
        else ...[
          // pending tasks
          ...pending.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TaskTile(
                task: task,
                onComplete: () => vm.completeTask(task.id),
                onDelete: () => vm.deleteTask(task.id),
                onEdit: () => _showTaskSheet(context, vm, task: task),
                now: _now,
                onFocus: task.hasSchedule && !task.scheduledStart!.isAfter(_now)
                    ? () => context.go('/work/focus/${task.id}')
                    : null,
              ),
            ),
          ),

          // completed tasks (collapsed section)
          if (completed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'DONE (${completed.length})',
              style: AppTypography.label.copyWith(
                color: AppColors.textMuted,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...completed.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _TaskTile(
                  task: task,
                  onComplete: () {},
                  onDelete: () => vm.deleteTask(task.id),
                  onEdit: () => _showTaskSheet(context, vm, task: task),
                  now: _now,
                  onFocus: null,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context, WorkViewModel vm) {
    _showTaskSheet(context, vm);
  }

  void _showTaskSheet(
    BuildContext context,
    WorkViewModel vm, {
    TaskModel? task,
  }) {
    final isEditing = task != null;
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    if (task != null) {
      titleCtrl.text = task.title;
      notesCtrl.text = task.description ?? '';
    }
    TaskPriority intensity = task?.priority ?? TaskPriority.medium;

    final now = DateTime.now();
    TimeOfDay start = TimeOfDay(
      hour: (task?.scheduledStart ?? now.add(const Duration(minutes: 1))).hour,
      minute:
          (task?.scheduledStart ?? now.add(const Duration(minutes: 1))).minute,
    );
    TimeOfDay end = TimeOfDay(
      hour: (task?.scheduledEnd ?? now.add(const Duration(minutes: 31))).hour,
      minute:
          (task?.scheduledEnd ?? now.add(const Duration(minutes: 31))).minute,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'EDIT TASK' : 'ADD TASK',
                style: AppTypography.label,
              ),
              const SizedBox(height: 12),

              // Title
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                ),
              ),
              const SizedBox(height: 10),

              // Notes
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)...',
                ),
              ),
              const SizedBox(height: 14),

              // Time slot
              Text(
                'TIME',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: 'START',
                      time: start,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: start,
                        );
                        if (picked != null) {
                          setState(() {
                            start = picked;
                            // Auto-shift end if it landed before start
                            if (_toMins(end) <= _toMins(start)) {
                              end = _addMinutes(start, 30);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeChip(
                      label: 'END',
                      time: end,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: end,
                        );
                        if (picked != null) setState(() => end = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Intensity selector
              Text(
                'INTENSITY',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = p == intensity;
                  final color = _intensityColor(p);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => intensity = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 1 : 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.label,
                              style: AppTypography.chip.copyWith(
                                color: isSelected ? color : AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final today = DateTime.now();
                    final base = DateTime(today.year, today.month, today.day);
                    var startDt = base.add(
                      Duration(hours: start.hour, minutes: start.minute),
                    );
                    var endDt = base.add(
                      Duration(hours: end.hour, minutes: end.minute),
                    );
                    // If end <= start, treat end as next day at that time
                    if (!endDt.isAfter(startDt)) {
                      endDt = endDt.add(const Duration(days: 1));
                    }
                    final title = titleCtrl.text.trim();
                    final description = notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim();
                    if (isEditing) {
                      vm.updateTask(
                        id: task.id,
                        title: title,
                        description: description,
                        priority: intensity,
                        scheduledStart: startDt,
                        scheduledEnd: endDt,
                      );
                    } else {
                      vm.addTask(
                        title: title,
                        description: description,
                        priority: intensity,
                        scheduledStart: startDt,
                        scheduledEnd: endDt,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'SAVE CHANGES' : 'ADD TASK',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.background,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _taskOrderAt(TaskModel a, TaskModel b, DateTime now) {
  final aBucket = _taskTimeBucket(a, now);
  final bBucket = _taskTimeBucket(b, now);
  if (aBucket != bBucket) return aBucket.compareTo(bBucket);

  if (a.hasSchedule && b.hasSchedule) {
    if (aBucket == 0) {
      return a.scheduledEnd!.compareTo(b.scheduledEnd!);
    }
    if (aBucket == 1) {
      return a.scheduledStart!.compareTo(b.scheduledStart!);
    }
    return b.scheduledEnd!.compareTo(a.scheduledEnd!);
  }

  if (a.hasSchedule) return -1;
  if (b.hasSchedule) return 1;
  return a.priority.index.compareTo(b.priority.index);
}

int _taskTimeBucket(TaskModel task, DateTime now) {
  if (task.status == TaskStatus.inProgress) return 0;
  if (!task.hasSchedule) return 3;
  if (!now.isBefore(task.scheduledStart!) && now.isBefore(task.scheduledEnd!)) {
    return 0;
  }
  if (now.isBefore(task.scheduledStart!)) return 1;
  return 2;
}

int _toMins(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay _addMinutes(TimeOfDay t, int m) {
  final total = (_toMins(t) + m) % (24 * 60);
  return TimeOfDay(hour: total ~/ 60, minute: total % 60);
}

String _formatTOD(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _TimeChip extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeChip({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.chip.copyWith(
                color: AppColors.textMuted,
                fontSize: 9,
              ),
            ),
            Text(
              _formatTOD(time),
              style: AppTypography.mono.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _intensityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.critical:
      return const Color(0xFFFF3B30); // red
    case TaskPriority.high:
      return AppColors.warning;
    case TaskPriority.medium:
      return AppColors.caution;
    case TaskPriority.low:
      return AppColors.textMuted;
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final DateTime now;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onFocus;

  const _TaskTile({
    required this.task,
    required this.now,
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final color = _intensityColor(task.priority);
    final timeStatus = _timeStatus(task, now);

    return Container(
      decoration: BoxDecoration(
        color: task.isCompleted
            ? AppColors.surface.withValues(alpha: 0.4)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: task.priority == TaskPriority.critical && !task.isCompleted
              ? color.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Completion area: 56×56 plain GestureDetector tap zone ────────
          // Plain GestureDetector (no Material/InkWell to avoid shape clipping
          // or arena weirdness). HitTestBehavior.opaque guarantees the tap is
          // captured anywhere in the 56×56 box, not just the visible circle.
          GestureDetector(
            onTap: task.isCompleted ? null : onComplete,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppColors.success
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.success,
                      )
                    : null,
              ),
            ),
          ),

          // Intensity bar
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: task.isCompleted ? AppColors.border : color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content — tappable for focus screen
          Expanded(
            child: GestureDetector(
              onTap: onFocus,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppTypography.h3.copyWith(
                              fontSize: 13,
                              color: task.isCompleted
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (task.hasSchedule)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '${_hhmm(task.scheduledStart!)}–${_hhmm(task.scheduledEnd!)}',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: task.isCompleted
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        if (!task.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.priority.label,
                              style: AppTypography.chip.copyWith(
                                color: color,
                                fontSize: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.description != null && !task.isCompleted) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (timeStatus != null && !task.isCompleted) ...[
                      const SizedBox(height: 3),
                      Text(
                        timeStatus.label,
                        style: AppTypography.caption.copyWith(
                          color: timeStatus.color,
                        ),
                      ),
                    ],
                    if (task.isCompleted && task.overrunMinutes != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.overrunMinutes! > 0
                            ? '+${task.overrunMinutes}m over plan'
                            : task.overrunMinutes! < 0
                            ? '${-task.overrunMinutes!}m under plan'
                            : 'on time',
                        style: AppTypography.caption.copyWith(
                          color: task.overrunMinutes! > 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                    if (task.isBlocked && task.blockedReason != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Blocked: ${task.blockedReason}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    if (task.carriedOverCount > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Carried over ${task.carriedOverCount}×',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.caution,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (!task.isCompleted && onFocus != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onFocus,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      task.status == TaskStatus.inProgress
                          ? Icons.play_circle_outline
                          : Icons.play_arrow_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.status == TaskStatus.inProgress ? 'OPEN' : 'START',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.accent,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(width: 6),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'EDIT',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 44,
            height: 44,
            child: PopupMenuButton<_TaskMenuAction>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: AppColors.textMuted,
              ),
              color: AppColors.surfaceVar,
              padding: EdgeInsets.zero,
              tooltip: 'Task actions',
              onSelected: (action) {
                switch (action) {
                  case _TaskMenuAction.edit:
                    onEdit();
                    break;
                  case _TaskMenuAction.focus:
                    onFocus?.call();
                    break;
                  case _TaskMenuAction.complete:
                    onComplete();
                    break;
                  case _TaskMenuAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _TaskMenuAction.edit,
                  child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
                ),
                if (!task.isCompleted && onFocus != null)
                  PopupMenuItem(
                    value: _TaskMenuAction.focus,
                    child: _MenuRow(
                      icon: Icons.play_arrow_rounded,
                      label: task.status == TaskStatus.inProgress
                          ? 'Open'
                          : 'Start',
                    ),
                  ),
                if (!task.isCompleted)
                  PopupMenuItem(
                    value: _TaskMenuAction.complete,
                    child: _MenuRow(
                      icon: Icons.check_circle_outline,
                      label: 'Mark done',
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _TaskMenuAction.delete,
                  child: _MenuRow(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_TaskTimeStatus? _timeStatus(TaskModel task, DateTime now) {
  if (!task.hasSchedule) return null;

  final start = task.scheduledStart!;
  final end = task.scheduledEnd!;
  if (now.isBefore(start)) {
    return _TaskTimeStatus(
      'Starts in ${_compactDuration(start.difference(now))}',
      AppColors.textMuted,
    );
  }
  if (now.isBefore(end)) {
    return _TaskTimeStatus(
      'Remaining ${_compactDuration(end.difference(now))}',
      AppColors.success,
    );
  }
  return _TaskTimeStatus(
    'Over by ${_compactDuration(now.difference(end))}',
    AppColors.warning,
  );
}

String _compactDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 1) return '${duration.inSeconds}s';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours <= 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

class _TaskTimeStatus {
  final String label;
  final Color color;

  const _TaskTimeStatus(this.label, this.color);
}

String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

enum _TaskMenuAction { edit, focus, complete, delete }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: effectiveColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.task_alt_outlined,
              color: AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No tasks yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap + to add what you need to do today',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
