// lib/features/betting/view/widgets/running_count_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/bet_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

String _tzs(double v) {
  if (v.abs() >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000)    return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

class RunningCountWidget extends ConsumerWidget {
  const RunningCountWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bettingViewModelProvider);
    final vm    = ref.read(bettingViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'RUNNING COUNT',
          trailing: Text(
            '${state.activeBets.length} active',
            style: AppTypography.mono.copyWith(fontSize: 12),
          ),
        ),
        if (state.activeBets.isEmpty)
          const _EmptyBets()
        else
          ...state.activeBets.map(
            (bet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ActiveBetTile(
                bet:      bet,
                onWin:    () => vm.settleBet(bet.id, BetStatus.won),
                onLoss:   () => vm.settleBet(bet.id, BetStatus.lost),
                onVoid:   () => vm.settleBet(bet.id, BetStatus.void_),
                onCashout: (amount) =>
                    vm.settleBet(bet.id, BetStatus.cashout, cashoutAmount: amount),
              ),
            ),
          ),
        if (state.todayBets.any((b) => b.isSettled)) ...[
          const SizedBox(height: AppSpacing.lg),
          const RichSectionHeader(title: "TODAY'S SETTLED"),
          ...state.todayBets
              .where((b) => b.isSettled)
              .map((bet) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                    child: _SettledBetTile(bet: bet),
                  )),
        ],
      ],
    );
  }
}

class _ActiveBetTile extends StatefulWidget {
  final BetModel bet;
  final VoidCallback onWin;
  final VoidCallback onLoss;
  final VoidCallback onVoid;
  final ValueChanged<double> onCashout;

  const _ActiveBetTile({
    required this.bet,
    required this.onWin,
    required this.onLoss,
    required this.onVoid,
    required this.onCashout,
  });

  @override
  State<_ActiveBetTile> createState() => _ActiveBetTileState();
}

class _ActiveBetTileState extends State<_ActiveBetTile> {
  bool _showCashout = false;
  final _cashoutCtrl = TextEditingController();

  @override
  void dispose() {
    _cashoutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bet = widget.bet;
    final returnAmt = bet.calculatedPotentialReturn;
    final pct = ((returnAmt - bet.stake) / bet.stake * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.caution.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.caution),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(bet.type.label.toUpperCase(),
                  style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
              const Spacer(),
              Text('@${bet.odds.toStringAsFixed(2)}',
                  style: AppTypography.mono.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(bet.description,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Stake: ${_tzs(bet.stake)}',
                  style: AppTypography.caption),
              const SizedBox(width: AppSpacing.md),
              Text('Return: ${_tzs(returnAmt)} (+$pct%)',
                  style: AppTypography.caption.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Cashout input (shown when CASHOUT tapped)
          if (_showCashout) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cashoutCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cashout amount',
                      prefixText: 'TZS ',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.caution.withValues(alpha: 0.4),
                            width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: AppColors.caution, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final amt = double.tryParse(_cashoutCtrl.text.trim());
                    if (amt == null || amt < 0) return;
                    widget.onCashout(amt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.caution.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.caution.withValues(alpha: 0.4),
                          width: 0.5),
                    ),
                    child: Text('CONFIRM',
                        style: AppTypography.chip
                            .copyWith(color: AppColors.caution)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _showCashout = false),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Settle buttons
          Row(
            children: [
              _SettleButton(
                  label: 'WON', color: AppColors.success, onTap: widget.onWin),
              const SizedBox(width: AppSpacing.sm),
              _SettleButton(
                  label: 'LOST', color: AppColors.warning, onTap: widget.onLoss),
              const SizedBox(width: AppSpacing.sm),
              _SettleButton(
                label: 'CASHOUT',
                color: AppColors.caution,
                onTap: () => setState(() => _showCashout = !_showCashout),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SettleButton(
                  label: 'VOID', color: AppColors.textMuted, onTap: widget.onVoid),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettleButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettleButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(label,
            style: AppTypography.chip.copyWith(color: color, fontSize: 9)),
      ),
    );
  }
}

class _SettledBetTile extends StatelessWidget {
  final BetModel bet;
  const _SettledBetTile({required this.bet});

  Color get _statusColor {
    if (bet.status == BetStatus.won) return AppColors.success;
    if (bet.status == BetStatus.lost) return AppColors.warning;
    if (bet.status == BetStatus.cashout) return AppColors.caution;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final pl     = bet.profitLoss;
    final plSign = pl >= 0 ? '+' : '';
    final pctOfStake = bet.stake > 0
        ? ((pl / bet.stake) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 32,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bet.description,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(bet.status.label.toUpperCase(),
                    style: AppTypography.chip
                        .copyWith(color: _statusColor, fontSize: 9)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$plSign${_tzs(pl)}',
                style: AppTypography.mono
                    .copyWith(fontSize: 12, color: _statusColor),
              ),
              Text(
                '$plSign$pctOfStake%',
                style: AppTypography.chip
                    .copyWith(fontSize: 9, color: _statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBets extends StatelessWidget {
  const _EmptyBets();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.pending_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No active bets', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Place a bet from the slip tab',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
