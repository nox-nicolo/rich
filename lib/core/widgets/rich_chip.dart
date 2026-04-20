// lib/core/widgets/rich_chip.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class RichChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  const RichChip({
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
    this.onTap,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color ??
        (selected ? AppColors.accent : AppColors.textSecondary);
    final bgColor = backgroundColor ??
        (selected
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surfaceVar);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? fgColor.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: fgColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.chip.copyWith(color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}
