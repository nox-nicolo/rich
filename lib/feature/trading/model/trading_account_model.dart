// lib/feature/trading/model/trading_account_model.dart

/// Which cloud bridge is being used to talk to the brokerage platform.
/// Only MetaApi is implemented right now; others are listed so the config
/// model can evolve without a migration.
enum AccountProvider { metaApi, ctrader, manual }

extension AccountProviderX on AccountProvider {
  String get label {
    switch (this) {
      case AccountProvider.metaApi: return 'MetaApi (MT4/MT5)';
      case AccountProvider.ctrader: return 'cTrader';
      case AccountProvider.manual:  return 'Manual only';
    }
  }
}

/// Which MetaTrader platform the broker account lives on.
enum MtPlatform { mt4, mt5 }

extension MtPlatformX on MtPlatform {
  String get label => this == MtPlatform.mt4 ? 'MT4' : 'MT5';
  String get apiValue => this == MtPlatform.mt4 ? 'mt4' : 'mt5';
}

/// Credentials + routing info for an external trading account.
///
/// Stored locally on the device and only sent to MetaApi cloud during
/// provisioning / data refresh. The MT password is kept so we can
/// re-provision if the remote account was deleted.
class TradingAccountConfig {
  final AccountProvider provider;
  final MtPlatform platform;   // MT4 or MT5
  final String login;          // MT account number
  final String password;       // MT investor password
  final String server;         // MT server name (broker-XYZ-Live)
  final String accountId;      // MetaApi provisioning account id (filled after provision)
  final String token;          // MetaApi auth token
  final String? nickname;      // friendly name to show in the UI
  final DateTime? connectedAt;

  const TradingAccountConfig({
    required this.provider,
    required this.platform,
    required this.login,
    required this.password,
    required this.server,
    required this.accountId,
    required this.token,
    this.nickname,
    this.connectedAt,
  });

  /// Config is "ready to sync" once we have an account id from MetaApi.
  bool get isValid =>
      accountId.isNotEmpty && token.isNotEmpty;

  /// Has enough info to attempt provisioning against MetaApi.
  bool get canProvision =>
      login.isNotEmpty &&
      password.isNotEmpty &&
      server.isNotEmpty &&
      token.isNotEmpty;

  TradingAccountConfig copyWith({
    AccountProvider? provider,
    MtPlatform? platform,
    String? login,
    String? password,
    String? server,
    String? accountId,
    String? token,
    String? nickname,
    DateTime? connectedAt,
  }) =>
      TradingAccountConfig(
        provider:    provider    ?? this.provider,
        platform:    platform    ?? this.platform,
        login:       login       ?? this.login,
        password:    password    ?? this.password,
        server:      server      ?? this.server,
        accountId:   accountId   ?? this.accountId,
        token:       token       ?? this.token,
        nickname:    nickname    ?? this.nickname,
        connectedAt: connectedAt ?? this.connectedAt,
      );

  Map<String, dynamic> toMap() => {
    'provider':    provider.index,
    'platform':    platform.index,
    'login':       login,
    'password':    password,
    'server':      server,
    'accountId':   accountId,
    'token':       token,
    'nickname':    nickname,
    'connectedAt': connectedAt?.toIso8601String(),
  };

  factory TradingAccountConfig.fromMap(Map<String, dynamic> m) =>
      TradingAccountConfig(
        provider:    AccountProvider.values[
            (m['provider'] as int?) ?? AccountProvider.metaApi.index],
        platform:    MtPlatform.values[
            (m['platform'] as int?) ?? MtPlatform.mt5.index],
        login:       (m['login']     as String?) ?? '',
        password:    (m['password']  as String?) ?? '',
        server:      (m['server']    as String?) ?? '',
        accountId:   (m['accountId'] as String?) ?? '',
        token:       (m['token']     as String?) ?? '',
        nickname:    m['nickname']   as String?,
        connectedAt: m['connectedAt'] != null
            ? DateTime.tryParse(m['connectedAt'] as String)
            : null,
      );
}

