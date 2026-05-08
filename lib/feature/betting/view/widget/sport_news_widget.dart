// lib/feature/betting/view/widget/sport_news_widget.dart
//
// Live sport-news feed for the BETTING screen. Pulls from ESPN's free
// public JSON API. Football (soccer) is the default tab; the user can
// switch to basketball, NFL, F1, or tennis.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/sport_news_model.dart';
import '../../viewmodel/sport_news_viewmodel.dart';

class SportNewsWidget extends ConsumerWidget {
  const SportNewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportNewsViewModelProvider);
    final vm    = ref.read(sportNewsViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sport selector ─────────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: SportFeed.values.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final feed = SportFeed.values[i];
              final selected = feed == state.feed;
              return _SportPill(
                label:    feed.label,
                selected: selected,
                onTap:    () => vm.selectFeed(feed),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Body ───────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: vm.refresh,
            child: _buildBody(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SportNewsState state) {
    if (state.isLoading && state.articles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 1),
      );
    }
    if (state.errorMessage != null && state.articles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.signal_wifi_off_outlined,
              size: 36, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              state.errorMessage!,
              style: AppTypography.body
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (state.articles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text('No news right now.',
                style: AppTypography.body
                    .copyWith(color: AppColors.textMuted)),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 80),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      itemCount: state.articles.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _ArticleCard(article: state.articles[i]),
    );
  }
}

// ── Sport selector pill ──────────────────────────────────────────────────────

class _SportPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SportPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.elevated,
                    AppColors.surfaceVar,
                  ],
                )
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Article card ─────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final SportNewsArticle article;
  const _ArticleCard({required this.article});

  String? get _publishedAgo {
    final p = article.published;
    if (p == null) return null;
    final diff = DateTime.now().difference(p);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVar,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (article.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _Thumbnail(url: article.imageUrl!),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + time
                Row(
                  children: [
                    if (article.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              width: 0.5),
                        ),
                        child: Text(
                          article.category!.toUpperCase(),
                          style: AppTypography.chip.copyWith(
                              color: AppColors.accent,
                              fontSize: 9,
                              letterSpacing: 1.2),
                        ),
                      ),
                    const Spacer(),
                    if (_publishedAgo != null)
                      Text(_publishedAgo!,
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Headline
                Text(
                  article.headline,
                  style: AppTypography.h3.copyWith(
                      fontSize: 14, height: 1.3),
                ),
                if (article.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    article.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ],
                if (article.byline != null && article.byline!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    article.byline!,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic),
                  ),
                ],
                if (article.articleUrl != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    article.articleUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.elevated,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 1, color: AppColors.accent),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.elevated,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 28, color: AppColors.textMuted),
      ),
    );
  }
}
