// lib/features/trading/model/trading_models.dart

// ── Trading Rule ──────────────────────────────────────────────────────────────

class TradingRule {
  final String id;
  final String title;
  final String description;
  final bool isNoTradeRule;
  final bool active;

  const TradingRule({
    required this.id,
    required this.title,
    required this.description,
    this.isNoTradeRule = false,
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
    'id':           id,
    'title':        title,
    'description':  description,
    'isNoTradeRule': isNoTradeRule,
    'active':       active,
  };

  factory TradingRule.fromMap(Map<String, dynamic> m) => TradingRule(
    id:           m['id'] as String,
    title:        m['title'] as String,
    description:  m['description'] as String,
    isNoTradeRule: m['isNoTradeRule'] as bool? ?? false,
    active:       m['active'] as bool? ?? true,
  );
}

// Starter suggestions shown when user has no custom rules yet
final defaultTradingRules = <TradingRule>[];


// ── Journal Entry ─────────────────────────────────────────────────────────────

enum TradeDirection { long, short, none }

enum JournalEntryType { trade, sessionReview, ruleBreak, lessonLearned }

enum TradeOutcome { pending, win, loss, breakeven, cancelled }

extension TradeOutcomeX on TradeOutcome {
  String get label {
    switch (this) {
      case TradeOutcome.pending:    return 'PENDING';
      case TradeOutcome.win:        return 'WIN';
      case TradeOutcome.loss:       return 'LOSS';
      case TradeOutcome.breakeven:  return 'BREAKEVEN';
      case TradeOutcome.cancelled:  return 'CANCELLED';
    }
  }
}

/// Unified journal entry. Field usage depends on [type]:
///
/// - [JournalEntryType.trade]: instrument, direction, lotSize, entry, stopLoss,
///   takeProfit, setup, preNotes (reasoning before entry), then after the trade
///   settles: exit, outcome, pnl, postNotes (review), lessonLearned.
///
/// - [JournalEntryType.ruleBreak]: ruleTitle, ruleBroken, consequence,
///   emotionalState, lessonLearned.
///
/// - [JournalEntryType.sessionReview]: tradesTaken, wins, losses, netPnl, mood,
///   biggestMistake, whatWorked, sessionNotes. (NO lesson field.)
///
/// - [JournalEntryType.lessonLearned]: content, lessonLearned.
class JournalEntry {
  final String id;
  final JournalEntryType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ── Trade fields (type == trade) ────────────────────────────────────────
  final String? instrument;
  final TradeDirection direction;
  final double? lotSize;
  final double? entry;
  final double? stopLoss;
  final double? takeProfit;
  final String? setup;          // e.g. "Break of structure", "FVG retest"
  final String? preNotes;       // reasoning before entry
  final double? exit;
  final TradeOutcome outcome;
  final double? pnl;            // actual P&L in account currency
  final String? postNotes;      // post-trade review

  // ── Rule break fields ───────────────────────────────────────────────────
  final String? ruleTitle;       // which rule
  final String? ruleBroken;      // what happened
  final String? consequence;     // outcome/impact
  final String? emotionalState;  // mood when broke rule

  // ── Session review fields ───────────────────────────────────────────────
  final int? tradesTaken;
  final int? wins;
  final int? losses;
  final double? netPnl;
  final String? mood;
  final String? biggestMistake;
  final String? whatWorked;
  final String? sessionNotes;

  // ── Lesson (attached to every type except sessionReview) ────────────────
  final String? lessonLearned;

  // ── Legacy / free-form content (for old entries & lessonLearned type) ──
  final String content;
  final bool ruleFollowed;
  final List<String> tags;

  const JournalEntry({
    required this.id,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    // Trade
    this.instrument,
    this.direction = TradeDirection.none,
    this.lotSize,
    this.entry,
    this.stopLoss,
    this.takeProfit,
    this.setup,
    this.preNotes,
    this.exit,
    this.outcome = TradeOutcome.pending,
    this.pnl,
    this.postNotes,
    // Rule break
    this.ruleTitle,
    this.ruleBroken,
    this.consequence,
    this.emotionalState,
    // Session review
    this.tradesTaken,
    this.wins,
    this.losses,
    this.netPnl,
    this.mood,
    this.biggestMistake,
    this.whatWorked,
    this.sessionNotes,
    // Shared
    this.lessonLearned,
    this.content = '',
    this.ruleFollowed = true,
    this.tags = const [],
  });

