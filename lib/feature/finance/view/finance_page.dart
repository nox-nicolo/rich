// lib/feature/finance/view/finance_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rich_section_header.dart';
import '../model/finance_models.dart';
import '../viewmodel/finance_viewmodel.dart';
import 'widgets/finance_summary_card.dart';
import 'widgets/finance_trend_chart.dart';
import 'widgets/finance_account_card.dart';
import 'widgets/finance_budget_multi_card.dart';
import 'widgets/finance_transaction_tile.dart';
import 'widgets/finance_insight_card.dart';
import 'pages/add_income_page.dart';
import 'pages/add_expense_page.dart';
import 'pages/transfer_money_page.dart';
import 'pages/budget_allocations_page.dart';
import 'pages/finance_reports_page.dart';
import 'pages/finance_audit_page.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeViewModelProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 1,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: AppColors.background,
              floating: true,
              pinned: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: AppSpacing.iconSm,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => context.go('/'),
              ),
              title: Text(
                'FINANCE',
                style: AppTypography.label.copyWith(fontSize: 12),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.history_outlined,
                    size: AppSpacing.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Audit Trail',
                  onPressed: () => _openAudit(context),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bar_chart_outlined,
                    size: AppSpacing.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Reports',
                  onPressed: () => _openReports(context),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Summary Card ────────────────────────────────────────
                  FinanceSummaryCard(
                    summary: state.dashboardSummary,
                    monthSummary: state.monthSummary,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  FinanceTrendChart(
                    accounts: state.accounts,
                    transactions: state.transactions,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Quick Actions ───────────────────────────────────────
                  _QuickActionsRow(
                    onAddIncome: () => _openAddIncome(context),
                    onAddExpense: () => _openAddExpense(context),
                    onTransfer: () => _openTransfer(context),
                    onBudget: () => _openBudget(context),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Accounts ────────────────────────────────────────────
                  RichSectionHeader(
                    title: 'ACCOUNTS',
                    action: 'SEE ALL',
                    onAction: () {},
                  ),
                  ...FinanceCategory.values.map((cat) {
                    final account = state.accountFor(cat);
                    if (account == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FinanceAccountCard(
                        account: account,
                        monthSpent: state.monthSummary.spentFor(cat),
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Budget Progress ─────────────────────────────────────
                  // Each card stacks every configured period (daily → yearly)
                  // so a weekly overage is visible even when the month is OK.
                  RichSectionHeader(
                    title: 'BUDGETS',
                    action: 'SET BUDGET',
                    onAction: () => _openBudget(context),
                  ),
                  ...FinanceCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FinanceBudgetMultiCard(
                        category: cat,
                        checks: state.budgetChecksFor(cat),
                        onSetBudget: () => _openBudget(context),
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Recent Transactions ─────────────────────────────────
                  RichSectionHeader(
                    title: 'RECENT TRANSACTIONS',
                    action: 'ALL',
                    onAction: () => _openReports(context),
                  ),
                  if (state.recentTransactions.isEmpty)
                    _EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message:
                          'No transactions yet.\nAdd income or an expense to get started.',
                    )
                  else
                    ...state.recentTransactions
                        .take(10)
                        .map(
                          (tx) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: FinanceTransactionTile(transaction: tx),
                          ),
                        ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Insights ────────────────────────────────────────────
                  const RichSectionHeader(title: 'BUDGET INSIGHTS'),
                  ...state.allInsights
                      .where((i) => i.health != BudgetHealth.healthy)
                      .take(5)
                      .map(
                        (insight) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: FinanceInsightCard(insight: insight),
                        ),
                      ),
                  if (state.allBudgetChecks.isEmpty)
                    FinanceInsightCard(
                      insight: BudgetInsight(
                        id: 'no_budgets',
                        category: FinanceCategory.general,
                        health: BudgetHealth.warning,
                        title: 'No budgets set',
                        message:
                            'Set daily, weekly, monthly or yearly budgets '
                            'to get overspend alerts.',
                        createdAt: DateTime.now(),
                      ),
                    )
                  else if (state.allBudgetChecks.every(
                    (c) => c.health == BudgetHealth.healthy,
                  ))
                    FinanceInsightCard(
                      insight: BudgetInsight(
                        id: 'all_ok',
                        category: FinanceCategory.general,
                        health: BudgetHealth.healthy,
                        title: 'All budgets on track',
                        message: 'Every configured period is within budget.',
                        createdAt: DateTime.now(),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.x3l),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddIncome(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const AddIncomePage(),
      fullscreenDialog: true,
    ),
  );

  void _openAddExpense(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const AddExpensePage(),
      fullscreenDialog: true,
    ),
  );

  void _openTransfer(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const TransferMoneyPage(),
      fullscreenDialog: true,
    ),
  );

  void _openBudget(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const BudgetAllocationsPage(),
      fullscreenDialog: true,
    ),
  );

  void _openReports(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FinanceReportsPage()));

  void _openAudit(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FinanceAuditPage()));
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;
  final VoidCallback onBudget;

  const _QuickActionsRow({
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
    required this.onBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_circle_outline,
          label: 'Income',
          color: AppColors.success,
          onTap: onAddIncome,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickAction(
          icon: Icons.remove_circle_outline,
          label: 'Expense',
          color: AppColors.warning,
          onTap: onAddExpense,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickAction(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer',
          color: const Color(0xFF3498DB),
          onTap: onTransfer,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickAction(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Budget',
          color: const Color(0xFFE67E22),
          onTap: onBudget,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: AppSpacing.iconMd, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
