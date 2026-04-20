// lib/feature/milestones/view/widgets/milestone_dashboard_card.dart
//
// Compact always-visible summary on the dashboard so the user sees their
// long-term goals every day. Tap → Milestones screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../model/milestone.dart';
import '../../viewmodel/milestone_viewmodel.dart';

class MilestoneDashboardCard extends ConsumerWidget {
  const MilestoneDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(milestoneViewModelProvider);

    if (state.isLoading) return const SizedBox.shrink();

    final sixActive   = state.activeIn(Horizon.sixMonth).length;
    final yearActive  = state.activeIn(Horizon.yearly).length;
    final sixAtRisk   = state.atRiskCount(Horizon.sixMonth);
    final yearAtRisk  = state.atRiskCount(Horizon.yearly);
    final hasAny      = state.all.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push(RouteNames.milestones),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    color: AppColors.accent, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.md),
                Text('MILESTONES', style: AppTypography.label),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 12),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!hasAny)
              Text(
                'No milestones yet. Set 6-month or yearly goals to keep your eye on the long game.',
                style: AppTypography.body,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _HorizonStat(
                      label:  '6-MONTH',
                      active: sixActive,
                      atRisk: sixAtRisk,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _HorizonStat(
                      label:  'YEARLY',
                      active: yearActive,
                      atRisk: yearAtRisk,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HorizonStat extends StatelessWidget {
  final String label;
  final int active;
  final int atRisk;
  const _HorizonStat({
    required this.label,
    required this.active,
    required this.atRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$active',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  )),
              const SizedBox(width: 4),
              Text('active', style: AppTypography.caption),
            ],
          ),
          if (atRisk > 0)
            Text(
              '$atRisk at risk',
              style: AppTypography.caption
                  .copyWith(color: AppColors.caution),
            ),
        ],
      ),
    );
  }
}
