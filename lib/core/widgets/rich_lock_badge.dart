// lib/core/widgets/rich_lock_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class RichLockBadge extends StatelessWidget {
  final String? reason;
  final String? unlockHint;

  /// compact = small inline badge
  /// full    = expanded card with reason + hint
  final bool compact;

  const RichLockBadge({
    this.reason,
    this.unlockHint,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _CompactBadge() : _FullBadge(
      reason:     reason,
      unlockHint: unlockHint,
    );
  }
}

class _CompactBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline,
              size: 10, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'LOCKED',
            style: AppTypography.chip.copyWith(
              color: AppColors.warning,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullBadge extends StatelessWidget {
  final String? reason;
  final String? unlockHint;

  const _FullBadge({this.reason, this.unlockHint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: AppSpacing.iconSm,
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'LOCKED',
                style: AppTypography.label
                    .copyWith(color: AppColors.warning),
              ),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(reason!, style: AppTypography.body),
          ],
          if (unlockHint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              unlockHint!,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