// ── Broker Trade (mirror of a position/order from the remote platform) ──────

enum BrokerTradeSide { buy, sell }

extension BrokerTradeSideX on BrokerTradeSide {
  String get label => this == BrokerTradeSide.buy ? 'BUY' : 'SELL';
}

/// Snapshot of a single trade fetched from the broker platform.
/// This is a read-only mirror — the app does not place orders.
class BrokerTrade {
  final String id;
  final String symbol;
  final BrokerTradeSide side;
  final double volume;       // lots
  final double openPrice;
  final double? closePrice;  // null while position is open
  final double? stopLoss;
  final double? takeProfit;
  final double? profit;      // account currency, may include swap
  final double? swap;
  final double? commission;
  final DateTime openTime;
  final DateTime? closeTime; // null = position still open
  final String? comment;

  const BrokerTrade({
    required this.id,
    required this.symbol,
    required this.side,
    required this.volume,
    required this.openPrice,
    required this.openTime,
    this.closePrice,
    this.stopLoss,
    this.takeProfit,
    this.profit,
    this.swap,
    this.commission,
    this.closeTime,
    this.comment,
  });

  bool get isOpen => closeTime == null;

  Map<String, dynamic> toMap() => {
    'id':         id,
    'symbol':     symbol,
    'side':       side.index,
    'volume':     volume,
    'openPrice':  openPrice,
    'closePrice': closePrice,
    'stopLoss':   stopLoss,
    'takeProfit': takeProfit,
    'profit':     profit,
    'swap':       swap,
    'commission': commission,
    'openTime':   openTime.toIso8601String(),
    'closeTime':  closeTime?.toIso8601String(),
    'comment':    comment,
  };

  factory BrokerTrade.fromMap(Map<String, dynamic> m) => BrokerTrade(
        id:         m['id']     as String,
        symbol:     m['symbol'] as String,
        side:       BrokerTradeSide.values[(m['side'] as int?) ?? 0],
        volume:     (m['volume']     as num).toDouble(),
        openPrice:  (m['openPrice']  as num).toDouble(),
        closePrice: (m['closePrice'] as num?)?.toDouble(),
        stopLoss:   (m['stopLoss']   as num?)?.toDouble(),
        takeProfit: (m['takeProfit'] as num?)?.toDouble(),
        profit:     (m['profit']     as num?)?.toDouble(),
        swap:       (m['swap']       as num?)?.toDouble(),
        commission: (m['commission'] as num?)?.toDouble(),
        openTime:   DateTime.parse(m['openTime'] as String),
        closeTime:  m['closeTime'] != null
            ? DateTime.parse(m['closeTime'] as String)
            : null,
        comment:    m['comment'] as String?,
      );
}

/// Live snapshot of the account balance / equity from the broker.
class BrokerAccountInfo {
  final double balance;
  final double equity;
  final double margin;
  final double freeMargin;
  final String currency;
  final DateTime fetchedAt;

  const BrokerAccountInfo({
    required this.balance,
    required this.equity,
    required this.margin,
    required this.freeMargin,
    required this.currency,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() => {
    'balance':    balance,
    'equity':     equity,
    'margin':     margin,
    'freeMargin': freeMargin,
    'currency':   currency,
    'fetchedAt':  fetchedAt.toIso8601String(),
  };

  factory BrokerAccountInfo.fromMap(Map<String, dynamic> m) =>
      BrokerAccountInfo(
        balance:    (m['balance']    as num).toDouble(),
        equity:     (m['equity']     as num).toDouble(),
        margin:     (m['margin']     as num).toDouble(),
        freeMargin: (m['freeMargin'] as num).toDouble(),
        currency:   m['currency']    as String,
        fetchedAt:  DateTime.parse(m['fetchedAt'] as String),
      );
}
