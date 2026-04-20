// lib/feature/trading/service/trading_account_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/trading_account_model.dart';

/// Result wrapper so the UI can show a sensible error instead of
/// an opaque exception.
class AccountFetchResult<T> {
  final T? data;
  final String? error;
  const AccountFetchResult.ok(this.data) : error = null;
  const AccountFetchResult.err(this.error) : data = null;
  bool get ok => error == null;
}

/// Thin client around the MetaApi cloud REST endpoints.
/// Docs: https://metaapi.cloud/docs/client/restApi/
///
/// This is a stub: we hit the read-only endpoints only. Order placement
/// is deliberately NOT implemented — the app mirrors what the broker
/// platform already has.
class TradingAccountService {
  final TradingAccountConfig config;
  final http.Client _client;

  /// Client API host (used for reading positions, history, info).
  static const _host = 'https://mt-client-api-v1.new-york.agiliumtrade.ai';

  /// Provisioning host (used to register a broker account with MetaApi).
  static const _provisioningHost =
      'https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai';

  TradingAccountService(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'auth-token':  config.token,
        'Accept':      'application/json',
      };

  Map<String, String> get _jsonHeaders => {
        ..._headers,
        'Content-Type': 'application/json',
      };

  Uri _u(String path) => Uri.parse('$_host/users/current/accounts/${config.accountId}$path');

  /// Provision a new MetaApi account from bare MT credentials (login,
  /// password, server, platform). Returns the provisioned `accountId`
  /// which the caller should persist on the config.
  ///
  /// The user flow becomes: paste MT login + password + server + pick
  /// MT4/MT5, and the app takes care of the MetaApi plumbing. The auth
  /// token (acquired once from metaapi.cloud) is still required.
  Future<AccountFetchResult<String>> provisionAccount() async {
    if (!config.canProvision) {
      return const AccountFetchResult.err(
          'Missing MT login / password / server / token');
    }
    try {
      final body = json.encode({
        'name':     config.nickname?.isNotEmpty == true
            ? config.nickname
            : 'rich-${config.login}',
        'type':     'cloud',
        'login':    config.login,
        'password': config.password,
        'server':   config.server,
        'platform': config.platform.apiValue, // 'mt4' | 'mt5'
        'magic':    0,
        'application': 'MetaApi',
      });
      final res = await _client
          .post(
            Uri.parse('$_provisioningHost/users/current/accounts'),
            headers: _jsonHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200 && res.statusCode != 201) {
        return AccountFetchResult.err(
            'HTTP ${res.statusCode}: ${_extractError(res.body)}');
      }
      final m = json.decode(res.body) as Map<String, dynamic>;
      final id = (m['id'] ?? m['_id']) as String?;
      if (id == null || id.isEmpty) {
        return const AccountFetchResult.err(
            'Provisioning succeeded but no account id returned');
      }
      return AccountFetchResult.ok(id);
    } catch (e) {
      return AccountFetchResult.err(e.toString());
    }
  }

