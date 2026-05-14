// lib/feature/dashboard/view/widget/accountability_red_flags_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/services/accountability_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/tracking/tracking_feature.dart';

class AccountabilityRedFlagsWidget extends StatelessWidget {
  const AccountabilityRedFlagsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final flags = AccountabilityService.yesterdayRedFlags();
    if (flags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.warning,
                size: AppSpacing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'YESTERDAY RED FLAGS',
                style: AppTypography.label.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...flags.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key.label}: ${entry.value}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
