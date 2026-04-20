// lib/features/work/view/widgets/work_review_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/task_model.dart';
import '../../viewmodel/work_viewmodel.dart';

class WorkReviewWidget extends ConsumerWidget {
  const WorkReviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workViewModelProvider);

    final completed = state.todayTasks
        .where((t) => t.isCompleted)
        .toList();
    final blocked = state.todayTasks
        .where((t) => t.isBlocked)
        .toList();
    final pending = state.todayTasks
        .where((t) =>
            t.status == TaskStatus.pending ||
            t.status == TaskStatus.inProgress)
        .toList();

    final totalMinutes = state.todaySessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'WORKDAY REVIEW'),

        // ── Summary stats ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'DONE',
                value: '${completed.length}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'PENDING',
                value: '${pending.length}',
                color: AppColors.caution,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'BLOCKED',
                value: '${blocked.length}',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'FOCUSED',
                value: '${totalMinutes}m',
                color: AppColors.accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Completed tasks ───────────────────────────────────────
        if (completed.isNotEmpty) ...[
          Text('COMPLETED', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...completed.map((t) => _ReviewTaskTile(
                task: t,
                color: AppColors.success,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Blocked tasks ─────────────────────────────────────────
        if (blocked.isNotEmpty) ...[
          Text('BLOCKED', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...blocked.map((t) => _ReviewTaskTile(
                task: t,
                color: AppColors.warning,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Shutdown prompt ───────────────────────────────────────
        _ShutdownCard(pendingCount: pending.length),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.h2.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }
}

class _ReviewTaskTile extends StatelessWidget {
  final TaskModel task;
  final Color color;

  const _ReviewTaskTile({required this.task, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (task.blockedReason != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.blockedReason!,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutdownCard extends StatelessWidget {
  final int pendingCount;

  const _ShutdownCard({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.power_settings_new_outlined,
                size: AppSpacing.iconSm,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'SHUTDOWN RITUAL',
                style: AppTypography.label
                    .copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pendingCount > 0
                ? 'You have $pendingCount pending tasks. Move or cancel them before shutting down.'
                : 'All tasks resolved. Close your loops and prepare for tomorrow.',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
}
