// lib/features/betting/model/bet_model.dart

enum BetStatus { active, won, lost, void_, pending, cashout }

extension BetStatusX on BetStatus {
  String get label {
    switch (this) {
      case BetStatus.active:
        return 'Active';
      case BetStatus.won:
        return 'Won';
      case BetStatus.lost:
        return 'Lost';
      case BetStatus.void_:
        return 'Void';
      case BetStatus.pending:
        return 'Pending';
      case BetStatus.cashout:
        return 'Cashout';
    }
  }
}

enum BetType { single, accumulator, system }

extension BetTypeX on BetType {
  String get label {
    switch (this) {
      case BetType.single:
        return 'Single';
      case BetType.accumulator:
        return 'Accumulator';
      case BetType.system:
        return 'System';
    }
  }
}

class BetModel {
  final String id;
  final String description;
  final BetType type;
  final BetStatus status;
  final double stake;
  final double odds;
  final DateTime placedAt;
  final DateTime? settledAt;
  final String? ruleConfirmation;
  final String? reasoning;
  final bool ruleChecked;
  final double? potentialReturn;
  final double? actualReturn;

  const BetModel({
    required this.id,
    required this.description,
    required this.type,
    required this.status,
    required this.stake,
    required this.odds,
    required this.placedAt,
    this.settledAt,
    this.ruleConfirmation,
    this.reasoning,
    this.ruleChecked = false,
    this.potentialReturn,
    this.actualReturn,
  });

  double get calculatedPotentialReturn => stake * odds;

  bool get isActive => status == BetStatus.active;
  bool get isSettled =>
      status == BetStatus.won ||
      status == BetStatus.lost ||
      status == BetStatus.cashout;

  double get profitLoss {
    if (status == BetStatus.won) {
      return (actualReturn ?? calculatedPotentialReturn) - stake;
    }
    if (status == BetStatus.lost) return -stake;
    if (status == BetStatus.cashout) return (actualReturn ?? 0) - stake;
    return 0;
  }

  BetModel copyWith({
    BetStatus? status,
    DateTime? settledAt,
    double? actualReturn,
  }) {
    return BetModel(
      id: id,
      description: description,
      type: type,
      status: status ?? this.status,
      stake: stake,
      odds: odds,
      placedAt: placedAt,
      settledAt: settledAt ?? this.settledAt,
      ruleConfirmation: ruleConfirmation,
      reasoning: reasoning,
      ruleChecked: ruleChecked,
      potentialReturn: potentialReturn,
      actualReturn: actualReturn ?? this.actualReturn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'type': type.index,
      'status': status.index,
      'stake': stake,
      'odds': odds,
      'placedAt': placedAt.toIso8601String(),
      'settledAt': settledAt?.toIso8601String(),
      'ruleConfirmation': ruleConfirmation,
      'reasoning': reasoning,
      'ruleChecked': ruleChecked,
      'potentialReturn': potentialReturn,
      'actualReturn': actualReturn,
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> m) {
    return BetModel(
      id: m['id'] as String,
      description: m['description'] as String,
      type: BetType.values[m['type'] as int],
      status: BetStatus.values[m['status'] as int],
      stake: (m['stake'] as num).toDouble(),
      odds: (m['odds'] as num).toDouble(),
      placedAt: DateTime.parse(m['placedAt'] as String),
      settledAt: m['settledAt'] != null
          ? DateTime.parse(m['settledAt'] as String)
          : null,
      ruleConfirmation: m['ruleConfirmation'] as String?,
      reasoning: m['reasoning'] as String?,
      ruleChecked: m['ruleChecked'] as bool? ?? false,
      potentialReturn: (m['potentialReturn'] as num?)?.toDouble(),
      actualReturn: (m['actualReturn'] as num?)?.toDouble(),
    );
  }
}
