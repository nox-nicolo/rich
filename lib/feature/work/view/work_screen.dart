// lib/features/work/view/work_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/work_viewmodel.dart';
import 'widget/task_queue_widget.dart';
import 'widget/focus_block_widget.dart';
import 'widget/meeting_prep_widget.dart';
import 'widget/work_review_widget.dart';

class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});

  static const _tabs = ['TASKS', 'FOCUS', 'MEETINGS', 'REVIEW'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'WORK',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.isDeepWorkActive)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(
                label: 'DEEP WORK',
                color: AppColors.accent,
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 1,
              ),
            )
          : Column(
              children: [
                _WorkTabBar(
                  tabs: _tabs,
                  selected: state.activeTab,
                  onSelect: ref
                      .read(workViewModelProvider.notifier)
                      .setTab,
                ),
                Expanded(
                  child: _tabContent(state.activeTab),
                ),
              ],
            ),
    );
  }

  Widget _tabContent(String tab) {
    switch (tab) {
      case 'TASKS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: TaskQueueWidget(),
        );
      case 'FOCUS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: FocusBlockWidget(),
        );
      case 'MEETINGS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: MeetingPrepWidget(),
        );
      case 'REVIEW':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: WorkReviewWidget(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WorkTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _WorkTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(color: color),
      ),
    );
  }
}
