// lib/feature/finance/view/widgets/finance_account_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceAccountCard extends StatelessWidget {
  final FinanceAccount account;
  final double? monthSpent;
  final VoidCallback? onTap;

  const FinanceAccountCard({
    super.key,
    required this.account,
    this.monthSpent,
    this.onTap,
  });

  Color get _categoryColor {
    switch (account.category) {
      case FinanceCategory.general:   return const Color(0xFF6C8EBF);
      case FinanceCategory.investing: return const Color(0xFF27AE60);
      case FinanceCategory.saving:    return const Color(0xFFE67E22);
      case FinanceCategory.emergency: return const Color(0xFFC0392B);
      case FinanceCategory.travel:    return const Color(0xFF9B59B6);
    }
  }

  IconData get _categoryIcon {
    switch (account.category) {
      case FinanceCategory.general:   return Icons.wallet_outlined;
      case FinanceCategory.investing: return Icons.show_chart_outlined;
      case FinanceCategory.saving:    return Icons.savings_outlined;
      case FinanceCategory.emergency: return Icons.health_and_safety_outlined;
      case FinanceCategory.travel:    return Icons.flight_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _categoryColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_categoryIcon, size: 16, color: _categoryColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: _categoryColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TZS ${account.currentBalance.toStringAsFixed(0)}',
                    style: AppTypography.h3.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (monthSpent != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('this month', style: AppTypography.caption.copyWith(fontSize: 9)),
                  Text(
                    '-TZS ${monthSpent!.toStringAsFixed(0)}',
                    style: AppTypography.mono.copyWith(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right,
                size: AppSpacing.iconSm, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
