// lib/features/life/view/widgets/habit_streak_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/habit_model.dart';
import '../../viewmodel/life_viewmodel.dart';

class HabitStreakWidget extends ConsumerWidget {
  const HabitStreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);
    final vm = ref.read(lifeViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'HABITS',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.completedHabitsToday}/${state.habits.length}',
                style: AppTypography.mono.copyWith(fontSize: 12),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _showAddHabitSheet(context, vm),
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
            ],
          ),
        ),
        if (state.habits.isEmpty)
          _EmptyState()
        else
          ...state.habits.map(
            (habit) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HabitTile(
                habit: habit,
                onComplete: () => vm.completeHabit(habit.id),
                onDelete: () => vm.deleteHabit(habit.id),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddHabitSheet(BuildContext context, LifeViewModel vm) {
    final nameCtrl = TextEditingController();
    HabitCategory category = HabitCategory.health;

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
              Text('ADD HABIT', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Habit name...'),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: HabitCategory.values.map((c) {
                  final isSelected = c == category;
                  return GestureDetector(
                    onTap: () => setState(() => category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
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
                        c.label,
                        style: AppTypography.chip.copyWith(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      vm.addHabit(
                        name: nameCtrl.text.trim(),
                        category: category,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    'ADD',
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

class _HabitTile extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _HabitTile({
    required this.habit,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: habit.completedToday
              ? AppColors.success.withValues(alpha: 0.3)
              : habit.streakAtRisk
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: habit.completedToday ? null : onComplete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.completedToday
                    ? AppColors.success.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: habit.completedToday
                      ? AppColors.success
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: habit.completedToday
                  ? const Icon(Icons.check,
                      size: 12, color: AppColors.success)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTypography.h3.copyWith(
                    fontSize: 13,
                    color: habit.completedToday
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      habit.category.label,
                      style: AppTypography.caption,
                    ),
                    if (habit.currentStreak > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${habit.currentStreak}d streak',
                        style: AppTypography.caption.copyWith(
                          color: habit.streakAtRisk
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(Icons.close,
                  size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.repeat_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No habits yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Build your daily discipline stack',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
