// lib/features/dashboard/view/widgets/pillar_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/pillar_summary_model.dart';
import '../../viewmodel/dashboard_viewmodel.dart';

class PillarGridWidget extends ConsumerWidget {
  const PillarGridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pillars = ref.watch(pillarSummariesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'COMMAND CENTER'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing:  AppSpacing.sm,
            childAspectRatio: 1.6,
          ),
          itemCount: pillars.length,
          itemBuilder: (context, i) => _PillarCard(
            pillar: pillars[i],
            onTap:  pillars[i].isLocked ? null : () => context.go(pillars[i].route),
          ),
        ),
      ],
    );
  }
}

class _PillarCard extends StatelessWidget {
  final PillarSummary pillar;
  final VoidCallback? onTap;

  const _PillarCard({required this.pillar, required this.onTap});

  Color get _borderColor {
    switch (pillar.status) {
      case PillarStatus.locked:    return AppColors.lockedBorder;
      case PillarStatus.active:    return AppColors.accent.withValues(alpha: 0.3);
      case PillarStatus.completed: return AppColors.success.withValues(alpha: 0.3);
      case PillarStatus.warning:   return AppColors.warning.withValues(alpha: 0.3);
      default:                     return AppColors.border;
    }
  }

  Color get _bgColor {
    switch (pillar.status) {
      case PillarStatus.locked:    return AppColors.locked;
      case PillarStatus.active:    return AppColors.surface;
      case PillarStatus.completed: return AppColors.surface;
      default:                     return AppColors.surface;
    }
  }

  Color get _labelColor {
    switch (pillar.status) {
      case PillarStatus.locked: return AppColors.textDisabled;
      default:                  return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // null = no-op when locked
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: _borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // ── Icon row ────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  pillar.isLocked
                      ? Icons.lock_outline
                      : _iconFor(pillar),
                  size: AppSpacing.iconSm,
                  color: pillar.isLocked
                      ? AppColors.textDisabled
                      : AppColors.textSecondary,
                ),
                const Spacer(),
                _StatusBadge(pillar: pillar),
              ],
            ),

            // ── Labels ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pillar.label,
                  style: AppTypography.h3.copyWith(
                    color: _labelColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pillar.statusDetail ?? pillar.sublabel,
                  style: AppTypography.caption.copyWith(
                    color: pillar.isLocked
                        ? AppColors.textDisabled
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PillarSummary p) {
    switch (p.feature.name) {
      case 'meditation': return Icons.self_improvement_outlined;
      case 'work':       return Icons.work_outline;
      case 'life':       return Icons.favorite_border;
      case 'trading':    return Icons.show_chart_outlined;
      case 'betting':    return Icons.sports_soccer_outlined;
      case 'reading':    return Icons.auto_stories_outlined;
      case 'writing':    return Icons.edit_note_outlined;
      default:           return Icons.circle_outlined;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final PillarSummary pillar;
  const _StatusBadge({required this.pillar});

  @override
  Widget build(BuildContext context) {
    switch (pillar.status) {
      case PillarStatus.locked:
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Text(
            'LOCKED',
            style: AppTypography.chip.copyWith(
                color: AppColors.warning, fontSize: 9),
          ),
        );

      case PillarStatus.completed:
        return const Icon(Icons.check_circle_outline,
            size: 14, color: AppColors.success);

      case PillarStatus.active:
        return Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
