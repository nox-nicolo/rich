// lib/feature/milestones/view/widgets/milestone_tile.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/milestone.dart';

class MilestoneTile extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onTap;

  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.onTap,
  });

  Color get _accent {
    if (milestone.status == MilestoneStatus.done) return AppColors.success;
    if (milestone.status == MilestoneStatus.dropped) return AppColors.textMuted;
    if (milestone.isOverdue) return AppColors.warning;
    if (milestone.isAtRisk) return AppColors.caution;
    return AppColors.accent;
  }

  String get _badge {
    switch (milestone.status) {
      case MilestoneStatus.done:    return 'DONE';
      case MilestoneStatus.dropped: return 'DROPPED';
      case MilestoneStatus.active:
        if (milestone.isOverdue) return 'OVERDUE';
        if (milestone.isAtRisk)  return 'AT RISK';
        return 'ON TRACK';
    }
  }

  String get _dueLabel {
    final now = DateTime.now();
    final diff = milestone.targetDate.difference(now);
    if (milestone.status != MilestoneStatus.active) {
      return 'Target: ${_fmt(milestone.targetDate)}';
    }
    if (diff.inDays < 0) return 'Overdue by ${-diff.inDays}d';
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays < 60) return 'In ${diff.inDays}d';
    final months = (diff.inDays / 30).round();
    return 'In ${months}mo';
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final pct = (milestone.progress * 100).round();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _accent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    milestone.title,
                    style: AppTypography.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(_badge, style: AppTypography.label.copyWith(color: _accent)),
              ],
            ),
            if (milestone.note != null && milestone.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                milestone.note!,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: milestone.progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.elevated,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$pct%',
                    style: AppTypography.mono.copyWith(fontSize: 11)),
                Text(_dueLabel,
                    style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
