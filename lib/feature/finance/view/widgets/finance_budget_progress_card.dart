// lib/feature/finance/view/widgets/finance_budget_progress_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceBudgetProgressCard extends StatelessWidget {
  final FinanceCategory category;
  final double spent;
  final double allocated;
  final String insight;

  const FinanceBudgetProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.allocated,
    required this.insight,
  });

  double get _percent =>
      allocated <= 0 ? 0 : (spent / allocated).clamp(0.0, 1.0);

  Color get _health {
    if (allocated <= 0) return AppColors.textMuted;
    final p = spent / allocated;
    if (p > 1) return AppColors.warning;
    if (p >= 0.85) return AppColors.caution;
    if (p >= 0.65) return AppColors.caution.withValues(alpha: 0.7);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.label.toUpperCase(),
                style: AppTypography.label,
              ),
              const Spacer(),
              Text(
                allocated > 0
                    ? '${(_percent * 100).toStringAsFixed(0)}%'
                    : 'No budget',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: _health,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: _percent,
              minHeight: 5,
              backgroundColor: AppColors.elevated,
              valueColor: AlwaysStoppedAnimation<Color>(_health),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: TZS ${spent.toStringAsFixed(0)}',
                style: AppTypography.bodySmall,
              ),
              Text(
                allocated > 0
                    ? 'Budget: TZS ${allocated.toStringAsFixed(0)}'
                    : 'Set a budget',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (insight.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              insight,
              style: AppTypography.caption.copyWith(
                color: _health,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
