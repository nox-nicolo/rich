import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/finance_models.dart';

class FinanceRepository {
  static const String _accountsKey = 'finance_accounts';
  static const String _allocationsKey = 'finance_allocations';
  static const String _transactionsKey = 'finance_transactions';
  static const String _auditTrailKey = 'finance_audit_trail';

  static const String accountEntityType = 'finance_account';
  static const String allocationEntityType = 'finance_allocation';
  static const String transactionEntityType = 'finance_transaction';
  static const String auditEntryEntityType = 'finance_audit_entry';

  // ── Accounts ──────────────────────────────────────────────────────────────

  Future<void> saveAccount(FinanceAccount account) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_accountsKey, defaultValue: []) as List,
    );

    final index = existing.indexWhere((e) => (e as Map)['id'] == account.id);
    if (index >= 0) {
      existing[index] = account.toMap();
    } else {
      existing.add(account.toMap());
    }

    await box.put(_accountsKey, existing);
  }

  List<FinanceAccount> loadAccounts() {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> raw = List.from(
      box.get(_accountsKey, defaultValue: []) as List,
    );

    return raw
        .map((e) => FinanceAccount.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<FinanceAccount> loadActiveAccounts() {
    return loadAccounts().where((a) => a.isActive).toList();
  }

  FinanceAccount? loadAccountByCategory(FinanceCategory category) {
    final accounts = loadAccounts()
        .where((a) => a.category == category && a.isActive)
        .toList();

    return accounts.isNotEmpty ? accounts.first : null;
  }

  FinanceAccount? loadAccountById(String id) {
    final accounts = loadAccounts().where((a) => a.id == id).toList();
    return accounts.isNotEmpty ? accounts.first : null;
  }

  Future<void> deleteAccount(String id) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_accountsKey, defaultValue: []) as List,
    );

    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_accountsKey, existing);
  }

  Future<void> removeLocalAccount(String id) => deleteAccount(id);

  // ── Budget Allocations ────────────────────────────────────────────────────

  Future<void> saveAllocation(BudgetAllocation allocation) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_allocationsKey, defaultValue: []) as List,
    );

    final index = existing.indexWhere((e) => (e as Map)['id'] == allocation.id);
    if (index >= 0) {
      existing[index] = allocation.toMap();
    } else {
      existing.add(allocation.toMap());
    }

    await box.put(_allocationsKey, existing);
  }

  List<BudgetAllocation> loadAllocations() {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> raw = List.from(
      box.get(_allocationsKey, defaultValue: []) as List,
    );

    return raw
        .map(
          (e) => BudgetAllocation.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  List<BudgetAllocation> loadAllocationsForPeriod(FinancePeriod period) {
    return loadAllocations().where((a) => a.period == period).toList();
  }

  BudgetAllocation? loadLatestAllocationForCategory(
    FinanceCategory category,
    FinancePeriod period,
  ) {
    final items =
        loadAllocations()
            .where((a) => a.category == category && a.period == period)
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return items.isNotEmpty ? items.first : null;
  }

  Future<void> deleteAllocation(String id) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_allocationsKey, defaultValue: []) as List,
    );

    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_allocationsKey, existing);
  }

  Future<void> removeLocalAllocation(String id) => deleteAllocation(id);

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<void> saveTransaction(FinanceTransaction transaction) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_transactionsKey, defaultValue: []) as List,
    );

    final index = existing.indexWhere(
      (e) => (e as Map)['id'] == transaction.id,
    );
    if (index >= 0) {
      existing[index] = transaction.toMap();
    } else {
      existing.add(transaction.toMap());
    }

    await box.put(_transactionsKey, existing);
  }

  List<FinanceTransaction> loadAllTransactions() {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> raw = List.from(
      box.get(_transactionsKey, defaultValue: []) as List,
    );

    return raw
        .map(
          (e) =>
              FinanceTransaction.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  FinanceTransaction? loadTransactionById(String id) {
    final items = loadAllTransactions().where((t) => t.id == id).toList();
    return items.isNotEmpty ? items.first : null;
  }

  List<FinanceTransaction> loadTransactionsByCategory(
    FinanceCategory category,
  ) {
    return loadAllTransactions().where((t) => t.category == category).toList();
  }

  List<FinanceTransaction> loadTransactionsByType(TransactionType type) {
    return loadAllTransactions().where((t) => t.type == type).toList();
  }

  List<FinanceTransaction> loadTransactionsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return loadAllTransactions()
        .where(
          (t) =>
              !t.transactionDate.isBefore(start) &&
              !t.transactionDate.isAfter(end),
        )
        .toList();
  }

  List<FinanceTransaction> loadTodayTransactions() {
    final now = DateTime.now();
    return loadAllTransactions()
        .where(
          (t) =>
              t.transactionDate.year == now.year &&
              t.transactionDate.month == now.month &&
              t.transactionDate.day == now.day,
        )
        .toList();
  }

  List<FinanceTransaction> loadThisWeekTransactions() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return loadTransactionsInRange(start: startOfWeek, end: endOfWeek);
  }

  List<FinanceTransaction> loadThisMonthTransactions() {
    final now = DateTime.now();
    return loadAllTransactions()
        .where(
          (t) =>
              t.transactionDate.year == now.year &&
              t.transactionDate.month == now.month,
        )
        .toList();
  }

  List<FinanceTransaction> loadRecentTransactions({int days = 31}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return loadAllTransactions()
        .where((t) => t.transactionDate.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  Future<void> deleteTransaction(String id) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_transactionsKey, defaultValue: []) as List,
    );

    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_transactionsKey, existing);
  }

  Future<void> removeLocalTransaction(String id) => deleteTransaction(id);

  // ── Audit Trail ───────────────────────────────────────────────────────────

  Future<void> saveAuditEntry(AuditTrailEntry entry) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_auditTrailKey, defaultValue: []) as List,
    );

    final index = existing.indexWhere((e) => (e as Map)['id'] == entry.id);
    if (index >= 0) {
      existing[index] = entry.toMap();
    } else {
      existing.add(entry.toMap());
    }

    // keep recent history manageable but still useful
    if (existing.length > 2000) {
      existing.removeAt(0);
    }

    await box.put(_auditTrailKey, existing);
  }

  List<AuditTrailEntry> loadAuditTrail() {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> raw = List.from(
      box.get(_auditTrailKey, defaultValue: []) as List,
    );

    return raw
        .map(
          (e) => AuditTrailEntry.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AuditTrailEntry> loadAuditTrailForEntity(String entityId) {
    return loadAuditTrail().where((e) => e.entityId == entityId).toList();
  }

  Future<void> clearAuditTrail() async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    await box.put(_auditTrailKey, <dynamic>[]);
  }

  Future<void> removeLocalAuditEntry(String id) async {
    final box = HiveService.box(HiveBoxes.financeLogs);
    final List<dynamic> existing = List.from(
      box.get(_auditTrailKey, defaultValue: []) as List,
    );

    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_auditTrailKey, existing);
  }

  // ── Reports / Helpers ─────────────────────────────────────────────────────

  PeriodSummary loadTodaySummary() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return FinanceReportHelper.buildSummary(
      period: FinancePeriod.daily,
      startDate: start,
      endDate: end,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  PeriodSummary loadThisWeekSummary() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final end = start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return FinanceReportHelper.buildSummary(
      period: FinancePeriod.weekly,
      startDate: start,
      endDate: end,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  PeriodSummary loadThisMonthSummary() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return FinanceReportHelper.buildSummary(
      period: FinancePeriod.monthly,
      startDate: start,
      endDate: end,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  PeriodSummary loadThisYearSummary() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);

    return FinanceReportHelper.buildSummary(
      period: FinancePeriod.yearly,
      startDate: start,
      endDate: end,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  FinanceDashboardSummary loadDashboardSummary() {
    return FinanceReportHelper.buildDashboardSummary(
      accounts: loadAccounts(),
      transactions: loadAllTransactions(),
    );
  }

  FinancialStatement buildMonthlyStatement({
    required int year,
    required int month,
    String id = 'monthly_statement',
    double openingBalance = 0,
  }) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return FinanceReportHelper.buildStatement(
      id: '$id-$year-$month',
      period: FinancePeriod.monthly,
      startDate: start,
      endDate: end,
      openingBalance: openingBalance,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  FinancialStatement buildWeeklyStatement({
    required DateTime weekDate,
    String id = 'weekly_statement',
    double openingBalance = 0,
  }) {
    final start = DateTime(
      weekDate.year,
      weekDate.month,
      weekDate.day,
    ).subtract(Duration(days: weekDate.weekday - 1));
    final end = start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return FinanceReportHelper.buildStatement(
      id: '$id-${start.toIso8601String()}',
      period: FinancePeriod.weekly,
      startDate: start,
      endDate: end,
      openingBalance: openingBalance,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }

  FinancialStatement buildDailyStatement({
    required DateTime date,
    String id = 'daily_statement',
    double openingBalance = 0,
  }) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return FinanceReportHelper.buildStatement(
      id: '$id-${start.toIso8601String()}',
      period: FinancePeriod.daily,
      startDate: start,
      endDate: end,
      openingBalance: openingBalance,
      transactions: loadTransactionsInRange(start: start, end: end),
    );
  }
}
