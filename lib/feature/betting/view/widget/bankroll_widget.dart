// lib/features/betting/view/widgets/bankroll_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/bankroll_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

class BankrollWidget extends ConsumerWidget {
  const BankrollWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(bettingViewModelProvider);
    final bankroll = state.bankroll;

    // No capital set yet — show setup prompt
    if (bankroll.startingBalance == 0) {
      return _SetupCapitalCard(onTap: () => _showCapitalSheet(context, ref));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'BANKROLL',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showCapitalSheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text('ADD CAPITAL',
                      style: AppTypography.chip
                          .copyWith(color: AppColors.accent, fontSize: 10)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showRulesSheet(context, ref, bankroll),
                child: const Icon(Icons.tune_outlined,
                    size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
        ),

        // ── Balance card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: bankroll.isAtDailyStopLimit
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'BALANCE',
                      value: _tzs(bankroll.currentBalance),
                      color: AppColors.accent,
                      large: true,
                    ),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      label: 'P&L',
                      value: '${bankroll.isInProfit ? '+' : ''}${_tzs(bankroll.profitLoss)}',
                      color: bankroll.isInProfit ? AppColors.success : AppColors.warning,
                      large: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.divider, thickness: 0.5),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'MAX STAKE\n(${(bankroll.maxStakePercent * 100).toStringAsFixed(0)}%)',
                      value: _tzs(bankroll.maxStakeAmount),
                    ),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      label: 'DAILY STOP',
                      value: _tzs(bankroll.dailyStopLimit),
                      color: AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      label: 'EXPOSURE',
                      value: _tzs(state.totalExposure),
                      color: state.totalExposure > 0
                          ? AppColors.caution
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Daily stop progress bar ───────────────────────────────────────
        _DailyStopBar(bankroll: bankroll, todayPL: state.todayProfitLoss),
      ],
    );
  }

  // ── Set capital sheet ─────────────────────────────────────────────────────

  void _showCapitalSheet(BuildContext context, WidgetRef ref) {
    final vm      = ref.read(bettingViewModelProvider.notifier);
    final bankroll = ref.read(bettingViewModelProvider).bankroll;
    final ctrl    = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 3,
                  decoration: BoxDecoration(color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('ADD CAPITAL', style: AppTypography.label),
              const SizedBox(height: 4),
              Text(
                bankroll.startingBalance > 0
                    ? 'Current: ${_tzs(bankroll.currentBalance)} — top up adds to your existing balance'
                    : 'Enter your starting amount to begin tracking',
                style: AppTypography.caption),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 50000',
                  prefixText: 'TZS ',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(ctrl.text.trim());
                        if (amount == null || amount <= 0) return;
                        // If no balance set yet, set as starting capital
                        if (bankroll.startingBalance == 0) {
                          vm.setStartingCapital(amount);
                        } else {
                          vm.addCapital(amount);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        bankroll.startingBalance > 0 ? 'ADD CAPITAL' : 'SET CAPITAL',
                        style: AppTypography.h3
                            .copyWith(color: AppColors.background, fontSize: 13)),
                    ),
                  ),
                  if (bankroll.startingBalance > 0) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        final amount = double.tryParse(ctrl.text.trim());
                        if (amount == null || amount <= 0) return;
                        vm.setStartingCapital(amount);
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('RESET',
                          style: AppTypography.chip
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rules sheet (max stake %, daily stop, weekly target) ─────────────────

  void _showRulesSheet(BuildContext context, WidgetRef ref, BankrollModel bankroll) {
    final vm         = ref.read(bettingViewModelProvider.notifier);
    final stakeCtrl  = TextEditingController(
        text: (bankroll.maxStakePercent * 100).toStringAsFixed(0));
    final stopCtrl   = TextEditingController(
        text: bankroll.dailyStopLimit.toStringAsFixed(0));
    final weeklyCtrl = TextEditingController(
        text: bankroll.weeklyTarget.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('BANKROLL RULES', style: AppTypography.label),
            const SizedBox(height: 14),

            // Max stake % — free text, user defines
            Text('MAX STAKE PER BET (%)',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: stakeCtrl,
              keyboardType: TextInputType.number,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. 10',
                suffixText: '%',
              ),
            ),

            const SizedBox(height: 14),
            Text('DAILY STOP LOSS (TZS)',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: stopCtrl,
              keyboardType: TextInputType.number,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'e.g. 5000', prefixText: 'TZS '),
            ),

            const SizedBox(height: 14),
            Text('WEEKLY TARGET (TZS)',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: weeklyCtrl,
              keyboardType: TextInputType.number,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'e.g. 100000', prefixText: 'TZS '),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final pct    = double.tryParse(stakeCtrl.text.trim());
                  final stop   = double.tryParse(stopCtrl.text.trim());
                  final weekly = double.tryParse(weeklyCtrl.text.trim());
                  vm.updateBankrollSettings(
                    maxStakePercent: pct != null ? (pct / 100).clamp(0.001, 1.0) : null,
                    dailyStopLimit:  stop,
                    weeklyTarget:    weekly,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SAVE RULES',
                    style: AppTypography.h3
                        .copyWith(color: AppColors.background, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Setup prompt (no capital yet) ─────────────────────────────────────────────

class _SetupCapitalCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupCapitalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 36, color: AppColors.accent),
            const SizedBox(height: 12),
            Text('Set your starting capital',
                style: AppTypography.h3),
            const SizedBox(height: 6),
            Text('Tap here to define your bankroll in TZS',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _tzs(double v) {
  if (v.abs() >= 1000000) {
    return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  }
  if (v.abs() >= 1000) {
    return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  }
  return 'TZS ${v.toStringAsFixed(0)}';
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   large;

  const _BalanceStat({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.label.copyWith(fontSize: 9)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: large
              ? AppTypography.h1.copyWith(color: color, fontSize: 18)
              : AppTypography.mono.copyWith(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

class _DailyStopBar extends StatelessWidget {
  final BankrollModel bankroll;
  final double        todayPL;
  const _DailyStopBar({required this.bankroll, required this.todayPL});

  @override
  Widget build(BuildContext context) {
    final lossAmount = todayPL < 0 ? todayPL.abs() : 0.0;
    final progress   = bankroll.dailyStopLimit > 0
        ? (lossAmount / bankroll.dailyStopLimit).clamp(0.0, 1.0)
        : 0.0;
    final atRisk = progress > 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('DAILY STOP', style: AppTypography.label),
            const Spacer(),
            Text(
              '${_tzs(lossAmount)} / ${_tzs(bankroll.dailyStopLimit)}',
              style: AppTypography.mono.copyWith(
                fontSize: 11,
                color: atRisk ? AppColors.warning : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value:           progress,
            backgroundColor: AppColors.surfaceVar,
            valueColor:      AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? AppColors.warning
                  : atRisk
                      ? AppColors.caution
                      : AppColors.success,
            ),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}
