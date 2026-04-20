// lib/core/widgets/rich_status_dot.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

enum RichStatus {
  active,
  inactive,
  warning,
  locked,
  success,
}

extension RichStatusX on RichStatus {
  Color get color {
    switch (this) {
      case RichStatus.active:   return AppColors.success;
      case RichStatus.inactive: return AppColors.textMuted;
      case RichStatus.warning:  return AppColors.caution;
      case RichStatus.locked:   return AppColors.warning;
      case RichStatus.success:  return AppColors.success;
    }
  }
}

class RichStatusDot extends StatelessWidget {
  final RichStatus status;
  final String? label;
  final double size;

  const RichStatusDot({
    required this.status,
    this.label,
    this.size = 7,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status.color,
      ),
    );

    if (label == null) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          label!,
          style: AppTypography.caption
              .copyWith(color: status.color),
        ),
      ],
    );
  }
}
