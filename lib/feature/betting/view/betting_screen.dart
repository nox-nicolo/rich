// lib/features/betting/view/betting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/betting_viewmodel.dart';
import 'widget/bankroll_widget.dart';
import 'widget/running_count_widget.dart';
import 'widget/slip_review_widget.dart';
import 'widget/lockdown_widget.dart';
import 'widget/cooldown_timer_widget.dart';
import 'widget/betting_plan_widget.dart';
import 'widget/betting_history_widget.dart';
import 'widget/sport_news_widget.dart';

class BettingScreen extends ConsumerWidget {
  const BettingScreen({super.key});

  static const _tabs = ['OVERVIEW', 'PLAN', 'BETS', 'NEWS', 'HISTORY', 'SLIP', 'LOCKDOWN'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bettingViewModelProvider);
    final vm = ref.read(bettingViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'BETTING',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.isLocked)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(
                label: 'LOCKED',
                color: AppColors.warning,
              ),
            )
          else if (state.activeBets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(
                label: '${state.activeBets.length} ACTIVE',
                color: AppColors.caution,
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
                // Cooldown timer always visible if active
                if (state.lockdown.cooldownActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: const CooldownTimerWidget(),
                  ),
                _BettingTabBar(
                  tabs: _tabs,
                  selected: state.activeTab,
                  onSelect: vm.setTab,
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
      case 'OVERVIEW':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: BankrollWidget(),
        );
      case 'PLAN':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: BettingPlanWidget(),
        );
      case 'BETS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: RunningCountWidget(),
        );
      case 'NEWS':
        // No outer padding/scroll wrapper — SportNewsWidget owns its own
        // header (sport selector) + RefreshIndicator-pull-to-reload list.
        return const Padding(
          padding: EdgeInsets.only(top: AppSpacing.md),
          child: SportNewsWidget(),
        );
      case 'HISTORY':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: BettingHistoryWidget(),
        );
      case 'SLIP':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SlipReviewWidget(),
        );
      case 'LOCKDOWN':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LockdownWidget(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BettingTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _BettingTabBar({
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
          return Expanded(
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
                    textAlign: TextAlign.center,
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
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(color: color),
      ),
    );
  }
}
