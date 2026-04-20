// lib/features/dashboard/view/widgets/next_action_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class NextActionWidget extends StatelessWidget {
  final String action;
  final String? route;
  const NextActionWidget({required this.action, this.route, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route != null && route!.isNotEmpty
          ? () => context.go(route!)
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [

            // ── Left accent bar ────────────────────────────────────────────
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // ── Text ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT ACTION', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  Text(action, style: AppTypography.h3),
                ],
              ),
            ),

            if (route != null && route!.isNotEmpty)
              const Icon(
                Icons.arrow_forward_ios,
                size: AppSpacing.iconSm,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
