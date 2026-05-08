// lib/feature/milestones/view/widgets/milestone_dashboard_card.dart
//
// Premium glossy card on the dashboard. Switches between 6-month and yearly
// horizons with a top toggle and shows actual milestones (title + progress
// bar + date + status) instead of just counts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../model/milestone.dart';
import '../../viewmodel/milestone_viewmodel.dart';

class MilestoneDashboardCard extends ConsumerStatefulWidget {
  const MilestoneDashboardCard({super.key});

  @override
  ConsumerState<MilestoneDashboardCard> createState() =>
      _MilestoneDashboardCardState();
}

class _MilestoneDashboardCardState
    extends ConsumerState<MilestoneDashboardCard> {
  Horizon _horizon = Horizon.sixMonth;
  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(milestoneViewModelProvider);
    if (state.isLoading) return const SizedBox.shrink();

    final hasAny = state.all.isNotEmpty;
    final sixActive = state.activeIn(Horizon.sixMonth).length;
    final yearActive = state.activeIn(Horizon.yearly).length;

    // Sort milestones for the selected horizon: overdue/at-risk first, then
    // by lowest progress so the most urgent items are at the top.
    final list = [...state.activeIn(_horizon)]
      ..sort((a, b) {
        int rank(Milestone m) {
          if (m.isOverdue) return 0;
          if (m.isAtRisk) return 1;
          return 2;
        }

        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return a.progress.compareTo(b.progress);
      });

    final visible = list.take(_maxVisible).toList();
    final remaining = list.length - visible.length;

    return GlossyCard(
      onTap: () => context.push(RouteNames.milestones),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(period: periodLabelFor(_horizon)),
          const SizedBox(height: AppSpacing.md),
          _HorizonToggle(
            horizon: _horizon,
            sixCount: sixActive,
            yearCount: yearActive,
            onChanged: (h) => setState(() => _horizon = h),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hasAny)
            _EmptyState()
          else if (visible.isEmpty)
            _EmptyHorizon(horizon: _horizon)
          else ...[
            ...List.generate(visible.length, (i) {
              final m = visible[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == visible.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: _MilestoneRow(milestone: m),
              );
            }),
            if (remaining > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _ViewAllLink(remaining: remaining),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Header row ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String period;
  const _Header({required this.period});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.18),
                AppColors.accent.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: AppColors.accent,
            size: 14,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'MILESTONES',
          style: AppTypography.label.copyWith(letterSpacing: 2.5),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            period,
            style: AppTypography.chip.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textMuted,
          size: 11,
        ),
      ],
    );
  }
}

// ── Horizon toggle ────────────────────────────────────────────────────────────

class _HorizonToggle extends StatelessWidget {
  final Horizon horizon;
  final int sixCount;
  final int yearCount;
  final ValueChanged<Horizon> onChanged;

  const _HorizonToggle({
    required this.horizon,
    required this.sixCount,
    required this.yearCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: '6-MONTH',
              count: sixCount,
              selected: horizon == Horizon.sixMonth,
              onTap: () => onChanged(Horizon.sixMonth),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'YEARLY',
              count: yearCount,
              selected: horizon == Horizon.yearly,
              onTap: () => onChanged(Horizon.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.elevated, AppColors.surfaceVar],
                )
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: selected
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  width: 0.5,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '$count',
                style: AppTypography.mono.copyWith(
                  fontSize: 10,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single milestone row ──────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final Milestone milestone;
  const _MilestoneRow({required this.milestone});

  Color get _accentColor {
    if (milestone.isOverdue) return AppColors.warning;
    if (milestone.isAtRisk) return AppColors.caution;
    if (milestone.progress >= 0.85) return AppColors.success;
    return AppColors.accent;
  }

  String get _statusText {
    if (milestone.isOverdue) return 'OVERDUE';
    if (milestone.isAtRisk) return 'AT RISK';
    return 'ON TRACK';
  }

  String get _targetLabel {
    final d = milestone.targetDate;
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[d.month]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = milestone.progress.clamp(0.0, 1.0);
    final color = _accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.elevated.withValues(alpha: 0.65),
            AppColors.surface.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: milestone.isOverdue || milestone.isAtRisk
              ? color.withValues(alpha: 0.25)
              : AppColors.border.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + percent
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: AppTypography.mono.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (milestone.processSteps.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 11,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    milestone.processSteps.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (milestone.processSteps.length > 1) ...[
                  const SizedBox(width: 5),
                  Text(
                    '+${milestone.processSteps.length - 1}',
                    style: AppTypography.mono.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ],
          // Progress bar with gradient fill
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: AppColors.background.withValues(alpha: 0.7),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [color.withValues(alpha: 0.55), color],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Footer: status dot + target date
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _statusText,
                style: AppTypography.chip.copyWith(
                  fontSize: 9,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_today_outlined,
                size: 10,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                _targetLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── View-all footer ───────────────────────────────────────────────────────────

class _ViewAllLink extends StatelessWidget {
  final int remaining;
  const _ViewAllLink({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '+$remaining more',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: AppColors.border),
          const SizedBox(width: 6),
          Text(
            'VIEW ALL',
            style: AppTypography.chip.copyWith(
              color: AppColors.accent,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_forward, size: 10, color: AppColors.accent),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        'No milestones yet. Set 6-month or yearly goals to keep your eye on the long game.',
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _EmptyHorizon extends StatelessWidget {
  final Horizon horizon;
  const _EmptyHorizon({required this.horizon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          const Icon(
            Icons.add_circle_outline,
            color: AppColors.textMuted,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No active ${horizon.label.toLowerCase()} milestones',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
