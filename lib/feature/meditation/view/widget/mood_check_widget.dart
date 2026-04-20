// lib/features/meditation/view/widgets/mood_check_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/meditation_session_model.dart';

class MoodCheckWidget extends StatelessWidget {
  final MoodLevel selected;
  final ValueChanged<MoodLevel> onSelect;

  const MoodCheckWidget({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW ARE YOU RIGHT NOW', style: AppTypography.label),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MoodLevel.values
              .map((mood) => _MoodButton(
                    mood: mood,
                    isSelected: mood == selected,
                    onTap: () => onSelect(mood),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  final MoodLevel mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mood) {
      case MoodLevel.veryLow:
        return Icons.sentiment_very_dissatisfied_outlined;
      case MoodLevel.low:
        return Icons.sentiment_dissatisfied_outlined;
      case MoodLevel.neutral:
        return Icons.sentiment_neutral_outlined;
      case MoodLevel.good:
        return Icons.sentiment_satisfied_outlined;
      case MoodLevel.excellent:
        return Icons.sentiment_very_satisfied_outlined;
    }
  }

  Color get _color {
    if (!isSelected) return AppColors.textMuted;
    switch (mood) {
      case MoodLevel.veryLow:
      case MoodLevel.low:
        return AppColors.warning;
      case MoodLevel.neutral:
        return AppColors.caution;
      case MoodLevel.good:
      case MoodLevel.excellent:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? _color.withValues(alpha: 0.1)
                  : AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? _color : AppColors.border,
                width: isSelected ? 1.0 : 0.5,
              ),
            ),
            child: Icon(_icon, size: AppSpacing.iconLg, color: _color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mood.shortLabel,
            style: AppTypography.caption.copyWith(
              color: isSelected ? _color : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
