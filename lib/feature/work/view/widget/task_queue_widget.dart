// lib/features/work/view/widgets/task_queue_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/task_model.dart';
import '../../viewmodel/work_viewmodel.dart';

class TaskQueueWidget extends ConsumerWidget {
  const TaskQueueWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workViewModelProvider);
    final vm    = ref.read(workViewModelProvider.notifier);

    final pending   = state.todayTasks.where((t) => !t.isCompleted).toList();
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
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        if (state.todayTasks.isEmpty)
          _EmptyState()
        else ...[
          // pending tasks
          ...pending.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TaskTile(
              task:       task,
              onComplete: () => vm.completeTask(task.id),
              onDelete:   () => vm.deleteTask(task.id),
              onFocus:    task.hasSchedule
                  ? () => context.go('/work/focus/${task.id}')
                  : null,
            ),
          )),

          // completed tasks (collapsed section)
          if (completed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('DONE (${completed.length})',
                style: AppTypography.label.copyWith(
                    color: AppColors.textMuted, fontSize: 9)),
            const SizedBox(height: AppSpacing.xs),
            ...completed.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _TaskTile(
                task:       task,
                onComplete: () {},
                onDelete:   () => vm.deleteTask(task.id),
                onFocus:    null,
              ),
            )),
          ],
        ],
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context, WorkViewModel vm) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    TaskPriority intensity = TaskPriority.medium;

    final now = DateTime.now();
    TimeOfDay start = TimeOfDay(
      hour: now.add(const Duration(minutes: 1)).hour,
      minute: now.add(const Duration(minutes: 1)).minute,
    );
    TimeOfDay end = TimeOfDay(
      hour: now.add(const Duration(minutes: 31)).hour,
      minute: now.add(const Duration(minutes: 31)).minute,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 3,
                  decoration: BoxDecoration(color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('ADD TASK', style: AppTypography.label),
              const SizedBox(height: 12),

              // Title
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'What needs to be done?'),
              ),
              const SizedBox(height: 10),

              // Notes
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                    hintText: 'Notes (optional)...'),
              ),
              const SizedBox(height: 14),

              // Time slot
              Text('TIME',
                  style: AppTypography.chip
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: 'START',
                      time: start,
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: ctx, initialTime: start);
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
                            context: ctx, initialTime: end);
                        if (picked != null) setState(() => end = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Intensity selector
              Text('INTENSITY',
                  style: AppTypography.chip
                      .copyWith(color: AppColors.textMuted)),
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
                            child: Text(p.label,
                                style: AppTypography.chip.copyWith(
                                  color: isSelected
                                      ? color
                                      : AppColors.textMuted,
                                  fontSize: 9,
                                )),
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
                        Duration(hours: start.hour, minutes: start.minute));
                    var endDt = base.add(
                        Duration(hours: end.hour, minutes: end.minute));
                    // If end <= start, treat end as next day at that time
                    if (!endDt.isAfter(startDt)) {
                      endDt = endDt.add(const Duration(days: 1));
                    }
                    vm.addTask(
                      title:          titleCtrl.text.trim(),
                      description:    notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      priority:       intensity,
                      scheduledStart: startDt,
                      scheduledEnd:   endDt,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('ADD TASK',
                      style: AppTypography.h3
                          .copyWith(color: AppColors.background, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  const _TimeChip({required this.label, required this.time, required this.onTap});

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
            Text(label,
                style: AppTypography.chip
                    .copyWith(color: AppColors.textMuted, fontSize: 9)),
            Text(_formatTOD(time),
                style: AppTypography.mono.copyWith(
                    color: AppColors.textPrimary, fontSize: 13)),
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
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback? onFocus;

  const _TaskTile({
    required this.task,
    required this.onComplete,
    required this.onDelete,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final color = _intensityColor(task.priority);

    return GestureDetector(
      onTap: onFocus,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion circle
            GestureDetector(
              onTap: task.isCompleted ? null : onComplete,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted ? AppColors.success : AppColors.border,
                    width: 1,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 12, color: AppColors.success)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Intensity bar
            Container(
              width: 3,
              height: task.description != null ? 44 : 28,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.border
                    : color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Intensity badge (only for pending)
                      if (!task.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(task.priority.label,
                              style: AppTypography.chip.copyWith(
                                  color: color, fontSize: 8)),
                        ),
                    ],
                  ),
                  if (task.description != null && !task.isCompleted) ...[
                    const SizedBox(height: 3),
                    Text(task.description!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMuted)),
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
                              : AppColors.success),
                    ),
                  ],
                  if (task.isBlocked && task.blockedReason != null) ...[
                    const SizedBox(height: 3),
                    Text('Blocked: ${task.blockedReason}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.warning)),
                  ],
                ],
              ),
            ),

            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm, top: 2),
                child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.task_alt_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No tasks yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Tap + to add what you need to do today',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
