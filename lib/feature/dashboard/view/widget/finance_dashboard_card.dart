// lib/feature/dashboard/view/widget/finance_dashboard_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../../finance/model/finance_models.dart';
import '../../../finance/viewmodel/finance_viewmodel.dart';

class FinanceDashboardCard extends ConsumerWidget {
  const FinanceDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeViewModelProvider);

    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    final dash   = state.dashboardSummary;
    final month  = state.monthSummary;
    final net    = month.netCashFlow;
    final netPos = net >= 0;

    return GlossyCard(
      onTap:        () => context.push(RouteNames.finance),
      accentBorder: const Color(0xFF27AE60),
      radius:       AppSpacing.radiusXl,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: Color(0xFF27AE60)),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('FINANCE', style: AppTypography.label.copyWith(fontSize: 11)),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: AppSpacing.iconSm, color: AppColors.textMuted),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Total balance
            Text(
              'TZS ${dash.totalBalance.toStringAsFixed(0)}',
              style: AppTypography.h2.copyWith(fontSize: 20),
            ),
            Text('Total Balance', style: AppTypography.caption),

            const SizedBox(height: AppSpacing.md),

            // Month stats row
            Row(
              children: [
                _MiniStat(
                  label: '↓ INCOME',
                  value: 'TZS ${month.totalIncome.toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.md),
                _MiniStat(
                  label: '↑ EXPENSES',
                  value: 'TZS ${month.totalExpenses.toStringAsFixed(0)}',
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                _MiniStat(
                  label: 'NET',
                  value: '${netPos ? '+' : ''}TZS ${net.abs().toStringAsFixed(0)}',
                  color: netPos ? AppColors.success : AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.md),

            // Category mini balances
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: FinanceCategory.values.map((cat) {
                final balance = _balanceFor(dash, cat);
                return _CategoryDot(
                  label: cat.label.substring(0, 3).toUpperCase(),
                  amount: balance,
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Budget health message
            _buildHealthMessage(state),
          ],
        ),
    );
  }

  double _balanceFor(FinanceDashboardSummary dash, FinanceCategory cat) {
    switch (cat) {
      case FinanceCategory.general:   return dash.totalGeneralAvailable;
      case FinanceCategory.investing: return dash.totalInvested;
      case FinanceCategory.saving:    return dash.totalSaved;
      case FinanceCategory.emergency: return dash.totalEmergencyReserved;
      case FinanceCategory.travel:    return dash.totalTravelReserved;
    }
  }

  Widget _buildHealthMessage(FinanceState state) {
    // Find the worst health insight
    final worst = state.allInsights
      ..sort((a, b) => b.health.index.compareTo(a.health.index));
    final top = worst.isNotEmpty ? worst.first : null;

    if (top == null || top.health == BudgetHealth.healthy) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 11, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          Text('All budgets on track',
              style: AppTypography.caption.copyWith(color: AppColors.success, fontSize: 10)),
        ],
      );
    }

    final color = top.health == BudgetHealth.overBudget ||
            top.health == BudgetHealth.danger
        ? AppColors.warning
        : AppColors.caution;

    return Row(
      children: [
        Icon(Icons.warning_amber_outlined, size: 11, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${top.category.label}: ${top.health.label}',
            style: AppTypography.caption.copyWith(color: color, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final String label;
  final double amount;

  const _CategoryDot({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(fontSize: 8)),
        const SizedBox(height: 2),
        Text(
          'T${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(0)}K' : amount.toStringAsFixed(0)}',
          style: AppTypography.mono.copyWith(
              fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