  /// True if a trade entry has been closed (post-trade filled in).
  bool get isTradeClosed =>
      type == JournalEntryType.trade && outcome != TradeOutcome.pending;

  /// Risk:Reward ratio if SL/TP both set.
  double? get riskReward {
    if (entry == null || stopLoss == null || takeProfit == null) return null;
    final risk   = (entry! - stopLoss!).abs();
    final reward = (takeProfit! - entry!).abs();
    if (risk == 0) return null;
    return reward / risk;
  }

  JournalEntry copyWith({
    DateTime? updatedAt,
    String? instrument,
    TradeDirection? direction,
    double? lotSize,
    double? entry,
    double? stopLoss,
    double? takeProfit,
    String? setup,
    String? preNotes,
    double? exit,
    TradeOutcome? outcome,
    double? pnl,
    String? postNotes,
    String? ruleTitle,
    String? ruleBroken,
    String? consequence,
    String? emotionalState,
    int? tradesTaken,
    int? wins,
    int? losses,
    double? netPnl,
    String? mood,
    String? biggestMistake,
    String? whatWorked,
    String? sessionNotes,
    String? lessonLearned,
    String? content,
    bool? ruleFollowed,
    List<String>? tags,
  }) =>
      JournalEntry(
        id:              id,
        type:            type,
        createdAt:       createdAt,
        updatedAt:       updatedAt ?? this.updatedAt,
        instrument:      instrument ?? this.instrument,
        direction:       direction ?? this.direction,
        lotSize:         lotSize ?? this.lotSize,
        entry:           entry ?? this.entry,
        stopLoss:        stopLoss ?? this.stopLoss,
        takeProfit:      takeProfit ?? this.takeProfit,
        setup:           setup ?? this.setup,
        preNotes:        preNotes ?? this.preNotes,
        exit:            exit ?? this.exit,
        outcome:         outcome ?? this.outcome,
        pnl:             pnl ?? this.pnl,
        postNotes:       postNotes ?? this.postNotes,
        ruleTitle:       ruleTitle ?? this.ruleTitle,
        ruleBroken:      ruleBroken ?? this.ruleBroken,
        consequence:     consequence ?? this.consequence,
        emotionalState:  emotionalState ?? this.emotionalState,
        tradesTaken:     tradesTaken ?? this.tradesTaken,
        wins:            wins ?? this.wins,
        losses:          losses ?? this.losses,
        netPnl:          netPnl ?? this.netPnl,
        mood:            mood ?? this.mood,
        biggestMistake:  biggestMistake ?? this.biggestMistake,
        whatWorked:      whatWorked ?? this.whatWorked,
        sessionNotes:    sessionNotes ?? this.sessionNotes,
        lessonLearned:   lessonLearned ?? this.lessonLearned,
        content:         content ?? this.content,
        ruleFollowed:    ruleFollowed ?? this.ruleFollowed,
        tags:            tags ?? this.tags,
      );

  Map<String, dynamic> toMap() => {
    'id':             id,
    'type':           type.index,
    'createdAt':      createdAt.toIso8601String(),
    'updatedAt':      updatedAt?.toIso8601String(),
    'instrument':     instrument,
    'direction':      direction.index,
    'lotSize':        lotSize,
    'entry':          entry,
    'stopLoss':       stopLoss,
    'takeProfit':     takeProfit,
    'setup':          setup,
    'preNotes':       preNotes,
    'exit':           exit,
    'outcome':        outcome.index,
    'pnl':            pnl,
    'postNotes':      postNotes,
    'ruleTitle':      ruleTitle,
    'ruleBroken':     ruleBroken,
    'consequence':    consequence,
    'emotionalState': emotionalState,
    'tradesTaken':    tradesTaken,
    'wins':           wins,
    'losses':         losses,
    'netPnl':         netPnl,
    'mood':           mood,
    'biggestMistake': biggestMistake,
    'whatWorked':     whatWorked,
    'sessionNotes':   sessionNotes,
    'lessonLearned':  lessonLearned,
    'content':        content,
    'ruleFollowed':   ruleFollowed,
    'tags':           tags,
  };

