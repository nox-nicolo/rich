// lib/feature/finance/view/widgets/finance_summary_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceSummaryCard extends StatelessWidget {
  final FinanceDashboardSummary summary;
  final PeriodSummary monthSummary;

  const FinanceSummaryCard({
    super.key,
    required this.summary,
    required this.monthSummary,
  });

  @override
  Widget build(BuildContext context) {
    final netFlow = monthSummary.netCashFlow;
    final netColor = netFlow >= 0 ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL BALANCE', style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _fmt(summary.totalBalance),
            style: AppTypography.display.copyWith(fontSize: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatChip(
                label: 'INCOME',
                value: _fmt(monthSummary.totalIncome),
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: 'EXPENSES',
                value: _fmt(monthSummary.totalExpenses),
                color: AppColors.warning,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: 'NET',
                value: '${netFlow >= 0 ? '+' : ''}${_fmt(netFlow)}',
                color: netColor,
                icon: netFlow >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => 'TZS ${v.abs().toStringAsFixed(0)}';
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: color, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTypography.mono.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
