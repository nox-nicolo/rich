// lib/core/widgets/rich_section_header.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class RichSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const RichSectionHeader({
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(title, style: AppTypography.label),
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
