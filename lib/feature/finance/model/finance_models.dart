import 'dart:convert';

enum FinanceCategory {
  general,
  investing,
  saving,
  emergency,
  travel,
}

extension FinanceCategoryX on FinanceCategory {
  String get label {
    switch (this) {
      case FinanceCategory.general:
        return 'General';
      case FinanceCategory.investing:
        return 'Investing';
      case FinanceCategory.saving:
        return 'Saving';
      case FinanceCategory.emergency:
        return 'Emergency';
      case FinanceCategory.travel:
        return 'Travel';
    }
  }

  String get key => name;

  static FinanceCategory fromString(String value) {
    return FinanceCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FinanceCategory.general,
    );
  }
}

enum TransactionType {
  income,
  expense,
  transferIn,
  transferOut,
  adjustment,
}

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transferIn:
        return 'Transfer In';
      case TransactionType.transferOut:
        return 'Transfer Out';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String get key => name;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

enum FinancePeriod {
  daily,
  weekly,
  monthly,
  yearly,
}

extension FinancePeriodX on FinancePeriod {
  String get label {
    switch (this) {
      case FinancePeriod.daily:
        return 'Daily';
      case FinancePeriod.weekly:
        return 'Weekly';
      case FinancePeriod.monthly:
        return 'Monthly';
      case FinancePeriod.yearly:
        return 'Yearly';
    }
  }

  String get key => name;

  static FinancePeriod fromString(String value) {
    return FinancePeriod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FinancePeriod.monthly,
    );
  }
}

enum AuditAction {
  created,
  updated,
  deleted,
}

extension AuditActionX on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.created:
        return 'Created';
      case AuditAction.updated:
        return 'Updated';
      case AuditAction.deleted:
        return 'Deleted';
    }
  }

  String get key => name;

  static AuditAction fromString(String value) {
    return AuditAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuditAction.created,
    );
  }
}

enum BudgetHealth {
  healthy,
  warning,
  danger,
  overBudget,
}

extension BudgetHealthX on BudgetHealth {
  String get label {
    switch (this) {
      case BudgetHealth.healthy:
        return 'Healthy';
      case BudgetHealth.warning:
        return 'Warning';
      case BudgetHealth.danger:
        return 'Danger';
      case BudgetHealth.overBudget:
        return 'Over Budget';
    }
  }

  String get key => name;

  static BudgetHealth fromString(String value) {
    return BudgetHealth.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BudgetHealth.healthy,
    );
  }
}

enum PaymentMethod {
  cash,
  mobileMoney,
  bank,
  card,
  other,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get key => name;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.other,
    );
  }
}

