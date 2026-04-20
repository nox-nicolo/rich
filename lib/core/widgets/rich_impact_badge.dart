// lib/core/widgets/rich_impact_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

enum ImpactLevel { high, medium, low, neutral }

extension ImpactLevelX on ImpactLevel {
  Color get color {
    switch (this) {
      case ImpactLevel.high:    return AppColors.impactHigh;
      case ImpactLevel.medium:  return AppColors.impactMedium;
      case ImpactLevel.low:     return AppColors.impactLow;
      case ImpactLevel.neutral: return AppColors.impactNeutral;
    }
  }

  String get label {
    switch (this) {
      case ImpactLevel.high:    return 'HIGH';
      case ImpactLevel.medium:  return 'MED';
      case ImpactLevel.low:     return 'LOW';
      case ImpactLevel.neutral: return '—';
    }
  }
}

class RichImpactBadge extends StatelessWidget {
  final ImpactLevel level;

  /// showLabel = true  → shows text label (HIGH / MED / LOW)
  /// showLabel = false → shows small colored dot only
  final bool showLabel;

  const RichImpactBadge({
    required this.level,
    this.showLabel = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = level.color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: showLabel
          ? Text(
              level.label,
              style: AppTypography.chip.copyWith(
                color: color,
                fontSize: 10,
              ),
            )
          : Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
    );
  }
}
