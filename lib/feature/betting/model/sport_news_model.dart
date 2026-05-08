// lib/feature/betting/model/sport_news_model.dart
//
// One sport-news article fetched from ESPN's free public JSON API.
// Endpoint shape: https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/news
// No auth, no rate limit beyond reasonable use.

class SportNewsArticle {
  final String headline;
  final String description;
  final String? imageUrl;
  final String? articleUrl;
  final String? byline;
  final DateTime? published;
  final String? category;

  const SportNewsArticle({
    required this.headline,
    required this.description,
    this.imageUrl,
    this.articleUrl,
    this.byline,
    this.published,
    this.category,
  });

  factory SportNewsArticle.fromMap(Map<String, dynamic> m) {
    // Pick the first usable image — ESPN often returns a list with multiple
    // crops; we just want the largest URL we can find.
    String? image;
    final images = m['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map && first['url'] is String) {
        image = first['url'] as String;
      }
    }

    // Web link to the full article on espn.com
    String? webUrl;
    final links = m['links'];
    if (links is Map) {
      final web = links['web'];
      if (web is Map && web['href'] is String) {
        webUrl = web['href'] as String;
      }
    }

    // First category description, used as a small chip on the card
    String? cat;
    final cats = m['categories'];
    if (cats is List && cats.isNotEmpty) {
      final first = cats.first;
      if (first is Map && first['description'] is String) {
        cat = first['description'] as String;
      }
    }

    return SportNewsArticle(
      headline:    (m['headline'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      imageUrl:    image,
      articleUrl:  webUrl,
      byline:      m['byline'] as String?,
      published:   DateTime.tryParse(m['published'] as String? ?? ''),
      category:    cat,
    );
  }
}

enum SportFeed { football, basketball, americanFootball, formula1, tennis }

extension SportFeedX on SportFeed {
  String get label {
    switch (this) {
      case SportFeed.football:          return 'Football';
      case SportFeed.basketball:        return 'Basketball';
      case SportFeed.americanFootball:  return 'NFL';
      case SportFeed.formula1:          return 'F1';
      case SportFeed.tennis:            return 'Tennis';
    }
  }

  /// ESPN URL path segment: `/{sport}/{league}/news`
  String get espnPath {
    switch (this) {
      case SportFeed.football:          return 'soccer/all';
      case SportFeed.basketball:        return 'basketball/nba';
      case SportFeed.americanFootball:  return 'football/nfl';
      case SportFeed.formula1:          return 'racing/f1';
      case SportFeed.tennis:            return 'tennis';
    }
  }
}
