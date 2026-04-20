// lib/providers/news_provider.dart
//
// Global news event stream shared across Trading and Dashboard.
// The WebSocket service pushes events here.
// The rule engine reads latestNewsProvider to evaluate rules.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/trading/model/news_event.dart';

class NewsNotifier extends StateNotifier<List<NewsEvent>> {
  NewsNotifier() : super([]);

  /// Add a new event to the top of the feed.
  /// Keeps max 100 events in memory.
  void addEvent(NewsEvent event) {
    final updated = [event, ...state];
    state = updated.length > 100
        ? updated.take(100).toList()
        : updated;
  }

  /// Tag a specific event's sentiment.
  void tagSentiment(String id, NewsSentiment sentiment) {
    state = state
        .map((e) => e.id == id ? e.copyWith(sentiment: sentiment) : e)
        .toList();
  }

  /// Clear all events (e.g. on session end).
  void clear() => state = [];

  List<NewsEvent> get highImpact =>
      state.where((e) => e.isHighImpact).toList();

  List<NewsEvent> get untagged =>
      state.where((e) => !e.isTagged).toList();
}

/// Full ordered news feed (newest first).
final newsProvider =
    StateNotifierProvider<NewsNotifier, List<NewsEvent>>(
  (ref) => NewsNotifier(),
);

/// Most recent single event — used by the rule engine
/// and the Dashboard news flash widget.
final latestNewsProvider = Provider<NewsEvent?>(
  (ref) {
    final news = ref.watch(newsProvider);
    return news.isEmpty ? null : news.first;
  },
);

/// Only high impact events.
final highImpactNewsProvider = Provider<List<NewsEvent>>(
  (ref) {
    return ref.watch(newsProvider).where((e) => e.isHighImpact).toList();
  },
);

/// Count of untagged high-impact events.
/// Used to show a badge/warning on the Trading tab.
final untaggedHighImpactCountProvider = Provider<int>(
  (ref) {
    return ref
        .watch(newsProvider)
        .where((e) => e.isHighImpact && !e.isTagged)
        .length;
  },
);
