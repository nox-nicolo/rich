// lib/feature/betting/repository/sport_news_repository.dart
//
// Fetches sport-news articles from ESPN's public JSON API. ESPN's site API
// is free, requires no authentication, and is the same endpoint ESPN's own
// apps use — so the response is rich (headline, description, image,
// byline, published timestamp, web link).
//
// A small in-memory cache (10 min TTL) prevents re-fetching when the user
// switches sport tabs back and forth.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/sport_news_model.dart';

class _CacheEntry {
  final List<SportNewsArticle> articles;
  final DateTime fetchedAt;
  _CacheEntry(this.articles, this.fetchedAt);
}

class SportNewsRepository {
  static const Duration _ttl = Duration(minutes: 10);
  static const Duration _httpTimeout = Duration(seconds: 12);

  // Per-feed cache keyed by SportFeed.name
  final Map<String, _CacheEntry> _cache = {};

  /// Returns articles for the given sport feed. Uses the cache if its
  /// entry is fresh, otherwise hits ESPN. Throws on network/parse failure
  /// so the viewmodel can surface a retry UI.
  Future<List<SportNewsArticle>> fetch(SportFeed feed,
      {bool force = false}) async {
    final key = feed.name;
    final now = DateTime.now();
    final cached = _cache[key];
    if (!force &&
        cached != null &&
        now.difference(cached.fetchedAt) < _ttl) {
      return cached.articles;
    }

    // ESPN's default page size is tiny (~6 articles). The site API accepts
    // a `limit` parameter (the same one ESPN's own apps use) — 100 is the
    // practical ceiling and gives a deep feed without paging.
    final uri = Uri.parse(
        'https://site.api.espn.com/apis/site/v2/sports/${feed.espnPath}/news'
        '?limit=500');

    final response =
        await http.get(uri).timeout(_httpTimeout);
    if (response.statusCode != 200) {
      throw Exception('ESPN responded ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! Map) throw Exception('Unexpected response shape');

    final raw = body['articles'];
    if (raw is! List) throw Exception('No articles in response');

    final articles = <SportNewsArticle>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          articles.add(
            SportNewsArticle.fromMap(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // Skip malformed entries, keep going.
        }
      }
    }

    _cache[key] = _CacheEntry(articles, now);
    return articles;
  }

  void invalidate(SportFeed feed) {
    _cache.remove(feed.name);
  }
}
