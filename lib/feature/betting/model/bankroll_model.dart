// lib/features/betting/model/bankroll_model.dart

class BankrollModel {
  final double startingBalance;
  final double currentBalance;
  final double dailyStopLimit;
  final double maxStakePercent;
  final double weeklyTarget;
  final DateTime lastUpdated;

  const BankrollModel({
    required this.startingBalance,
    required this.currentBalance,
    required this.dailyStopLimit,
    required this.maxStakePercent,
    required this.weeklyTarget,
    required this.lastUpdated,
  });

  factory BankrollModel.initial({double startingAmount = 1000}) {
    return BankrollModel(
      startingBalance: startingAmount,
      currentBalance: startingAmount,
      dailyStopLimit: startingAmount * 0.05,
      maxStakePercent: 0.02,
      weeklyTarget: startingAmount * 0.10,
      lastUpdated: DateTime.now(),
    );
  }

  double get maxStakeAmount => currentBalance * maxStakePercent;

  double get profitLoss => currentBalance - startingBalance;

  double get profitLossPercent =>
      startingBalance > 0 ? (profitLoss / startingBalance) * 100 : 0;

  bool get isInProfit => profitLoss > 0;

  bool get isAtDailyStopLimit => profitLoss <= -dailyStopLimit;

  BankrollModel copyWith({
    double? currentBalance,
    double? dailyStopLimit,
    double? maxStakePercent,
    double? weeklyTarget,
  }) {
    return BankrollModel(
      startingBalance: startingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      dailyStopLimit: dailyStopLimit ?? this.dailyStopLimit,
      maxStakePercent: maxStakePercent ?? this.maxStakePercent,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      lastUpdated: DateTime.now(),
    );
  }

  BankrollModel adjustBalance(double amount) {
    return copyWith(currentBalance: currentBalance + amount);
  }

  Map<String, dynamic> toMap() {
    return {
      'startingBalance': startingBalance,
      'currentBalance': currentBalance,
      'dailyStopLimit': dailyStopLimit,
      'maxStakePercent': maxStakePercent,
      'weeklyTarget': weeklyTarget,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BankrollModel.fromMap(Map<String, dynamic> m) {
    return BankrollModel(
      startingBalance: (m['startingBalance'] as num).toDouble(),
      currentBalance: (m['currentBalance'] as num).toDouble(),
      dailyStopLimit: (m['dailyStopLimit'] as num).toDouble(),
      maxStakePercent: (m['maxStakePercent'] as num).toDouble(),
      weeklyTarget: (m['weeklyTarget'] as num).toDouble(),
      lastUpdated: DateTime.parse(m['lastUpdated'] as String),
    );
  }
}
