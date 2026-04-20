// lib/features/life/view/widgets/workout_tracker_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/workout_model.dart';
import '../../viewmodel/life_viewmodel.dart';

class WorkoutTrackerWidget extends ConsumerWidget {
  const WorkoutTrackerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);
    final vm = ref.read(lifeViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'WORKOUT',
          trailing: GestureDetector(
            onTap: () => _showLogWorkoutSheet(context, vm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.add,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (!state.hasWorkedOutToday)
          _NoWorkoutCard(onLog: () => _showLogWorkoutSheet(context, vm))
        else
          ...state.todayWorkouts.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _WorkoutTile(workout: w),
            ),
          ),
      ],
    );
  }

  void _showLogWorkoutSheet(BuildContext context, LifeViewModel vm) {
    WorkoutType type = WorkoutType.strength;
    WorkoutIntensity intensity = WorkoutIntensity.moderate;
    int duration = 45;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
              Text('LOG WORKOUT', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              Text('TYPE', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: WorkoutType.values.map((t) {
                    final isSelected = t == type;
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            t.label,
                            style: AppTypography.chip.copyWith(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('INTENSITY', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: WorkoutIntensity.values.map((i) {
                  final isSelected = i == intensity;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => intensity = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              i.label,
                              style: AppTypography.chip.copyWith(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesCtrl,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Notes (optional)...'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    vm.logWorkout(
                      type: type,
                      intensity: intensity,
                      durationMinutes: duration,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'LOG',
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
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutModel workout;

  const _WorkoutTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final h =
        workout.completedAt.hour.toString().padLeft(2, '0');
    final m =
        workout.completedAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center_outlined,
              size: AppSpacing.iconSm, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.type.label,
                  style: AppTypography.h3.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${workout.intensity.label} · ${workout.durationMinutes}min',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Text('$h:$m', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _NoWorkoutCard extends StatelessWidget {
  final VoidCallback onLog;

  const _NoWorkoutCard({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLog,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.fitness_center_outlined,
                size: AppSpacing.iconSm,
                color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No workout logged today',
                      style: AppTypography.h3
                          .copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Tap to log your session',
                      style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: AppSpacing.iconSm,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
