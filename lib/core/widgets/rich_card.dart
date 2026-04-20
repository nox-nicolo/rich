// lib/core/widgets/rich_card.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class RichCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? borderRadius;

  const RichCard({
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ??
            const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppSpacing.radiusLg,
          ),
          border: Border.all(
            color: borderColor ?? AppColors.border,
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
