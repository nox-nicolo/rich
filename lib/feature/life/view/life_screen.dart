// lib/features/life/view/life_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/life_viewmodel.dart';
import '../model/language_model.dart';        // ← SupportedLanguageX (flag, etc.)
import 'widget/habit_streak_widget.dart';
import 'widget/workout_tracker_widget.dart';
import 'widget/health_log_widget.dart';
import 'widget/recovery_mode_widget.dart';
import 'widget/language_widget.dart';   // ← NEW

class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  // ── LANGUAGE tab added as the 5th tab ─────────────────────────────────────
  static const _tabs = ['HABITS', 'WORKOUT', 'HEALTH', 'RECOVERY', 'LANGUAGE'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);
    final vm    = ref.read(lifeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LIFE',
          style: AppTypography.label.copyWith(
            color:         AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.isInRecovery)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _StatusChip(
                  label: 'RECOVERY', color: AppColors.success),
            ),
          if (state.hasActiveLanguage)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(
                label:
                    '${state.activeLanguage!.language.flag} ${state.activeLanguage!.progressPercent}%',
                color: AppColors.accent,
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 1))
          : Column(
              children: [
                _LifeTabBar(
                  tabs:     _tabs,
                  selected: state.activeTab,
                  onSelect: vm.setTab,
                ),
                Expanded(child: _tabContent(state.activeTab)),
              ],
            ),
    );
  }

  Widget _tabContent(String tab) {
    switch (tab) {
      case 'HABITS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: HabitStreakWidget(),
        );
      case 'WORKOUT':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: WorkoutTrackerWidget(),
        );
      case 'HEALTH':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: HealthLogWidget(),
        );
      case 'RECOVERY':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: RecoveryModeWidget(),
        );
      case 'LANGUAGE':                            // ← NEW
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LanguageWidget(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
// Now scrollable because 5 tabs overflow on narrow screens.

class _LifeTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _LifeTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = tab == selected;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              child: GestureDetector(
                onTap: () => onSelect(tab),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab,
                      style: AppTypography.label.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 1,
                      width: 20,
                      color: isSelected
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
            color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label,
          style: AppTypography.chip.copyWith(color: color)),
    );
  }
}