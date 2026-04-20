// lib/features/meditation/view/widgets/streak_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/meditation_streak_model.dart';

class StreakWidget extends StatelessWidget {
  final MeditationStreak streak;

  const StreakWidget({required this.streak, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: streak.streakAtRisk
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streak.streakAtRisk)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Streak at risk — meditate today',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _StatCol(
                  label: 'STREAK',
                  value: '${streak.currentStreak}',
                  unit: 'd',
                  highlight: true,
                ),
              ),
              Container(width: 0.5, height: 36, color: AppColors.divider),
              Expanded(
                child: _StatCol(
                  label: 'BEST',
                  value: '${streak.longestStreak}',
                  unit: 'd',
                ),
              ),
              Container(width: 0.5, height: 36, color: AppColors.divider),
              Expanded(
                child: _StatCol(
                  label: 'TOTAL',
                  value: '${streak.totalSessions}',
                  unit: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  const _StatCol({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTypography.h1.copyWith(
                color: highlight ? AppColors.accent : AppColors.textPrimary,
                fontSize: 26,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: AppTypography.caption),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
