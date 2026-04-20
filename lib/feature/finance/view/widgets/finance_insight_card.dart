// lib/feature/finance/view/widgets/finance_insight_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceInsightCard extends StatelessWidget {
  final BudgetInsight insight;

  const FinanceInsightCard({super.key, required this.insight});

  Color get _healthColor {
    switch (insight.health) {
      case BudgetHealth.healthy:    return AppColors.success;
      case BudgetHealth.warning:    return AppColors.caution;
      case BudgetHealth.danger:     return AppColors.impactHigh;
      case BudgetHealth.overBudget: return AppColors.warning;
    }
  }

  IconData get _healthIcon {
    switch (insight.health) {
      case BudgetHealth.healthy:    return Icons.check_circle_outline;
      case BudgetHealth.warning:    return Icons.warning_amber_outlined;
      case BudgetHealth.danger:     return Icons.error_outline;
      case BudgetHealth.overBudget: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: _healthColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: _healthColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_healthIcon, size: 16, color: _healthColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title.toUpperCase(),
                  style: AppTypography.label.copyWith(color: _healthColor, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(insight.message, style: AppTypography.bodySmall.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
