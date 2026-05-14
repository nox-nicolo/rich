// lib/feature/finance/viewmodel/finance_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/finance_models.dart';
import '../repository/finance_repository.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class FinanceState {
  final List<FinanceAccount> accounts;
  final List<BudgetAllocation> allocations;
  final List<FinanceTransaction> transactions;
  final List<AuditTrailEntry> auditTrail;
  final FinanceDashboardSummary dashboardSummary;
  final PeriodSummary todaySummary;
  final PeriodSummary weekSummary;
  final PeriodSummary monthSummary;
  final PeriodSummary yearSummary;
  final List<FinanceTransaction> recentTransactions;
  final FinancePeriod selectedPeriod;
  final FinanceCategory? selectedCategory;
  final bool isLoading;
  final String? errorMessage;

  const FinanceState({
    required this.accounts,
    required this.allocations,
    required this.transactions,
    required this.auditTrail,
    required this.dashboardSummary,
    required this.todaySummary,
    required this.weekSummary,
    required this.monthSummary,
    required this.yearSummary,
    required this.recentTransactions,
    required this.selectedPeriod,
    this.selectedCategory,
    required this.isLoading,
    this.errorMessage,
  });

  factory FinanceState.initial() {
    final now = DateTime.now();
    final emptyDay = DateTime(now.year, now.month, now.day);
    final emptyPeriod = PeriodSummary(
      period: FinancePeriod.daily,
      startDate: emptyDay,
      endDate: emptyDay,
      totalIncome: 0,
      totalExpenses: 0,
      totalTransfersIn: 0,
      totalTransfersOut: 0,
      netCashFlow: 0,
      categorySpend: {},
      categoryIncome: {},
    );
    const emptyDash = FinanceDashboardSummary(
      totalBalance: 0,
      totalIncome: 0,
      totalExpenses: 0,
      totalSaved: 0,
      totalInvested: 0,
      totalEmergencyReserved: 0,
      totalTravelReserved: 0,
      totalGeneralAvailable: 0,
    );
    return FinanceState(
      accounts: const [],
      allocations: const [],
      transactions: const [],
      auditTrail: const [],
      dashboardSummary: emptyDash,
      todaySummary: emptyPeriod,
      weekSummary: emptyPeriod.copyWith(period: FinancePeriod.weekly),
      monthSummary: emptyPeriod.copyWith(period: FinancePeriod.monthly),
      yearSummary: emptyPeriod.copyWith(period: FinancePeriod.yearly),
      recentTransactions: const [],
      selectedPeriod: FinancePeriod.monthly,
      isLoading: true,
    );
  }

  FinanceState copyWith({
    List<FinanceAccount>? accounts,
    List<BudgetAllocation>? allocations,
    List<FinanceTransaction>? transactions,
    List<AuditTrailEntry>? auditTrail,
    FinanceDashboardSummary? dashboardSummary,
    PeriodSummary? todaySummary,
    PeriodSummary? weekSummary,
    PeriodSummary? monthSummary,
    PeriodSummary? yearSummary,
    List<FinanceTransaction>? recentTransactions,
    FinancePeriod? selectedPeriod,
    FinanceCategory? selectedCategory,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearCategory = false,
  }) {
    return FinanceState(
      accounts: accounts ?? this.accounts,
      allocations: allocations ?? this.allocations,
      transactions: transactions ?? this.transactions,
      auditTrail: auditTrail ?? this.auditTrail,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      todaySummary: todaySummary ?? this.todaySummary,
      weekSummary: weekSummary ?? this.weekSummary,
      monthSummary: monthSummary ?? this.monthSummary,
      yearSummary: yearSummary ?? this.yearSummary,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  // ── Computed Getters ───────────────────────────────────────────────────────

  double get totalBalance =>
      accounts.fold(0, (sum, a) => sum + a.currentBalance);

  List<FinanceAccount> get activeAccounts =>
      accounts.where((a) => a.isActive).toList();

  Map<FinanceCategory, List<FinanceTransaction>> get transactionsByCategory {
    final map = <FinanceCategory, List<FinanceTransaction>>{};
    for (final tx in transactions) {
      map.putIfAbsent(tx.category, () => []).add(tx);
    }
    return map;
  }

  BudgetAllocation? latestAllocationFor(FinanceCategory category) {
    return allocationFor(category, selectedPeriod);
  }

  BudgetAllocation? allocationFor(
    FinanceCategory category,
    FinancePeriod period,
  ) {
    final items =
        allocations
            .where((a) => a.category == category && a.period == period)
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return items.isNotEmpty ? items.first : null;
  }

  double spentFor(FinanceCategory category, FinancePeriod period) {
    switch (period) {
      case FinancePeriod.daily:
        return todaySummary.spentFor(category);
      case FinancePeriod.weekly:
        return weekSummary.spentFor(category);
      case FinancePeriod.monthly:
        return monthSummary.spentFor(category);
      case FinancePeriod.yearly:
        return yearSummary.spentFor(category);
    }
  }

  double currentMonthSpentFor(FinanceCategory category) =>
      monthSummary.spentFor(category);

  // Every configured budget for this category, across all periods.
  // Only periods that have an allocation with a positive amount are
  // included — periods with no budget simply don't show up.
  List<BudgetCheck> budgetChecksFor(FinanceCategory category) {
    final checks = <BudgetCheck>[];
    for (final period in FinancePeriod.values) {
      final alloc = allocationFor(category, period);
      if (alloc == null || alloc.allocatedAmount <= 0) continue;
      final spent = spentFor(category, period);
      final pct = FinanceReportHelper.usagePercent(
        spent: spent,
        allocated: alloc.allocatedAmount,
      );
      checks.add(
        BudgetCheck(
          category: category,
          period: period,
          spent: spent,
          allocated: alloc.allocatedAmount,
          usagePercent: pct,
          health: FinanceReportHelper.healthForUsagePercent(pct),
        ),
      );
    }
    return checks;
  }

  List<BudgetCheck> get allBudgetChecks =>
      FinanceCategory.values.expand(budgetChecksFor).toList();

  // Worst-wins across all configured periods for this category. Lets the
  // category card show red if daily is over even when monthly is still fine.
  BudgetHealth worstHealthFor(FinanceCategory category) {
    final checks = budgetChecksFor(category);
    if (checks.isEmpty) return BudgetHealth.healthy;
    return checks.map((c) => c.health).reduce(_worseHealth);
  }

  static BudgetHealth _worseHealth(BudgetHealth a, BudgetHealth b) {
    const order = [
      BudgetHealth.healthy,
      BudgetHealth.warning,
      BudgetHealth.danger,
      BudgetHealth.overBudget,
    ];
    return order.indexOf(a) >= order.indexOf(b) ? a : b;
  }

  double budgetUsagePercent(FinanceCategory category) {
    final alloc = latestAllocationFor(category);
    if (alloc == null || alloc.allocatedAmount <= 0) return 0;
    return FinanceReportHelper.usagePercent(
      spent: spentFor(category, alloc.period),
      allocated: alloc.allocatedAmount,
    );
  }

  BudgetHealth budgetHealthFor(FinanceCategory category) =>
      worstHealthFor(category);

  String budgetInsightFor(FinanceCategory category) {
    final alloc = latestAllocationFor(category);
    return FinanceReportHelper.commentForBudgetUsage(
      category: category,
      spent: alloc == null ? 0 : spentFor(category, alloc.period),
      allocated: alloc?.allocatedAmount ?? 0,
    );
  }

  // One insight per (category, period) check that isn't healthy, plus a
  // fallback "no budget set" entry for categories with zero configured
  // periods so the insights feed still teaches the user what's possible.
  List<BudgetInsight> get allInsights {
    final now = DateTime.now();
    final results = <BudgetInsight>[];

    for (final cat in FinanceCategory.values) {
      final checks = budgetChecksFor(cat);

      if (checks.isEmpty) {
        results.add(
          BudgetInsight(
            id: '${cat.name}_none',
            category: cat,
            health: BudgetHealth.healthy,
            title: cat.label,
            message:
                'No budget set for ${cat.label}. '
                'Add one to get daily/weekly/monthly checks.',
            createdAt: now,
          ),
        );
        continue;
      }

      for (final check in checks) {
        results.add(
          BudgetInsight(
            id: '${cat.name}_${check.period.name}',
            category: cat,
            health: check.health,
            title: '${cat.label} — ${check.period.label}',
            message: FinanceReportHelper.commentForBudgetUsage(
              category: cat,
              spent: check.spent,
              allocated: check.allocated,
            ),
            createdAt: now,
          ),
        );
      }
    }

    return results;
  }

  FinanceAccount? accountFor(FinanceCategory category) {
    final list = accounts
        .where((a) => a.category == category && a.isActive)
        .toList();
    return list.isNotEmpty ? list.first : null;
  }
}

// PeriodSummary copyWith helper (not on the model, keep clean)
extension PeriodSummaryCopyWith on PeriodSummary {
  PeriodSummary copyWith({FinancePeriod? period}) {
    return PeriodSummary(
      period: period ?? this.period,
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalTransfersIn: totalTransfersIn,
      totalTransfersOut: totalTransfersOut,
      netCashFlow: netCashFlow,
      categorySpend: categorySpend,
      categoryIncome: categoryIncome,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class FinanceViewModel extends StateNotifier<FinanceState> {
  final FinanceRepository _repo;

  FinanceViewModel(this._repo) : super(FinanceState.initial()) {
    _load();
  }

  // ── Load & Bootstrap ──────────────────────────────────────────────────────

  void _load() {
    _bootstrapDefaultAccounts();

    final accounts = _repo.loadAccounts();
    final allocations = _repo.loadAllocations();
    final transactions = _repo.loadAllTransactions();
    final auditTrail = _repo.loadAuditTrail();
    final dashboard = _repo.loadDashboardSummary();
    final today = _repo.loadTodaySummary();
    final week = _repo.loadThisWeekSummary();
    final month = _repo.loadThisMonthSummary();
    final year = _repo.loadThisYearSummary();
    final recent = _repo.loadRecentTransactions(days: 30);

    state = state.copyWith(
      accounts: accounts,
      allocations: allocations,
      transactions: transactions,
      auditTrail: auditTrail,
      dashboardSummary: dashboard,
      todaySummary: today,
      weekSummary: week,
      monthSummary: month,
      yearSummary: year,
      recentTransactions: recent,
      isLoading: false,
    );
  }

  void _bootstrapDefaultAccounts() {
    final existing = _repo.loadAccounts();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    for (final cat in FinanceCategory.values) {
      final account = FinanceAccount(
        id: const Uuid().v4(),
        category: cat,
        name: cat.label,
        description: 'Default ${cat.label} account',
        openingBalance: 0,
        currentBalance: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      _repo.saveAccount(account);
    }
  }

  void _recompute() {
    final accounts = _repo.loadAccounts();
    final allocations = _repo.loadAllocations();
    final transactions = _repo.loadAllTransactions();
    final auditTrail = _repo.loadAuditTrail();
    final dashboard = _repo.loadDashboardSummary();
    final today = _repo.loadTodaySummary();
    final week = _repo.loadThisWeekSummary();
    final month = _repo.loadThisMonthSummary();
    final year = _repo.loadThisYearSummary();
    final recent = _repo.loadRecentTransactions(days: 30);

    state = state.copyWith(
      accounts: accounts,
      allocations: allocations,
      transactions: transactions,
      auditTrail: auditTrail,
      dashboardSummary: dashboard,
      todaySummary: today,
      weekSummary: week,
      monthSummary: month,
      yearSummary: year,
      recentTransactions: recent,
    );
  }

  // ── Period / Category Selection ───────────────────────────────────────────

  void selectPeriod(FinancePeriod period) =>
      state = state.copyWith(selectedPeriod: period);

  void selectCategory(FinanceCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  // ── Income ────────────────────────────────────────────────────────────────
  //
  // Every income is auto-split across all five buckets by a fixed ratio:
  //   general   40%   (catch-all — absorbs rounding drift)
  //   saving    20%
  //   investing 15%
  //   emergency 12.5%
  //   travel    12.5%
  //
  // The UI no longer asks for a single category; it shows the split preview
  // and calls [addIncomeSplit]. Non-general portions are rounded to 2 dp,
  // then general is computed as the residual so the sum equals the input
  // amount exactly.

  static const Map<FinanceCategory, double> incomeSplitPercent = {
    FinanceCategory.general: 0.40,
    FinanceCategory.saving: 0.20,
    FinanceCategory.investing: 0.15,
    FinanceCategory.emergency: 0.125,
    FinanceCategory.travel: 0.125,
  };

  static Map<FinanceCategory, double> computeIncomeSplit(double amount) {
    final result = <FinanceCategory, double>{};
    double allocated = 0;
    for (final e in incomeSplitPercent.entries) {
      if (e.key == FinanceCategory.general) continue;
      final portion = double.parse((amount * e.value).toStringAsFixed(2));
      result[e.key] = portion;
      allocated += portion;
    }
    result[FinanceCategory.general] = double.parse(
      (amount - allocated).toStringAsFixed(2),
    );
    return result;
  }

  Future<void> addIncomeSplit({
    required String title,
    required String description,
    required double amount,
    required DateTime date,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? note,
  }) async {
    final now = DateTime.now();
    final splits = computeIncomeSplit(amount);
    final refId = const Uuid().v4();

    for (final entry in splits.entries) {
      final cat = entry.key;
      final portion = entry.value;
      if (portion <= 0) continue;

      final tx = FinanceTransaction(
        id: const Uuid().v4(),
        title: title,
        description: description,
        type: TransactionType.income,
        category: cat,
        amount: portion,
        transactionDate: date,
        paymentMethod: paymentMethod,
        vendor: vendor,
        note: note,
        referenceId: refId,
        createdAt: now,
        updatedAt: now,
      );
      await _repo.saveTransaction(tx);

      final account = await _accountForCategoryOrCreate(cat, now);
      await _repo.saveAccount(
        account.copyWith(
          currentBalance: account.currentBalance + portion,
          updatedAt: now,
        ),
      );
    }

    await _syncBudgetAllocationsFromBalances(now);

    await _saveAudit(
      entityId: refId,
      entityType: 'FinanceTransaction',
      action: AuditAction.created,
      fieldName: 'income_split',
      newValue: '+${amount.toStringAsFixed(2)} split 40/20/15/12.5/12.5',
    );

    await TrackingService.record(TrackingFeature.finance, {
      'logs': 1,
      'income': amount,
    });

    _recompute();
  }

  Future<void> addIncome({
    required String title,
    required String description,
    required FinanceCategory category,
    required double amount,
    required DateTime date,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? note,
  }) async {
    final now = DateTime.now();
    final tx = FinanceTransaction(
      id: const Uuid().v4(),
      title: title,
      description: description,
      type: TransactionType.income,
      category: category,
      amount: amount,
      transactionDate: date,
      paymentMethod: paymentMethod,
      vendor: vendor,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveTransaction(tx);

    // Update account balance
    final account = await _accountForCategoryOrCreate(category, now);
    final updated = account.copyWith(
      currentBalance: account.currentBalance + amount,
      updatedAt: now,
    );
    await _repo.saveAccount(updated);

    await _syncBudgetAllocationsFromBalances(now);

    await _saveAudit(
      entityId: tx.id,
      entityType: 'FinanceTransaction',
      action: AuditAction.created,
      fieldName: 'income',
      newValue: '${category.label}: +${amount.toStringAsFixed(2)}',
    );

    await TrackingService.record(TrackingFeature.finance, {
      'logs': 1,
      'income': amount,
    });

    _recompute();
  }

  // ── Expense ───────────────────────────────────────────────────────────────

  Future<void> addExpense({
    required String title,
    required String description,
    required FinanceCategory category,
    required double amount,
    required DateTime date,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? note,
  }) async {
    final now = DateTime.now();
    final tx = FinanceTransaction(
      id: const Uuid().v4(),
      title: title,
      description: description,
      type: TransactionType.expense,
      category: category,
      amount: amount,
      transactionDate: date,
      paymentMethod: paymentMethod,
      vendor: vendor,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveTransaction(tx);

    // Update account balance
    final account = _repo.loadAccountByCategory(category);
    if (account != null) {
      final updated = account.copyWith(
        currentBalance: account.currentBalance - amount,
        updatedAt: now,
      );
      await _repo.saveAccount(updated);
    }

    await _saveAudit(
      entityId: tx.id,
      entityType: 'FinanceTransaction',
      action: AuditAction.created,
      fieldName: 'expense',
      newValue: '${category.label}: -${amount.toStringAsFixed(2)}',
    );

    await TrackingService.record(TrackingFeature.finance, {
      'logs': 1,
      'expense': amount,
    });

    _recompute();
  }

  // ── Transfer ──────────────────────────────────────────────────────────────

  Future<void> transfer({
    required FinanceCategory fromCategory,
    required FinanceCategory toCategory,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final now = DateTime.now();
    final refId = const Uuid().v4();

    // Transfer-Out from source
    final txOut = FinanceTransaction(
      id: const Uuid().v4(),
      title: 'Transfer to ${toCategory.label}',
      description: 'Transfer from ${fromCategory.label} to ${toCategory.label}',
      type: TransactionType.transferOut,
      category: fromCategory,
      amount: amount,
      transactionDate: date,
      referenceId: refId,
      sourceAccountId: _repo.loadAccountByCategory(fromCategory)?.id,
      destinationAccountId: _repo.loadAccountByCategory(toCategory)?.id,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    // Transfer-In to destination
    final txIn = FinanceTransaction(
      id: const Uuid().v4(),
      title: 'Transfer from ${fromCategory.label}',
      description: 'Transfer from ${fromCategory.label} to ${toCategory.label}',
      type: TransactionType.transferIn,
      category: toCategory,
      amount: amount,
      transactionDate: date,
      referenceId: refId,
      sourceAccountId: _repo.loadAccountByCategory(fromCategory)?.id,
      destinationAccountId: _repo.loadAccountByCategory(toCategory)?.id,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.saveTransaction(txOut);
    await _repo.saveTransaction(txIn);

    // Update source account
    final srcAccount = _repo.loadAccountByCategory(fromCategory);
    if (srcAccount != null) {
      await _repo.saveAccount(
        srcAccount.copyWith(
          currentBalance: srcAccount.currentBalance - amount,
          updatedAt: now,
        ),
      );
    }

    // Update destination account
    final dstAccount = _repo.loadAccountByCategory(toCategory);
    if (dstAccount != null) {
      await _repo.saveAccount(
        dstAccount.copyWith(
          currentBalance: dstAccount.currentBalance + amount,
          updatedAt: now,
        ),
      );
    }

    await _saveAudit(
      entityId: refId,
      entityType: 'Transfer',
      action: AuditAction.created,
      fieldName: 'transfer',
      newValue:
          '${fromCategory.label} → ${toCategory.label}: ${amount.toStringAsFixed(2)}',
    );

    _recompute();
  }

  // ── Account ───────────────────────────────────────────────────────────────

  Future<void> saveAccount(FinanceAccount account) async {
    await _repo.saveAccount(account);
    await _saveAudit(
      entityId: account.id,
      entityType: 'FinanceAccount',
      action: AuditAction.updated,
      fieldName: 'account',
      newValue: account.name,
    );
    _recompute();
  }

  // ── Budget Allocation ─────────────────────────────────────────────────────

  Future<void> saveAllocation(BudgetAllocation allocation) async {
    await _repo.saveAllocation(allocation);
    await _saveAudit(
      entityId: allocation.id,
      entityType: 'BudgetAllocation',
      action: AuditAction.created,
      fieldName: 'allocation',
      newValue:
          '${allocation.category.label}/${allocation.period.label}: ${allocation.allocatedAmount.toStringAsFixed(2)}',
    );
    _recompute();
  }

  Future<void> deleteAllocation(String id) async {
    await _repo.deleteAllocation(id);
    await _saveAudit(
      entityId: id,
      entityType: 'BudgetAllocation',
      action: AuditAction.deleted,
      fieldName: 'allocation',
      oldValue: id,
    );
    _recompute();
  }

  // ── Transaction Update / Delete ───────────────────────────────────────────

  Future<void> updateTransaction({
    required FinanceTransaction updated,
    required FinanceTransaction original,
    String? reason,
  }) async {
    await _repo.saveTransaction(updated);

    // Reverse the original effect on account, apply new effect
    final origAccount = _repo.loadAccountByCategory(original.category);
    if (origAccount != null) {
      double reversalDelta = 0;
      if (original.type == TransactionType.income ||
          original.type == TransactionType.transferIn) {
        reversalDelta -= original.amount;
      } else if (original.type == TransactionType.expense ||
          original.type == TransactionType.transferOut) {
        reversalDelta += original.amount;
      }

      // Apply new transaction effect
      double newDelta = 0;
      if (updated.type == TransactionType.income ||
          updated.type == TransactionType.transferIn) {
        newDelta += updated.amount;
      } else if (updated.type == TransactionType.expense ||
          updated.type == TransactionType.transferOut) {
        newDelta -= updated.amount;
      }

      if (original.category == updated.category) {
        await _repo.saveAccount(
          origAccount.copyWith(
            currentBalance:
                origAccount.currentBalance + reversalDelta + newDelta,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Category changed — update both accounts
        await _repo.saveAccount(
          origAccount.copyWith(
            currentBalance: origAccount.currentBalance + reversalDelta,
            updatedAt: DateTime.now(),
          ),
        );
        final newAccount = _repo.loadAccountByCategory(updated.category);
        if (newAccount != null) {
          await _repo.saveAccount(
            newAccount.copyWith(
              currentBalance: newAccount.currentBalance + newDelta,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    await _saveAudit(
      entityId: updated.id,
      entityType: 'FinanceTransaction',
      action: AuditAction.updated,
      fieldName: 'amount',
      oldValue: original.amount.toStringAsFixed(2),
      newValue: updated.amount.toStringAsFixed(2),
      reason: reason,
    );

    _recompute();
  }

  Future<void> deleteTransaction(
    FinanceTransaction tx, {
    String? reason,
  }) async {
    await _repo.deleteTransaction(tx.id);

    // Reverse the effect on account balance
    final account = _repo.loadAccountByCategory(tx.category);
    if (account != null) {
      double delta = 0;
      if (tx.type == TransactionType.income ||
          tx.type == TransactionType.transferIn) {
        delta = -tx.amount;
      } else if (tx.type == TransactionType.expense ||
          tx.type == TransactionType.transferOut) {
        delta = tx.amount;
      }
      await _repo.saveAccount(
        account.copyWith(
          currentBalance: account.currentBalance + delta,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await _saveAudit(
      entityId: tx.id,
      entityType: 'FinanceTransaction',
      action: AuditAction.deleted,
      fieldName: 'transaction',
      oldValue: '${tx.title}: ${tx.amount.toStringAsFixed(2)}',
      reason: reason,
    );

    _recompute();
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  Future<void> _saveAudit({
    required String entityId,
    required String entityType,
    required AuditAction action,
    required String fieldName,
    String? oldValue,
    String? newValue,
    String? reason,
  }) async {
    final entry = AuditTrailEntry(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      action: action,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      timestamp: DateTime.now(),
      reason: reason,
    );
    await _repo.saveAuditEntry(entry);
  }

  Future<FinanceAccount> _accountForCategoryOrCreate(
    FinanceCategory category,
    DateTime now,
  ) async {
    final existing = _repo.loadAccountByCategory(category);
    if (existing != null) return existing;

    final account = FinanceAccount(
      id: const Uuid().v4(),
      category: category,
      name: category.label,
      description: 'Default ${category.label} account',
      openingBalance: 0,
      currentBalance: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveAccount(account);
    return account;
  }

  Future<void> _syncBudgetAllocationsFromBalances(DateTime now) async {
    final accounts = _repo.loadActiveAccounts();
    for (final account in accounts) {
      if (account.currentBalance <= 0) continue;
      final amounts = _budgetAmountsFromMonthly(account.currentBalance);
      for (final entry in amounts.entries) {
        final existing = _latestAllocationForCurrentPeriod(
          account.category,
          entry.key,
          now,
        );
        await _repo.saveAllocation(
          BudgetAllocation(
            id: existing?.id ?? const Uuid().v4(),
            category: account.category,
            period: entry.key,
            startDate: _periodStart(entry.key, now),
            endDate: _periodEnd(entry.key, now),
            allocatedAmount: entry.value,
            note: existing?.note,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
      }
    }
  }

  BudgetAllocation? _latestAllocationForCurrentPeriod(
    FinanceCategory category,
    FinancePeriod period,
    DateTime now,
  ) {
    final start = _periodStart(period, now);
    final items =
        _repo
            .loadAllocations()
            .where(
              (a) =>
                  a.category == category &&
                  a.period == period &&
                  a.startDate.year == start.year &&
                  a.startDate.month == start.month &&
                  a.startDate.day == start.day,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items.isNotEmpty ? items.first : null;
  }

  Map<FinancePeriod, double> _budgetAmountsFromMonthly(double monthlyAmount) {
    return {
      FinancePeriod.daily: double.parse(
        (monthlyAmount / 30).toStringAsFixed(2),
      ),
      FinancePeriod.weekly: double.parse(
        (monthlyAmount * 7 / 30).toStringAsFixed(2),
      ),
      FinancePeriod.monthly: double.parse(monthlyAmount.toStringAsFixed(2)),
    };
  }

  DateTime _periodStart(FinancePeriod period, DateTime now) {
    switch (period) {
      case FinancePeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case FinancePeriod.weekly:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
      case FinancePeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case FinancePeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _periodEnd(FinancePeriod period, DateTime now) {
    switch (period) {
      case FinancePeriod.daily:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case FinancePeriod.weekly:
        return _periodStart(
          period,
          now,
        ).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case FinancePeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case FinancePeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

  // ── Statement Builders ────────────────────────────────────────────────────

  FinancialStatement buildMonthlyStatement({int? year, int? month}) {
    final now = DateTime.now();
    return _repo.buildMonthlyStatement(
      year: year ?? now.year,
      month: month ?? now.month,
    );
  }

  FinancialStatement buildDailyStatement({DateTime? date}) =>
      _repo.buildDailyStatement(date: date ?? DateTime.now());

  FinancialStatement buildWeeklyStatement({DateTime? date}) =>
      _repo.buildWeeklyStatement(weekDate: date ?? DateTime.now());
}

// ── Providers ─────────────────────────────────────────────────────────────────

final financeRepositoryProvider = Provider<FinanceRepository>(
  (_) => FinanceRepository(),
);

final financeViewModelProvider =
    StateNotifierProvider<FinanceViewModel, FinanceState>(
      (ref) => FinanceViewModel(ref.read(financeRepositoryProvider)),
    );
