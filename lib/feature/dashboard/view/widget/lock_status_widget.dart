// lib/features/dashboard/view/widgets/lock_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../../../providers/providers.dart';

class LockStatusWidget extends ConsumerWidget {
  const LockStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedFeatures = ref.watch(lockedFeaturesProvider);
    final ruleResults    = ref.watch(activeRuleResultsProvider);

    if (lockedFeatures.isEmpty && ruleResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const RichSectionHeader(title: 'ACTIVE LOCKS'),

        // ── Locked features ───────────────────────────────────────────
        ...lockedFeatures.map(
          (feature) => _LockTile(
            label:  feature.label.toUpperCase(),
            reason: _reasonFor(feature, ref),
          ),
        ),

        // ── Active rule warnings ──────────────────────────────────────
        if (ruleResults.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...ruleResults.map(
            (r) => _WarningTile(message: r.reason ?? r.ruleId),
          ),
        ],
      ],
    );
  }

  String _reasonFor(RichFeature feature, WidgetRef ref) {
    final engine  = ref.read(ruleEngineServiceProvider);
    final ruleCtx = ref.read(ruleContextProvider);
    return engine.lockReason(feature, ruleCtx);
  }
}

class _LockTile extends StatelessWidget {
  final String label;
  final String reason;

  const _LockTile({required this.label, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlossyCard(
        padding:      const EdgeInsets.all(AppSpacing.md),
        radius:       AppSpacing.radiusMd,
        accentBorder: AppColors.warning,
        accentTint:   AppColors.warning,
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: AppSpacing.iconSm,
                color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.chip
                          .copyWith(color: AppColors.warning)),
                  const SizedBox(height: 2),
                  Text(reason, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  final String message;
  const _WarningTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: GlossyCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        radius:       AppSpacing.radiusMd,
        accentBorder: AppColors.caution,
        accentTint:   AppColors.caution,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: AppSpacing.iconSm,
                color: AppColors.caution),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
