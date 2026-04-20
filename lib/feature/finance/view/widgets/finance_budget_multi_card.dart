// lib/feature/finance/view/widgets/finance_budget_multi_card.dart
//
// Shows every configured budget for a category (daily, weekly, monthly,
// yearly) stacked inside a single card. The header is colored by the
// worst-performing period so a daily overage still turns the card red even
// when the month is fine.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceBudgetMultiCard extends StatelessWidget {
  final FinanceCategory category;
  final List<BudgetCheck> checks;
  final VoidCallback? onSetBudget;

  const FinanceBudgetMultiCard({
    super.key,
    required this.category,
    required this.checks,
    this.onSetBudget,
  });

  BudgetHealth get _worst {
    if (checks.isEmpty) return BudgetHealth.healthy;
    const order = [
      BudgetHealth.healthy,
      BudgetHealth.warning,
      BudgetHealth.danger,
      BudgetHealth.overBudget,
    ];
    return checks.map((c) => c.health).reduce(
          (a, b) => order.indexOf(a) >= order.indexOf(b) ? a : b,
        );
  }

  Color _colorFor(BudgetHealth h) {
    switch (h) {
      case BudgetHealth.overBudget: return AppColors.warning;
      case BudgetHealth.danger:     return AppColors.caution;
      case BudgetHealth.warning:    return AppColors.caution.withValues(alpha: 0.7);
      case BudgetHealth.healthy:    return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final worstColor = _colorFor(_worst);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: checks.isEmpty ? AppColors.border : worstColor.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.label.toUpperCase(), style: AppTypography.label),
              const Spacer(),
              if (checks.isEmpty)
                GestureDetector(
                  onTap: onSetBudget,
                  child: Text(
                    'SET BUDGET',
                    style: AppTypography.label.copyWith(color: AppColors.accent),
                  ),
                )
              else
                Text(
                  _worst == BudgetHealth.overBudget
                      ? 'OVER BUDGET'
                      : _worst.name.toUpperCase(),
                  style: AppTypography.label.copyWith(color: worstColor),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (checks.isEmpty)
            Text(
              'No budget configured.',
              style: AppTypography.bodySmall,
            )
          else
            Column(
              children: [
                for (int i = 0; i < checks.length; i++) ...[
                  _CheckRow(check: checks[i], color: _colorFor(checks[i].health)),
                  if (i != checks.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final BudgetCheck check;
  final Color color;

  const _CheckRow({required this.check, required this.color});

  @override
  Widget build(BuildContext context) {
    final pctLabel = '${(check.usagePercent * 100).toStringAsFixed(0)}%';
    final over = check.isOverBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                check.period.label.toUpperCase(),
                style: AppTypography.label.copyWith(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: check.displayPercent,
                  minHeight: 4,
                  backgroundColor: AppColors.elevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 48,
              child: Text(
                pctLabel,
                textAlign: TextAlign.right,
                style: AppTypography.mono.copyWith(fontSize: 11, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 68),
          child: Text(
            over
                ? 'TZS ${check.spent.toStringAsFixed(0)} of ${check.allocated.toStringAsFixed(0)} — over by ${(-check.remaining).toStringAsFixed(0)}'
                : 'TZS ${check.spent.toStringAsFixed(0)} of ${check.allocated.toStringAsFixed(0)}',
            style: AppTypography.caption.copyWith(
              color: over ? color : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
