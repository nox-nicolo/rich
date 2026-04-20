// lib/features/life/view/widgets/health_log_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/health_log_model.dart';
import '../../viewmodel/life_viewmodel.dart';

class HealthLogWidget extends ConsumerWidget {
  const HealthLogWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);
    final vm = ref.read(lifeViewModelProvider.notifier);
    final log = state.todayHealthLog;
    final hasSignals = log != null &&
        (log.sleepHours != null ||
            log.waterGlasses != null ||
            log.steps != null ||
            state.todayWorkouts.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'HEALTH LOG'),

        _EnergyBadge(
          level: log?.energyLevel ?? EnergyLevel.moderate,
          hasSignals: hasSignals,
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Sleep ─────────────────────────────────────────────────
        _MetricRow(
          icon: Icons.bedtime_outlined,
          label: 'SLEEP',
          value: log?.sleepHours != null
              ? '${log!.sleepHours}h'
              : '—',
          color: log != null && log.sleepHours != null
              ? (log.sleepHours! >= 7
                  ? AppColors.success
                  : AppColors.warning)
              : AppColors.textMuted,
          onTap: () => _showSliderSheet(
            context: context,
            label: 'SLEEP HOURS',
            min: 3,
            max: 12,
            initial: (log?.sleepHours ?? 7).toDouble(),
            onSave: (v) => vm.updateHealthLog(sleepHours: v.round()),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Water ─────────────────────────────────────────────────
        _MetricRow(
          icon: Icons.water_drop_outlined,
          label: 'WATER',
          value: log?.waterGlasses != null
              ? '${log!.waterGlasses} gl'
              : '—',
          color: log != null && log.waterGlasses != null
              ? (log.waterGlasses! >= 8
                  ? AppColors.success
                  : AppColors.caution)
              : AppColors.textMuted,
          onTap: () => _showSliderSheet(
            context: context,
            label: 'WATER GLASSES',
            min: 0,
            max: 15,
            initial: (log?.waterGlasses ?? 4).toDouble(),
            onSave: (v) =>
                vm.updateHealthLog(waterGlasses: v.round()),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Steps ─────────────────────────────────────────────────
        _MetricRow(
          icon: Icons.directions_walk_outlined,
          label: 'STEPS',
          value: log?.steps != null ? '${log!.steps}' : '—',
          color: log != null && log.steps != null
              ? (log.steps! >= 8000
                  ? AppColors.success
                  : AppColors.caution)
              : AppColors.textMuted,
          onTap: () => _showStepsSheet(context, vm, log?.steps),
        ),
      ],
    );
  }

  void _showSliderSheet({
    required BuildContext context,
    required String label,
    required double min,
    required double max,
    required double initial,
    required ValueChanged<double> onSave,
  }) {
    double value = initial;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(label, style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              Text(
                value.round().toString(),
                style: AppTypography.h1.copyWith(fontSize: 36),
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                activeColor: AppColors.accent,
                inactiveColor: AppColors.surfaceVar,
                onChanged: (v) => setState(() => value = v),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave(value);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'SAVE',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.background, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStepsSheet(
      BuildContext context, LifeViewModel vm, int? current) {
    final ctrl =
        TextEditingController(text: current?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('STEPS', style: AppTypography.label),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'e.g. 8500'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final steps = int.tryParse(ctrl.text.trim());
                  if (steps != null) {
                    vm.updateHealthLog(steps: steps);
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'SAVE',
                  style: AppTypography.h3.copyWith(
                      color: AppColors.background, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  final EnergyLevel level;
  final bool hasSignals;

  const _EnergyBadge({
    required this.level,
    required this.hasSignals,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasSignals ? _colorFor(level) : AppColors.textMuted;
    final label = hasSignals ? level.label.toUpperCase() : '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ENERGY', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Auto from sleep · water · steps · workout',
                style: AppTypography.caption,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: color, width: 0.5),
            ),
            child: Text(
              label,
              style: AppTypography.chip.copyWith(
                color: color,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.low:
        return AppColors.warning;
      case EnergyLevel.moderate:
        return AppColors.caution;
      case EnergyLevel.high:
        return AppColors.success;
      case EnergyLevel.peak:
        return AppColors.accent;
    }
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

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
            Icon(icon,
                size: AppSpacing.iconSm, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.body),
            const Spacer(),
            Text(
              value,
              style: AppTypography.mono.copyWith(color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.arrow_forward_ios,
                size: AppSpacing.iconSm,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