class FinanceAccount {
  final String id;
  final FinanceCategory category;
  final String name;
  final String description;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinanceAccount({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  FinanceAccount copyWith({
    String? id,
    FinanceCategory? category,
    String? name,
    String? description,
    double? openingBalance,
    double? currentBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceAccount(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get netChange => currentBalance - openingBalance;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'name': name,
      'description': description,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceAccount.fromMap(Map<String, dynamic> map) {
    return FinanceAccount(
      id: map['id'] ?? '',
      category: FinanceCategoryX.fromString(map['category'] ?? 'general'),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      openingBalance: (map['openingBalance'] ?? 0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FinanceAccount.fromJson(String source) =>
      FinanceAccount.fromMap(jsonDecode(source));
}

class BudgetAllocation {
  final String id;
  final FinanceCategory category;
  final FinancePeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double allocatedAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetAllocation({
    required this.id,
    required this.category,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.allocatedAmount,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  BudgetAllocation copyWith({
    String? id,
    FinanceCategory? category,
    FinancePeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? allocatedAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetAllocation(
      id: id ?? this.id,
      category: category ?? this.category,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'allocatedAmount': allocatedAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BudgetAllocation.fromMap(Map<String, dynamic> map) {
    return BudgetAllocation(
      id: map['id'] ?? '',
      category: FinanceCategoryX.fromString(map['category'] ?? 'general'),
      period: FinancePeriodX.fromString(map['period'] ?? 'monthly'),
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      allocatedAmount: (map['allocatedAmount'] ?? 0).toDouble(),
      note: map['note'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BudgetAllocation.fromJson(String source) =>
      BudgetAllocation.fromMap(jsonDecode(source));
}

class FinanceTransaction {
  final String id;
  final String title;
  final String description;
  final TransactionType type;
  final FinanceCategory category;
  final double amount;
  final DateTime transactionDate;
  final String? referenceId;
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String? vendor;
  final PaymentMethod? paymentMethod;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinanceTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.referenceId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.vendor,
    this.paymentMethod,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  FinanceTransaction copyWith({
    String? id,
    String? title,
    String? description,
    TransactionType? type,
    FinanceCategory? category,
    double? amount,
    DateTime? transactionDate,
    String? referenceId,
    String? sourceAccountId,
    String? destinationAccountId,
    String? vendor,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      referenceId: referenceId ?? this.referenceId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      vendor: vendor ?? this.vendor,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isIncome => type == TransactionType.income || type == TransactionType.transferIn;
  bool get isExpense => type == TransactionType.expense || type == TransactionType.transferOut;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'referenceId': referenceId,
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'vendor': vendor,
      'paymentMethod': paymentMethod?.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: TransactionTypeX.fromString(map['type'] ?? 'expense'),
      category: FinanceCategoryX.fromString(map['category'] ?? 'general'),
      amount: (map['amount'] ?? 0).toDouble(),
      transactionDate:
          DateTime.tryParse(map['transactionDate'] ?? '') ?? DateTime.now(),
      referenceId: map['referenceId'],
      sourceAccountId: map['sourceAccountId'],
      destinationAccountId: map['destinationAccountId'],
      vendor: map['vendor'],
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethodX.fromString(map['paymentMethod'])
          : null,
      note: map['note'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FinanceTransaction.fromJson(String source) =>
      FinanceTransaction.fromMap(jsonDecode(source));
}

class AuditTrailEntry {
  final String id;
  final String entityId;
  final String entityType;
  final AuditAction action;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;
  final String? reason;

  const AuditTrailEntry({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.action,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'action': action.name,
      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
    };
  }

  factory AuditTrailEntry.fromMap(Map<String, dynamic> map) {
    return AuditTrailEntry(
      id: map['id'] ?? '',
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      action: AuditActionX.fromString(map['action'] ?? 'created'),
      fieldName: map['fieldName'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      reason: map['reason'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AuditTrailEntry.fromJson(String source) =>
      AuditTrailEntry.fromMap(jsonDecode(source));
}

// One period's worth of "are we over budget?" for a category.
// Used to check each configured period (daily, weekly, monthly, yearly)
// independently so a category in good shape for the month can still flag
// when it has blown the daily or weekly limit.
class BudgetCheck {
  final FinanceCategory category;
  final FinancePeriod period;
  final double spent;
  final double allocated;
  final double usagePercent; // not clamped — >1 means overspent
  final BudgetHealth health;

  const BudgetCheck({
    required this.category,
    required this.period,
    required this.spent,
    required this.allocated,
    required this.usagePercent,
    required this.health,
  });

  bool get isOverBudget => health == BudgetHealth.overBudget;
  double get remaining => allocated - spent;
  double get displayPercent => usagePercent.clamp(0.0, 1.0);
}

class BudgetInsight {
  final String id;
  final FinanceCategory category;
  final BudgetHealth health;
  final String title;
  final String message;
  final DateTime createdAt;

  const BudgetInsight({
    required this.id,
    required this.category,
    required this.health,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'health': health.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BudgetInsight.fromMap(Map<String, dynamic> map) {
    return BudgetInsight(
      id: map['id'] ?? '',
      category: FinanceCategoryX.fromString(map['category'] ?? 'general'),
      health: BudgetHealthX.fromString(map['health'] ?? 'healthy'),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BudgetInsight.fromJson(String source) =>
      BudgetInsight.fromMap(jsonDecode(source));
}

class PeriodSummary {
  final FinancePeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpenses;
  final double totalTransfersIn;
  final double totalTransfersOut;
  final double netCashFlow;
  final Map<FinanceCategory, double> categorySpend;
  final Map<FinanceCategory, double> categoryIncome;

  const PeriodSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalTransfersIn,
    required this.totalTransfersOut,
    required this.netCashFlow,
    required this.categorySpend,
    required this.categoryIncome,
  });

  double spentFor(FinanceCategory category) => categorySpend[category] ?? 0;
  double incomeFor(FinanceCategory category) => categoryIncome[category] ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalTransfersIn': totalTransfersIn,
      'totalTransfersOut': totalTransfersOut,
      'netCashFlow': netCashFlow,
      'categorySpend':
          categorySpend.map((key, value) => MapEntry(key.name, value)),
      'categoryIncome':
          categoryIncome.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory PeriodSummary.fromMap(Map<String, dynamic> map) {
    return PeriodSummary(
      period: FinancePeriodX.fromString(map['period'] ?? 'monthly'),
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      totalIncome: (map['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (map['totalExpenses'] ?? 0).toDouble(),
      totalTransfersIn: (map['totalTransfersIn'] ?? 0).toDouble(),
      totalTransfersOut: (map['totalTransfersOut'] ?? 0).toDouble(),
      netCashFlow: (map['netCashFlow'] ?? 0).toDouble(),
      categorySpend: _categoryDoubleMapFromDynamic(map['categorySpend']),
      categoryIncome: _categoryDoubleMapFromDynamic(map['categoryIncome']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PeriodSummary.fromJson(String source) =>
      PeriodSummary.fromMap(jsonDecode(source));
}

class FinancialStatement {
  final String id;
  final FinancePeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalance;
  final double totalIncome;
  final double totalExpenses;
  final double totalTransfers;
  final double closingBalance;
  final List<FinanceTransaction> transactions;
  final DateTime generatedAt;

  const FinancialStatement({
    required this.id,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalTransfers,
    required this.closingBalance,
    required this.transactions,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'openingBalance': openingBalance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalTransfers': totalTransfers,
      'closingBalance': closingBalance,
      'transactions': transactions.map((e) => e.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory FinancialStatement.fromMap(Map<String, dynamic> map) {
    return FinancialStatement(
      id: map['id'] ?? '',
      period: FinancePeriodX.fromString(map['period'] ?? 'monthly'),
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      openingBalance: (map['openingBalance'] ?? 0).toDouble(),
      totalIncome: (map['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (map['totalExpenses'] ?? 0).toDouble(),
      totalTransfers: (map['totalTransfers'] ?? 0).toDouble(),
      closingBalance: (map['closingBalance'] ?? 0).toDouble(),
      transactions: (map['transactions'] as List? ?? [])
          .map((e) => FinanceTransaction.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      generatedAt: DateTime.tryParse(map['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FinancialStatement.fromJson(String source) =>
      FinancialStatement.fromMap(jsonDecode(source));
}

class FinanceDashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final double totalSaved;
  final double totalInvested;
  final double totalEmergencyReserved;
  final double totalTravelReserved;
  final double totalGeneralAvailable;

  const FinanceDashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSaved,
    required this.totalInvested,
    required this.totalEmergencyReserved,
    required this.totalTravelReserved,
    required this.totalGeneralAvailable,
  });

  double get netCashFlow => totalIncome - totalExpenses;

  Map<String, dynamic> toMap() {
    return {
      'totalBalance': totalBalance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalSaved': totalSaved,
      'totalInvested': totalInvested,
      'totalEmergencyReserved': totalEmergencyReserved,
      'totalTravelReserved': totalTravelReserved,
      'totalGeneralAvailable': totalGeneralAvailable,
    };
  }

  factory FinanceDashboardSummary.fromMap(Map<String, dynamic> map) {
    return FinanceDashboardSummary(
      totalBalance: (map['totalBalance'] ?? 0).toDouble(),
      totalIncome: (map['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (map['totalExpenses'] ?? 0).toDouble(),
      totalSaved: (map['totalSaved'] ?? 0).toDouble(),
      totalInvested: (map['totalInvested'] ?? 0).toDouble(),
      totalEmergencyReserved: (map['totalEmergencyReserved'] ?? 0).toDouble(),
      totalTravelReserved: (map['totalTravelReserved'] ?? 0).toDouble(),
      totalGeneralAvailable: (map['totalGeneralAvailable'] ?? 0).toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FinanceDashboardSummary.fromJson(String source) =>
      FinanceDashboardSummary.fromMap(jsonDecode(source));
}

class FinanceReportHelper {
  const FinanceReportHelper._();

  static PeriodSummary buildSummary({
    required FinancePeriod period,
    required DateTime startDate,
    required DateTime endDate,
    required List<FinanceTransaction> transactions,
  }) {
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalTransfersIn = 0;
    double totalTransfersOut = 0;

    final Map<FinanceCategory, double> spend = {
      for (final c in FinanceCategory.values) c: 0,
    };
    final Map<FinanceCategory, double> income = {
      for (final c in FinanceCategory.values) c: 0,
    };

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          totalIncome += tx.amount;
          income[tx.category] = (income[tx.category] ?? 0) + tx.amount;
          break;
        case TransactionType.expense:
          totalExpenses += tx.amount;
          spend[tx.category] = (spend[tx.category] ?? 0) + tx.amount;
          break;
        case TransactionType.transferIn:
          totalTransfersIn += tx.amount;
          break;
        case TransactionType.transferOut:
          totalTransfersOut += tx.amount;
          break;
        case TransactionType.adjustment:
          break;
      }
    }

    return PeriodSummary(
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalTransfersIn: totalTransfersIn,
      totalTransfersOut: totalTransfersOut,
      netCashFlow: totalIncome - totalExpenses,
      categorySpend: spend,
      categoryIncome: income,
    );
  }

  static FinanceDashboardSummary buildDashboardSummary({
    required List<FinanceAccount> accounts,
    required List<FinanceTransaction> transactions,
  }) {
    final totalBalance = accounts.fold<double>(
      0,
      (sum, a) => sum + a.currentBalance,
    );

    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpenses += tx.amount;
      }
    }

    double categoryBalance(FinanceCategory category) {
      return accounts
          .where((a) => a.category == category)
          .fold<double>(0, (sum, a) => sum + a.currentBalance);
    }

    return FinanceDashboardSummary(
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSaved: categoryBalance(FinanceCategory.saving),
      totalInvested: categoryBalance(FinanceCategory.investing),
      totalEmergencyReserved: categoryBalance(FinanceCategory.emergency),
      totalTravelReserved: categoryBalance(FinanceCategory.travel),
      totalGeneralAvailable: categoryBalance(FinanceCategory.general),
    );
  }

  static double usagePercent({
    required double spent,
    required double allocated,
  }) {
    if (allocated <= 0) return 0;
    // Intentionally NOT clamped — callers rendering a progress bar should
    // clamp on their side. Clamping here made [healthForUsagePercent] unable
    // to ever return [BudgetHealth.overBudget].
    return spent / allocated;
  }

  static BudgetHealth healthForUsagePercent(double percent) {
    if (percent > 1) return BudgetHealth.overBudget;
    if (percent >= 0.85) return BudgetHealth.danger;
    if (percent >= 0.65) return BudgetHealth.warning;
    return BudgetHealth.healthy;
  }

  static String commentForBudgetUsage({
    required FinanceCategory category,
    required double spent,
    required double allocated,
  }) {
    if (allocated <= 0) {
      return 'No budget allocation set for ${category.label} yet.';
    }

    final percent = spent / allocated;

    if (percent > 1) {
      return 'You have exceeded your ${category.label} budget. Reduce spending immediately.';
    }
    if (percent >= 0.85) {
      return 'Your ${category.label} budget is almost exhausted. Slow down spending.';
    }
    if (percent >= 0.65) {
      return 'Your ${category.label} budget usage is rising. Spend carefully.';
    }
    if (percent >= 0.35) {
      return 'Your ${category.label} budget usage is currently healthy.';
    }
    return 'Your ${category.label} budget is under control and still has room.';
  }

  static FinancialStatement buildStatement({
    required String id,
    required FinancePeriod period,
    required DateTime startDate,
    required DateTime endDate,
    required double openingBalance,
    required List<FinanceTransaction> transactions,
  }) {
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalTransfers = 0;

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          totalIncome += tx.amount;
          break;
        case TransactionType.expense:
          totalExpenses += tx.amount;
          break;
        case TransactionType.transferIn:
        case TransactionType.transferOut:
          totalTransfers += tx.amount;
          break;
        case TransactionType.adjustment:
          break;
      }
    }

    final closingBalance = openingBalance + totalIncome - totalExpenses;

    return FinancialStatement(
      id: id,
      period: period,
      startDate: startDate,
      endDate: endDate,
      openingBalance: openingBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalTransfers: totalTransfers,
      closingBalance: closingBalance,
      transactions: transactions,
      generatedAt: DateTime.now(),
    );
  }
}

Map<FinanceCategory, double> _categoryDoubleMapFromDynamic(dynamic raw) {
  if (raw is! Map) return {};
  final result = <FinanceCategory, double>{};
  raw.forEach((key, value) {
    result[FinanceCategoryX.fromString(key.toString())] =
        (value ?? 0).toDouble();
  });
  return result;
}