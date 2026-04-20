// lib/feature/trading/model/news_event.dart

// ── Impact ────────────────────────────────────────────────────────────────────

enum NewsImpact { high, medium, low, unknown }

extension NewsImpactX on NewsImpact {
  String get label {
    switch (this) {
      case NewsImpact.high:    return 'HIGH';
      case NewsImpact.medium:  return 'MED';
      case NewsImpact.low:     return 'LOW';
      case NewsImpact.unknown: return '—';
    }
  }
}

// ── Sentiment ─────────────────────────────────────────────────────────────────

enum NewsSentiment { bullish, bearish, neutral }

// ── News Event ────────────────────────────────────────────────────────────────

class NewsEvent {
  final String id;
  final String headline;
  final String source;
  final DateTime publishedAt;
  final NewsImpact impact;
  final NewsSentiment? sentiment;       // user-tagged call
  final NewsSentiment? vendorSentiment; // pre-tagged by the news provider
  final String? currency;               // e.g. 'USD', 'EUR'
  final String? description;
  final String? articleUrl;

  const NewsEvent({
    required this.id,
    required this.headline,
    required this.source,
    required this.publishedAt,
    this.impact = NewsImpact.unknown,
    this.sentiment,
    this.vendorSentiment,
    this.currency,
    this.description,
    this.articleUrl,
  });

  bool get isHighImpact => impact == NewsImpact.high;
  bool get isTagged => sentiment != null;

  NewsEvent copyWith({
    String? id,
    String? headline,
    String? source,
    DateTime? publishedAt,
    NewsImpact? impact,
    NewsSentiment? sentiment,
    NewsSentiment? vendorSentiment,
    String? currency,
    String? description,
    String? articleUrl,
  }) {
    return NewsEvent(
      id:              id              ?? this.id,
      headline:        headline        ?? this.headline,
      source:          source          ?? this.source,
      publishedAt:     publishedAt     ?? this.publishedAt,
      impact:          impact          ?? this.impact,
      sentiment:       sentiment       ?? this.sentiment,
      vendorSentiment: vendorSentiment ?? this.vendorSentiment,
      currency:        currency        ?? this.currency,
      description:     description     ?? this.description,
      articleUrl:      articleUrl      ?? this.articleUrl,
    );
  }
}
