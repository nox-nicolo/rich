// lib/features/dashboard/view/widgets/routine_progress_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/dashboard_state_model.dart';

class RoutineProgressWidget extends StatelessWidget {
  final DashboardState state;

  const RoutineProgressWidget({
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final completed = state.completedRoutines;
    final total     = state.totalRoutines;
    final rate      = state.routineCompletionRate;

    return GlossyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          RichSectionHeader(
            title: "TODAY'S ROUTINE",
            trailing: Text(
              '$completed / $total',
              style: AppTypography.mono.copyWith(fontSize: 12),
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.surfaceVar,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 1.0 ? AppColors.success : AppColors.accent,
              ),
              minHeight: 3,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Routine pills (read-only — auto-tracked by modules) ──────────
          if (state.routineProgress.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs + 2,
              children: state.routineProgress.entries
                  .map((entry) => _RoutinePill(
                        name: entry.key,
                        done: entry.value,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RoutinePill extends StatelessWidget {
  final String name;
  final bool done;

  const _RoutinePill({
    required this.name,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceVar,
        borderRadius:
            BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check,
                size: 10, color: AppColors.success),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            name,
            style: AppTypography.chip.copyWith(
              color: done
                  ? AppColors.success
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
