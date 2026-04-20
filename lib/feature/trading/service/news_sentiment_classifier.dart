// lib/feature/trading/service/news_sentiment_classifier.dart
//
// Deterministic bull/bear/neutral classifier for news events. Surfaces a
// single-glance sentiment chip on the news feed so the user doesn't have to
// decode the analysis copy themselves.
//
// Priority:
//   1. If the analysis engine has a rule with a directional call
//      (bullish/bearish), use that.
//   2. Otherwise, run a keyword pass on the headline. Keywords are framed
//      from the GOLD (XAUUSD) reader's perspective because that's the asset
//      the analysis engine is built for.
//   3. Fall back to neutral.

import '../model/news_event.dart';
import '../model/news_analysis.dart';

class NewsSentimentClassifier {
  NewsSentimentClassifier._();

  static NewsSentiment classify(NewsEvent event, NewsAnalysis? analysis) {
    // Vendor-provided sentiment (e.g. from the news API's insights block)
    // is the most authoritative signal we have.
    if (event.vendorSentiment != null) return event.vendorSentiment!;

    if (analysis != null) {
      switch (analysis.direction) {
        case AnalysisDirection.bullish:
          return NewsSentiment.bullish;
        case AnalysisDirection.bearish:
          return NewsSentiment.bearish;
        case AnalysisDirection.volatile:
        case AnalysisDirection.neutral:
        case AnalysisDirection.unknown:
          return NewsSentiment.neutral;
      }
    }

    final text = '${event.headline} ${event.description ?? ''}'.toLowerCase();

    for (final w in _bullishKeywords) {
      if (text.contains(w)) return NewsSentiment.bullish;
    }
    for (final w in _bearishKeywords) {
      if (text.contains(w)) return NewsSentiment.bearish;
    }
    return NewsSentiment.neutral;
  }

  // Framed from a gold reader's perspective:
  //   dovish Fed / weak USD / risk-off / cuts → bullish gold
  //   hawkish Fed / strong USD / hikes       → bearish gold
  static const _bullishKeywords = [
    'rate cut', 'rate cuts', 'cuts rates',
    'dovish', 'easing', 'stimulus',
    'dollar falls', 'dollar weakens', 'dollar slides', 'dollar drops',
    'gold rallies', 'gold surges', 'gold jumps', 'gold gains', 'gold rises',
    'safe haven', 'risk off', 'risk-off',
    'recession', 'slowdown',
  ];

  static const _bearishKeywords = [
    'rate hike', 'rate hikes', 'hikes rates',
    'hawkish', 'tightening',
    'dollar rallies', 'dollar surges', 'dollar jumps', 'dollar gains',
    'dollar strengthens', 'dollar climbs',
    'gold falls', 'gold drops', 'gold plunges', 'gold slides',
    'risk on', 'risk-on',
    'strong jobs', 'hot inflation', 'sticky inflation',
  ];
}
