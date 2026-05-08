// lib/features/dashboard/view/widgets/next_action_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glossy_card.dart';

class NextActionWidget extends StatelessWidget {
  final String action;
  final String? route;
  const NextActionWidget({required this.action, this.route, super.key});

  @override
  Widget build(BuildContext context) {
    final tappable = route != null && route!.isNotEmpty;
    return GlossyCard(
      onTap:        tappable ? () => context.go(route!) : null,
      accentBorder: AppColors.accent,
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
          if (tappable)
            const Icon(
              Icons.arrow_forward_ios,
              size: AppSpacing.iconSm,
              color: AppColors.accent,
            ),
        ],
      ),
    );
  }
}
