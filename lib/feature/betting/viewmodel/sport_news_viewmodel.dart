// lib/feature/betting/viewmodel/sport_news_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sport_news_model.dart';
import '../repository/sport_news_repository.dart';

class SportNewsState {
  final SportFeed feed;
  final List<SportNewsArticle> articles;
  final bool isLoading;
  final String? errorMessage;

  const SportNewsState({
    required this.feed,
    required this.articles,
    required this.isLoading,
    this.errorMessage,
  });

  factory SportNewsState.initial() => const SportNewsState(
        feed:      SportFeed.football, // football is the user's primary
        articles:  [],
        isLoading: true,
      );

  SportNewsState copyWith({
    SportFeed? feed,
    List<SportNewsArticle>? articles,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SportNewsState(
        feed:         feed         ?? this.feed,
        articles:     articles     ?? this.articles,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class SportNewsViewModel extends StateNotifier<SportNewsState> {
  final SportNewsRepository _repo;

  SportNewsViewModel(this._repo) : super(SportNewsState.initial()) {
    _load(state.feed);
  }

  Future<void> selectFeed(SportFeed feed) async {
    if (state.feed == feed && state.articles.isNotEmpty && !state.isLoading) {
      return;
    }
    state = state.copyWith(feed: feed, isLoading: true, clearError: true);
    await _load(feed);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load(state.feed, force: true);
  }

  Future<void> _load(SportFeed feed, {bool force = false}) async {
    try {
      final articles = await _repo.fetch(feed, force: force);
      // Only commit if user hasn't switched feeds in the meantime.
      if (state.feed != feed) return;
      state = state.copyWith(
        articles:  articles,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (state.feed != feed) return;
      state = state.copyWith(
        articles:     const [],
        isLoading:    false,
        errorMessage: 'Could not load news. Pull to retry.',
      );
    }
  }
}

final sportNewsRepositoryProvider =
    Provider<SportNewsRepository>((_) => SportNewsRepository());

final sportNewsViewModelProvider =
    StateNotifierProvider<SportNewsViewModel, SportNewsState>(
  (ref) => SportNewsViewModel(ref.read(sportNewsRepositoryProvider)),
);