  factory JournalEntry.fromMap(Map<String, dynamic> m) {
    // Map old preTrade/postTrade types to new unified 'trade' type
    int rawType = m['type'] as int;
    JournalEntryType resolvedType;
    // Legacy order: preTrade=0, postTrade=1, sessionReview=2, ruleBreak=3, lessonLearned=4
    // New order:    trade=0, sessionReview=1, ruleBreak=2, lessonLearned=3
    if (m.containsKey('instrument') || m.containsKey('outcome')) {
      // New format — use raw index directly
      resolvedType = JournalEntryType.values[rawType.clamp(0, JournalEntryType.values.length - 1)];
    } else {
      // Legacy format
      switch (rawType) {
        case 0: case 1: resolvedType = JournalEntryType.trade;         break;
        case 2:          resolvedType = JournalEntryType.sessionReview; break;
        case 3:          resolvedType = JournalEntryType.ruleBreak;     break;
        case 4:          resolvedType = JournalEntryType.lessonLearned; break;
        default:         resolvedType = JournalEntryType.lessonLearned;
      }
    }

    return JournalEntry(
      id:             m['id'] as String,
      type:           resolvedType,
      createdAt:      DateTime.parse(m['createdAt'] as String),
      updatedAt:      m['updatedAt'] != null ? DateTime.parse(m['updatedAt'] as String) : null,
      instrument:     m['instrument'] as String?,
      direction:      TradeDirection.values[(m['direction'] as int?) ?? 2],
      lotSize:        (m['lotSize'] as num?)?.toDouble(),
      entry:          (m['entry'] as num?)?.toDouble(),
      stopLoss:       (m['stopLoss'] as num?)?.toDouble(),
      takeProfit:     (m['takeProfit'] as num?)?.toDouble(),
      setup:          m['setup'] as String?,
      preNotes:       m['preNotes'] as String?,
      exit:           (m['exit'] as num?)?.toDouble(),
      outcome:        TradeOutcome.values[(m['outcome'] as int?) ?? 0],
      pnl:            (m['pnl'] as num?)?.toDouble(),
      postNotes:      m['postNotes'] as String?,
      ruleTitle:      m['ruleTitle'] as String?,
      ruleBroken:     m['ruleBroken'] as String?,
      consequence:    m['consequence'] as String?,
      emotionalState: m['emotionalState'] as String?,
      tradesTaken:    m['tradesTaken'] as int?,
      wins:           m['wins'] as int?,
      losses:         m['losses'] as int?,
      netPnl:         (m['netPnl'] as num?)?.toDouble(),
      mood:           m['mood'] as String?,
      biggestMistake: m['biggestMistake'] as String?,
      whatWorked:     m['whatWorked'] as String?,
      sessionNotes:   m['sessionNotes'] as String?,
      lessonLearned:  m['lessonLearned'] as String?,
      content:        (m['content'] as String?) ?? '',
      ruleFollowed:   m['ruleFollowed'] as bool? ?? true,
      tags:           List<String>.from(m['tags'] as List? ?? []),
    );
  }
}

extension JournalEntryTypeX on JournalEntryType {
  String get label {
    switch (this) {
      case JournalEntryType.trade:         return 'Trade';
      case JournalEntryType.sessionReview: return 'Session Review';
      case JournalEntryType.ruleBreak:     return 'Rule Break';
      case JournalEntryType.lessonLearned: return 'Lesson';
    }
  }
}


// ── Session Model ─────────────────────────────────────────────────────────────

enum TradingSession { london, newYork, asian, other }

extension TradingSessionX on TradingSession {
  String get label {
    switch (this) {
      case TradingSession.london:  return 'London';
      case TradingSession.newYork: return 'New York';
      case TradingSession.asian:   return 'Asian';
      case TradingSession.other:   return 'Custom';
    }
  }

  // UTC hour ranges
  int get openHour {
    switch (this) {
      case TradingSession.london:  return 8;
      case TradingSession.newYork: return 13;
      case TradingSession.asian:   return 0;
      case TradingSession.other:   return 0;
    }
  }

  int get closeHour {
    switch (this) {
      case TradingSession.london:  return 17;
      case TradingSession.newYork: return 22;
      case TradingSession.asian:   return 9;
      case TradingSession.other:   return 23;
    }
  }

  bool get isActive {
    final utcHour = DateTime.now().toUtc().hour;
    if (closeHour > openHour) {
      return utcHour >= openHour && utcHour < closeHour;
    }
    return utcHour >= openHour || utcHour < closeHour;
  }
}


// ── Bias Model ────────────────────────────────────────────────────────────────

enum BiasDirection { bullish, bearish, neutral }

class BiasEntry {
  final String id;
  final String instrument;
  final BiasDirection direction;
  final String reasoning;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const BiasEntry({
    required this.id,
    required this.instrument,
    required this.direction,
    required this.reasoning,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