  /// Fetch account info (balance, equity, margin).
  Future<AccountFetchResult<BrokerAccountInfo>> fetchAccountInformation() async {
    if (!config.isValid) {
      return const AccountFetchResult.err('Account not configured');
    }
    try {
      final res = await _client
          .get(_u('/account-information'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return AccountFetchResult.err(
            'HTTP ${res.statusCode}: ${_extractError(res.body)}');
      }
      final m = json.decode(res.body) as Map<String, dynamic>;
      return AccountFetchResult.ok(BrokerAccountInfo(
        balance:    (m['balance']    as num? ?? 0).toDouble(),
        equity:     (m['equity']     as num? ?? 0).toDouble(),
        margin:     (m['margin']     as num? ?? 0).toDouble(),
        freeMargin: (m['freeMargin'] as num? ?? 0).toDouble(),
        currency:   (m['currency']   as String?) ?? 'USD',
        fetchedAt:  DateTime.now(),
      ));
    } catch (e) {
      return AccountFetchResult.err(e.toString());
    }
  }

  /// Fetch all currently open positions.
  Future<AccountFetchResult<List<BrokerTrade>>> fetchOpenPositions() async {
    if (!config.isValid) {
      return const AccountFetchResult.err('Account not configured');
    }
    try {
      final res = await _client
          .get(_u('/positions'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return AccountFetchResult.err(
            'HTTP ${res.statusCode}: ${_extractError(res.body)}');
      }
      final list = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
      return AccountFetchResult.ok(list.map(_positionFromJson).toList());
    } catch (e) {
      return AccountFetchResult.err(e.toString());
    }
  }

  /// Fetch closed deals in a given time window (default: last 7 days).
  Future<AccountFetchResult<List<BrokerTrade>>> fetchHistory({
    DateTime? start,
    DateTime? end,
  }) async {
    if (!config.isValid) {
      return const AccountFetchResult.err('Account not configured');
    }
    final s = (start ?? DateTime.now().subtract(const Duration(days: 7)))
        .toUtc()
        .toIso8601String();
    final e = (end ?? DateTime.now()).toUtc().toIso8601String();
    try {
      final res = await _client
          .get(
            _u('/history-deals/time/$s/$e'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        return AccountFetchResult.err(
            'HTTP ${res.statusCode}: ${_extractError(res.body)}');
      }
      final list = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
      // History comes as deals — group by positionId to assemble closed trades.
      return AccountFetchResult.ok(_dealsToTrades(list));
    } catch (e) {
      return AccountFetchResult.err(e.toString());
    }
  }

  void dispose() => _client.close();

  // ── Parsing helpers ──────────────────────────────────────────────────────

  BrokerTrade _positionFromJson(Map<String, dynamic> m) => BrokerTrade(
        id:         (m['id'] ?? m['positionId'] ?? '').toString(),
        symbol:     (m['symbol'] as String?) ?? '',
        side:       (m['type'] as String?)?.toUpperCase().contains('SELL') == true
            ? BrokerTradeSide.sell
            : BrokerTradeSide.buy,
        volume:     (m['volume']     as num? ?? 0).toDouble(),
        openPrice:  (m['openPrice']  as num? ?? 0).toDouble(),
        stopLoss:   (m['stopLoss']   as num?)?.toDouble(),
        takeProfit: (m['takeProfit'] as num?)?.toDouble(),
        profit:     (m['profit']     as num?)?.toDouble(),
        swap:       (m['swap']       as num?)?.toDouble(),
        commission: (m['commission'] as num?)?.toDouble(),
        openTime:   DateTime.tryParse((m['time'] ?? '') as String)
            ?? DateTime.now(),
        comment:    m['comment'] as String?,
      );

  /// MetaApi history returns deal-level rows. Two deals (entry + exit) make
  /// up one closed trade. We group them by positionId and synthesize a
  /// BrokerTrade record.
  List<BrokerTrade> _dealsToTrades(List<Map<String, dynamic>> deals) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final d in deals) {
      final pid = (d['positionId'] ?? d['id']).toString();
      grouped.putIfAbsent(pid, () => []).add(d);
    }
    final result = <BrokerTrade>[];
    grouped.forEach((pid, group) {
      // Sort by time
      group.sort((a, b) => (a['time'] as String? ?? '')
          .compareTo(b['time'] as String? ?? ''));
      final entry = group.first;
      final exit  = group.length > 1 ? group.last : null;
      final type  = ((entry['type'] as String?) ?? '').toUpperCase();
      result.add(BrokerTrade(
        id:         pid,
        symbol:     (entry['symbol'] as String?) ?? '',
        side:       type.contains('SELL')
            ? BrokerTradeSide.sell
            : BrokerTradeSide.buy,
        volume:     (entry['volume']    as num? ?? 0).toDouble(),
        openPrice:  (entry['price']     as num? ?? 0).toDouble(),
        closePrice: (exit?['price']     as num?)?.toDouble(),
        profit:     group.fold<double>(
            0, (s, d) => s + ((d['profit'] as num?)?.toDouble() ?? 0)),
        swap:       group.fold<double>(
            0, (s, d) => s + ((d['swap'] as num?)?.toDouble() ?? 0)),
        commission: group.fold<double>(
            0, (s, d) => s + ((d['commission'] as num?)?.toDouble() ?? 0)),
        openTime:   DateTime.tryParse((entry['time'] ?? '') as String)
            ?? DateTime.now(),
        closeTime:  exit != null
            ? DateTime.tryParse((exit['time'] ?? '') as String)
            : null,
        comment:    entry['comment'] as String?,
      ));
    });
    // Newest first
    result.sort((a, b) => b.openTime.compareTo(a.openTime));
    return result;
  }

  String _extractError(String body) {
    try {
      final m = json.decode(body);
      if (m is Map && m['message'] is String) return m['message'] as String;
    } catch (_) {}
    return body.length > 120 ? '${body.substring(0, 120)}...' : body;
  }
}
