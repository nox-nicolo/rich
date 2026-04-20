// lib/features/betting/view/widgets/betting_history_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/bet_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _tzs(double v) {
  final sign = v >= 0 ? '+' : '';
  if (v.abs() >= 1000000) return '$sign TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000)    return '$sign TZS ${(v / 1000).toStringAsFixed(0)}K';
  return '$sign TZS ${v.toStringAsFixed(0)}';
}

String _formatDate(DateTime d) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'Today';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (d.year == yesterday.year &&
      d.month == yesterday.month &&
      d.day == yesterday.day) {
    return 'Yesterday';
  }
  return '${d.day} ${months[d.month]}';
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _DayRecord {
  final DateTime date;
  final List<BetModel> bets;

  _DayRecord({required this.date, required this.bets});

  int get total      => bets.length;
  int get wins       => bets.where((b) => b.status == BetStatus.won).length;
  int get losses     => bets.where((b) => b.status == BetStatus.lost).length;
  int get cashouts   => bets.where((b) => b.status == BetStatus.cashout).length;
  int get pending    => bets.where((b) => b.isActive).length;

  double get totalPL =>
      bets.where((b) => b.isSettled).fold(0.0, (s, b) => s + b.profitLoss);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class BettingHistoryWidget extends ConsumerStatefulWidget {
  const BettingHistoryWidget({super.key});

  @override
  ConsumerState<BettingHistoryWidget> createState() =>
      _BettingHistoryWidgetState();
}

class _BettingHistoryWidgetState
    extends ConsumerState<BettingHistoryWidget> {
  final Set<String> _expanded = {};

  List<_DayRecord> _groupByDay(List<BetModel> bets) {
    final map = <String, List<BetModel>>{};
    for (final b in bets) {
      final key =
          '${b.placedAt.year}-${b.placedAt.month.toString().padLeft(2, '0')}-${b.placedAt.day.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(b);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys.map((k) {
      final parts = k.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final dayBets = map[k]!
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
      return _DayRecord(date: date, bets: dayBets);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bettingViewModelProvider);
    final days  = _groupByDay(state.recentBets);

    // Monthly summary
    final now       = DateTime.now();
    final thisMonth = state.recentBets.where(
      (b) => b.placedAt.month == now.month && b.placedAt.year == now.year,
    ).toList();
    final monthPL   = thisMonth
        .where((b) => b.isSettled)
        .fold(0.0, (s, b) => s + b.profitLoss);
    final monthBets = thisMonth.length;
    final monthWins = thisMonth.where((b) => b.status == BetStatus.won).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Monthly summary card ──────────────────────────────────────────
        RichSectionHeader(title: 'THIS MONTH'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              _MonthlyStat(
                label: 'P&L',
                value: _tzs(monthPL),
                color: monthPL >= 0 ? AppColors.success : AppColors.warning,
                large: true,
              ),
              _MonthlyStat(
                label: 'BETS',
                value: '$monthBets',
                color: AppColors.textPrimary,
              ),
              _MonthlyStat(
                label: 'WIN RATE',
                value: monthBets > 0
                    ? '${(monthWins / monthBets * 100).toStringAsFixed(0)}%'
                    : '—',
                color: AppColors.accent,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Daily records ─────────────────────────────────────────────────
        RichSectionHeader(
          title: 'DAILY RECORDS',
          trailing: Text('last 31 days',
              style: AppTypography.caption.copyWith(fontSize: 10)),
        ),

        if (days.isEmpty)
          _EmptyHistory()
        else
          ...days.map((day) => _DayRow(
                record:     day,
                expanded:   _expanded.contains(day.date.toIso8601String()),
                onToggle:   () => setState(() {
                  final key = day.date.toIso8601String();
                  if (_expanded.contains(key)) {
                    _expanded.remove(key);
                  } else {
                    _expanded.add(key);
                  }
                }),
              )),
      ],
    );
  }
}

// ── Day row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final _DayRecord  record;
  final bool        expanded;
  final VoidCallback onToggle;

  const _DayRow({
    required this.record,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final pl      = record.totalPL;
    final plColor = pl > 0
        ? AppColors.success
        : pl < 0
            ? AppColors.warning
            : AppColors.textMuted;

    return Column(
      children: [
        // ── Header row ───────────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 14),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: expanded
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Date
                SizedBox(
                  width: 72,
                  child: Text(_formatDate(record.date),
                      style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13)),
                ),

                // Bet counts
                Expanded(
                  child: Row(
                    children: [
                      _CountDot(
                          count: record.wins,
                          color: AppColors.success,
                          label: 'W'),
                      const SizedBox(width: 6),
                      _CountDot(
                          count: record.losses,
                          color: AppColors.warning,
                          label: 'L'),
                      if (record.cashouts > 0) ...[
                        const SizedBox(width: 6),
                        _CountDot(
                            count: record.cashouts,
                            color: AppColors.caution,
                            label: 'C'),
                      ],
                      if (record.pending > 0) ...[
                        const SizedBox(width: 6),
                        _CountDot(
                            count: record.pending,
                            color: AppColors.textMuted,
                            label: '•'),
                      ],
                    ],
                  ),
                ),

                // P&L
                Text(
                  record.pending == record.total && record.total > 0
                      ? 'LIVE'
                      : _tzs(pl),
                  style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: record.pending == record.total
                          ? AppColors.caution
                          : plColor),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded bet list ─────────────────────────────────────────────
        if (expanded)
          Container(
            margin: const EdgeInsets.only(
                left: 8, right: 0, bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1.5),
              ),
            ),
            child: Column(
              children: record.bets
                  .map((bet) => _BetDetailRow(bet: bet))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ── Bet detail row (inside expanded day) ──────────────────────────────────────

class _BetDetailRow extends StatelessWidget {
  final BetModel bet;
  const _BetDetailRow({required this.bet});

  Color get _statusColor {
    switch (bet.status) {
      case BetStatus.won:
        return AppColors.success;
      case BetStatus.lost:
        return AppColors.warning;
      case BetStatus.cashout:
        return AppColors.caution;
      case BetStatus.active:
        return AppColors.caution;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl     = bet.profitLoss;
    final plText = bet.isActive
        ? 'LIVE'
        : '${pl >= 0 ? '+' : ''}TZS ${pl.abs().toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _statusColor),
            ),
            const SizedBox(width: 8),

            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bet.description,
                      style: AppTypography.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      Text('@${bet.odds.toStringAsFixed(2)}',
                          style: AppTypography.caption
                              .copyWith(fontSize: 10)),
                      const SizedBox(width: 8),
                      Text(
                          'Stake: TZS ${bet.stake.toStringAsFixed(0)}',
                          style: AppTypography.caption
                              .copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // P&L
            Text(plText,
                style: AppTypography.mono.copyWith(
                    fontSize: 11, color: _statusColor)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CountDot extends StatelessWidget {
  final int count;
  final Color color;
  final String label;
  const _CountDot(
      {required this.count, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$count$label',
          style: AppTypography.chip
              .copyWith(color: color, fontSize: 9)),
    );
  }
}

class _MonthlyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   large;
  const _MonthlyStat({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.label.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              style: large
                  ? AppTypography.h1.copyWith(color: color, fontSize: 16)
                  : AppTypography.mono.copyWith(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.history, color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No betting history yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Your bet records will appear here',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
