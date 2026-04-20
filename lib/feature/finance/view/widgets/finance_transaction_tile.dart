// lib/feature/finance/view/widgets/finance_transaction_tile.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';

class FinanceTransactionTile extends StatelessWidget {
  final FinanceTransaction transaction;
  final VoidCallback? onTap;

  const FinanceTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  Color get _typeColor {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.warning;
      case TransactionType.transferIn:
        return const Color(0xFF3498DB);
      case TransactionType.transferOut:
        return const Color(0xFF9B59B6);
      case TransactionType.adjustment:
        return AppColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transferIn:
        return Icons.swap_horiz_rounded;
      case TransactionType.transferOut:
        return Icons.swap_horiz_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  String get _sign {
    switch (transaction.type) {
      case TransactionType.income:
      case TransactionType.transferIn:
        return '+';
      case TransactionType.expense:
      case TransactionType.transferOut:
        return '-';
      case TransactionType.adjustment:
        return '';
    }
  }

  String get _formattedDate {
    final d = transaction.transactionDate;
    return '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPad,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_typeIcon, size: 14, color: _typeColor),
            ),
            const SizedBox(width: AppSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: AppTypography.h3.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category.label,
                        style: AppTypography.caption,
                      ),
                      Text(' · ', style: AppTypography.caption),
                      Text(
                        _formattedDate,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '$_sign TZS ${transaction.amount.toStringAsFixed(0)}',
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                color: _typeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
