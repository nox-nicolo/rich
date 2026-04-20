// lib/feature/trading/model/news_analysis.dart
//
// Describes HOW an economic event tends to move a specific asset and WHY.
// Today the only analyzed asset is gold (XAUUSD) — the engine is structured
// so other assets (indices, majors) can be added later.

enum AnalysisDirection { bullish, bearish, volatile, neutral, unknown }

extension AnalysisDirectionX on AnalysisDirection {
  String get label {
    switch (this) {
      case AnalysisDirection.bullish:  return 'BULLISH';
      case AnalysisDirection.bearish:  return 'BEARISH';
      case AnalysisDirection.volatile: return 'VOLATILE';
      case AnalysisDirection.neutral:  return 'NEUTRAL';
      case AnalysisDirection.unknown:  return 'UNCLEAR';
    }
  }

  /// Short arrow-style glyph for the direction badge.
  String get arrow {
    switch (this) {
      case AnalysisDirection.bullish:  return '↑';
      case AnalysisDirection.bearish:  return '↓';
      case AnalysisDirection.volatile: return '↕';
      case AnalysisDirection.neutral:  return '·';
      case AnalysisDirection.unknown:  return '?';
    }
  }
}

/// Explains a news event's probable impact on a single asset.
class NewsAnalysis {
  /// The asset this analysis is about — e.g. 'XAUUSD'.
  final String asset;

  /// Friendly display name — e.g. 'GOLD'.
  final String assetDisplay;

  final AnalysisDirection direction;

  /// Short one-liner used on the collapsed tile, e.g.
  /// 'Hot CPI → hawkish Fed → gold falls'.
  final String takeaway;

  /// Multi-sentence educational paragraph explaining WHY the event matters
  /// for this asset. Shown when the tile expands.
  final String why;

  /// What happens if the actual print beats the forecast (null if not applicable).
  final String? beatScenario;

  /// What happens if the actual print misses the forecast (null if not applicable).
  final String? missScenario;

  /// What specific numbers / sub-indicators to watch in the release.
  final String? whatToWatch;

  const NewsAnalysis({
    required this.asset,
    required this.assetDisplay,
    required this.direction,
    required this.takeaway,
    required this.why,
    this.beatScenario,
    this.missScenario,
    this.whatToWatch,
  });
}
