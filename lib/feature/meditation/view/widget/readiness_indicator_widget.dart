// lib/features/meditation/view/widgets/readiness_indicator_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class ReadinessIndicatorWidget extends StatelessWidget {
  final bool completedToday;

  const ReadinessIndicatorWidget({
    required this.completedToday,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        completedToday ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completedToday
                ? Icons.lock_open_outlined
                : Icons.lock_outline,
            size: AppSpacing.iconMd,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completedToday
                      ? 'TRADING GATE OPEN'
                      : 'TRADING GATE LOCKED',
                  style: AppTypography.label.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  completedToday
                      ? 'Meditation complete. Trading is now accessible.'
                      : 'Complete Prayer, Breathing, or Stillness to unlock Trading.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (!completedToday)
            const Icon(
              Icons.arrow_forward_ios,
              size: AppSpacing.iconSm,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
