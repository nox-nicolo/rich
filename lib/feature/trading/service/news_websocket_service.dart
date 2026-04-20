// lib/feature/trading/service/news_websocket_service.dart
//
// Two parallel feeds drive the Trading › News tab:
//
//   1. Real news articles from the configured news provider (massive.com
//      /v2/reference/news). These carry a headline, publisher, description,
//      and vendor sentiment (positive/negative/neutral).
//
//   2. The ForexFactory economic calendar. Scheduled releases like NFP,
//      CPI, FOMC with forecast/previous values and — crucially — an impact
//      rating (high/medium/low) that the news API doesn't supply.
//
// Both sources emit NewsEvents into the same onNews callback. A shared
// _seenIds set deduplicates across polls.
//
// NOTE on the API key: it is embedded here for convenience. If this repo
// ever goes public, rotate the key and load it from a secure config source
// (dart-define, .env, platform keystore) instead.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/news_event.dart';

class NewsWebSocketService {
  final void Function(NewsEvent event) onNews;

  static const _apiKey = 'x2IltgNHzv320GdMtiXwWMWvLhcy3Udl';
  static final _newsUrl = Uri.parse(
    'https://api.polygon.io/v2/reference/news'
    '?order=desc&limit=100&sort=published_utc&apiKey=$_apiKey',
  );
  static final _calendarUrl = Uri.parse(
    'https://nfs.faireconomy.media/ff_calendar_thisweek.json',
  );

  Timer? _pollTimer;
  bool _connected = false;
  final Set<String> _seenIds = {};

  NewsWebSocketService({required this.onNews});

  void connect() {
    if (_connected) return;
    _connected = true;
    _refreshAll();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshAll();
    });
  }

  void disconnect() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _connected = false;
  }

  bool get isConnected => _connected;

  /// Manually fetch both feeds now. Safe to call whether or not [connect]
  /// has been invoked — used by pull-to-refresh. Doesn't touch the poll
  /// timer so the 5-minute cadence continues unchanged.
  Future<void> refreshNow() => _refreshAll();

  Future<void> _refreshAll() async {
    // Independent — one failing doesn't block the other.
    await Future.wait([
      _fetchNews(),
      _fetchCalendar(),
    ]);
  }

  // ── News source ────────────────────────────────────────────────────────

  Future<void> _fetchNews() async {
    try {
      final response = await http.get(_newsUrl);
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final results = decoded['results'];
      if (results is! List) return;

      // Emit oldest-first so newest lands at the top of the feed
      // (NewsNotifier prepends on addEvent).
      final items = results.reversed.toList();

      for (final raw in items) {
        if (raw is! Map<String, dynamic>) continue;
        final event = _parseNewsItem(raw);
        if (event == null) continue;

        if (_seenIds.contains(event.id)) continue;
        _seenIds.add(event.id);

        onNews(event);
      }
    } catch (_) {
      // Silently fail — retry on next poll
    }
  }

  NewsEvent? _parseNewsItem(Map<String, dynamic> m) {
    final id = (m['id'] as String?) ?? '';
    final title = (m['title'] as String?) ?? '';
    if (id.isEmpty || title.isEmpty) return null;

    final publishedRaw = m['published_utc'] as String?;
    final publishedAt = publishedRaw != null
        ? (DateTime.tryParse(publishedRaw) ?? DateTime.now())
        : DateTime.now();

    final publisher = m['publisher'];
    final source = publisher is Map<String, dynamic>
        ? (publisher['name'] as String? ?? 'News')
        : 'News';

    final description = m['description'] as String?;
    final articleUrl = m['article_url'] as String?;

    // Only forex-prefixed tickers ("C:EURUSD") contribute a currency hint.
    // Stock tickers like "UBS" are left alone.
    final tickers = m['tickers'];
    String? currency;
    if (tickers is List) {
      for (final t in tickers) {
        if (t is! String) continue;
        if (!t.startsWith('C:')) continue;
        final pair = t.substring(2);
        if (pair.length >= 3) {
          currency = pair.substring(0, 3);
          break;
        }
      }
    }

    // Vendor sentiment from insights[].sentiment.
    NewsSentiment? vendorSentiment;
    final insights = m['insights'];
    if (insights is List && insights.isNotEmpty) {
      final first = insights.first;
      if (first is Map<String, dynamic>) {
        vendorSentiment = _mapSentiment(first['sentiment'] as String?);
      }
    }

    return NewsEvent(
      id:              'news_$id',
      headline:        title,
      source:          source,
      publishedAt:     publishedAt,
      impact:          NewsImpact.unknown,
      vendorSentiment: vendorSentiment,
      currency:        currency,
      description:     description,
      articleUrl:      articleUrl,
    );
  }

  static NewsSentiment? _mapSentiment(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'positive':
      case 'bullish':
        return NewsSentiment.bullish;
      case 'negative':
      case 'bearish':
        return NewsSentiment.bearish;
      case 'neutral':
        return NewsSentiment.neutral;
      default:
        return null;
    }
  }

  // ── Calendar source ────────────────────────────────────────────────────

  Future<void> _fetchCalendar() async {
    try {
      final response = await http.get(_calendarUrl);
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! List) return;

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        final title    = item['title']    as String? ?? '';
        final country  = item['country']  as String? ?? '';
        final date     = item['date']     as String? ?? '';
        final impact   = item['impact']   as String? ?? '';
        final forecast = item['forecast'] as String? ?? '';
        final previous = item['previous'] as String? ?? '';
        if (title.isEmpty) continue;

        final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
        if (parsedDate.isBefore(startOfToday)) continue;

        final id = 'cal_${title.hashCode}_$date';
        if (_seenIds.contains(id)) continue;
        _seenIds.add(id);

        final event = NewsEvent(
          id:          id,
          headline:    title,
          source:      'Forex Calendar ($country)',
          publishedAt: parsedDate,
          impact:      _mapImpact(impact),
          currency:    country,
          description: forecast.isNotEmpty || previous.isNotEmpty
              ? 'Forecast: $forecast | Previous: $previous'
              : null,
        );

        onNews(event);
      }
    } catch (_) {
      // Silently fail — retry on next poll
    }
  }

  static NewsImpact _mapImpact(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':
        return NewsImpact.high;
      case 'medium':
        return NewsImpact.medium;
      case 'low':
        return NewsImpact.low;
      default:
        return NewsImpact.unknown;
    }
  }
}
