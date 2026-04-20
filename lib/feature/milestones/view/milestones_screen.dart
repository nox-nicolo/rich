// lib/feature/milestones/view/milestones_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/milestone.dart';
import '../viewmodel/milestone_viewmodel.dart';
import 'pages/add_milestone_page.dart';
import 'widgets/milestone_tile.dart';

class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  void _openAdd(BuildContext context, {Milestone? existing}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMilestonePage(existing: existing),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(milestoneViewModelProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 1),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('MILESTONES',
            style: AppTypography.label.copyWith(fontSize: 12)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: AppSpacing.iconSm, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add,
                color: AppColors.accent, size: AppSpacing.iconMd),
            onPressed: () => _openAdd(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _HorizonSection(
            horizon: Horizon.sixMonth,
            items:   state.sixMonth,
            active:  state.activeIn(Horizon.sixMonth).length,
            atRisk:  state.atRiskCount(Horizon.sixMonth),
            onAdd:   () => _openAdd(context),
            onTap:   (m) => _openAdd(context, existing: m),
          ),
          const SizedBox(height: AppSpacing.xl),
          _HorizonSection(
            horizon: Horizon.yearly,
            items:   state.yearly,
            active:  state.activeIn(Horizon.yearly).length,
            atRisk:  state.atRiskCount(Horizon.yearly),
            onAdd:   () => _openAdd(context),
            onTap:   (m) => _openAdd(context, existing: m),
          ),
          const SizedBox(height: AppSpacing.x3l),
        ],
      ),
    );
  }
}

class _HorizonSection extends StatelessWidget {
  final Horizon horizon;
  final List<Milestone> items;
  final int active;
  final int atRisk;
  final VoidCallback onAdd;
  final ValueChanged<Milestone> onTap;

  const _HorizonSection({
    required this.horizon,
    required this.items,
    required this.active,
    required this.atRisk,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HorizonHeader(
          horizon: horizon,
          active:  active,
          atRisk:  atRisk,
          total:   items.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          _EmptyTile(horizon: horizon, onTap: onAdd)
        else
          ...items.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: MilestoneTile(
                  milestone: m,
                  onTap: () => onTap(m),
                ),
              )),
      ],
    );
  }
}

class _HorizonHeader extends StatelessWidget {
  final Horizon horizon;
  final int active;
  final int atRisk;
  final int total;

  const _HorizonHeader({
    required this.horizon,
    required this.active,
    required this.atRisk,
    required this.total,
  });

  String get _title => horizon == Horizon.sixMonth ? '6-MONTH' : 'YEARLY';

  @override
  Widget build(BuildContext context) {
    final period = periodLabelFor(horizon);
    final daysLeft =
        defaultTargetFor(horizon).difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad,
        vertical:   AppSpacing.md,
      ),
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
              Text(_title,
                  style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text(period,
                  style: AppTypography.mono.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _Chip(
                label: '$active ACTIVE',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              if (atRisk > 0)
                _Chip(
                  label: '$atRisk AT RISK',
                  color: AppColors.caution,
                ),
              const Spacer(),
              Text(
                daysLeft >= 0
                    ? '${daysLeft}d left'
                    : 'Period closed',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical:   2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final Horizon horizon;
  final VoidCallback onTap;
  const _EmptyTile({required this.horizon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.add,
                color: AppColors.textMuted, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                horizon == Horizon.sixMonth
                    ? 'Add a goal for this half'
                    : 'Add a goal for this year',
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
