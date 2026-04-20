// lib/feature/finance/view/pages/finance_reports_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';
import '../widgets/finance_transaction_tile.dart';
import '../widgets/finance_budget_progress_card.dart';

class FinanceReportsPage extends ConsumerStatefulWidget {
  const FinanceReportsPage({super.key});

  @override
  ConsumerState<FinanceReportsPage> createState() => _FinanceReportsPageState();
}

class _FinanceReportsPageState extends ConsumerState<FinanceReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['TODAY', 'WEEK', 'MONTH', 'YEAR'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('REPORTS', style: AppTypography.label.copyWith(fontSize: 12)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.chip.copyWith(fontSize: 10),
          unselectedLabelColor: AppColors.textMuted,
          labelColor: AppColors.textPrimary,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PeriodReport(
            summary:   state.todaySummary,
            state:     state,
            period:    FinancePeriod.daily,
          ),
          _PeriodReport(
            summary:   state.weekSummary,
            state:     state,
            period:    FinancePeriod.weekly,
          ),
          _PeriodReport(
            summary:   state.monthSummary,
            state:     state,
            period:    FinancePeriod.monthly,
          ),
          _PeriodReport(
            summary:   state.yearSummary,
            state:     state,
            period:    FinancePeriod.yearly,
          ),
        ],
      ),
    );
  }
}

class _PeriodReport extends StatelessWidget {
  final PeriodSummary summary;
  final FinanceState state;
  final FinancePeriod period;

  const _PeriodReport({
    required this.summary,
    required this.state,
    required this.period,
  });

  List<FinanceTransaction> get _txForPeriod {
    return state.transactions.where((t) {
      return !t.transactionDate.isBefore(summary.startDate) &&
          !t.transactionDate.isAfter(summary.endDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txs = _txForPeriod;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Summary Cards ──────────────────────────────────────────────────
        _SummaryMetrics(summary: summary),
        const SizedBox(height: AppSpacing.xl),

        // ── Category Breakdown ─────────────────────────────────────────────
        const RichSectionHeader(title: 'SPENDING BY CATEGORY'),
        ...FinanceCategory.values.map((cat) {
          final allocation = period == FinancePeriod.monthly
              ? state.latestAllocationFor(cat)
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FinanceBudgetProgressCard(
              category:  cat,
              spent:     summary.spentFor(cat),
              allocated: allocation?.allocatedAmount ?? 0,
              insight:   '',
            ),
          );
        }),

        const SizedBox(height: AppSpacing.xl),

        // ── Category Income Snapshot ───────────────────────────────────────
        const RichSectionHeader(title: 'INCOME BY CATEGORY'),
        ...FinanceCategory.values
            .where((cat) => summary.incomeFor(cat) > 0)
            .map((cat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CategoryRow(
                    category: cat,
                    amount: summary.incomeFor(cat),
                    color: AppColors.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                )),
        if (FinanceCategory.values.every((cat) => summary.incomeFor(cat) == 0))
          _EmptyMessage(message: 'No income recorded for this period.'),

        const SizedBox(height: AppSpacing.xl),

        // ── Transactions ───────────────────────────────────────────────────
        RichSectionHeader(
          title: 'TRANSACTIONS (${txs.length})',
        ),
        if (txs.isEmpty)
          _EmptyMessage(message: 'No transactions for this period.')
        else
          ...txs.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FinanceTransactionTile(transaction: tx),
              )),

        const SizedBox(height: AppSpacing.x3l),
      ],
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  final PeriodSummary summary;

  const _SummaryMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final net = summary.netCashFlow;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          label: 'INCOME',
          value: 'TZS ${summary.totalIncome.toStringAsFixed(0)}',
          color: AppColors.success,
          icon: Icons.arrow_downward_rounded,
        ),
        _MetricCard(
          label: 'EXPENSES',
          value: 'TZS ${summary.totalExpenses.toStringAsFixed(0)}',
          color: AppColors.warning,
          icon: Icons.arrow_upward_rounded,
        ),
        _MetricCard(
          label: 'TRANSFER IN',
          value: 'TZS ${summary.totalTransfersIn.toStringAsFixed(0)}',
          color: const Color(0xFF3498DB),
          icon: Icons.swap_horiz_rounded,
        ),
        _MetricCard(
          label: 'NET CASH FLOW',
          value: '${net >= 0 ? '+' : ''}TZS ${net.abs().toStringAsFixed(0)}',
          color: net >= 0 ? AppColors.success : AppColors.warning,
          icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTypography.caption.copyWith(color: color, fontSize: 9)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTypography.mono.copyWith(
                        fontSize: 11, color: color, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final FinanceCategory category;
  final double amount;
  final Color color;
  final IconData icon;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPad, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(category.label, style: AppTypography.body),
          ),
          Text(
            'TZS ${amount.toStringAsFixed(0)}',
            style: AppTypography.mono.copyWith(
                fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        message,
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
