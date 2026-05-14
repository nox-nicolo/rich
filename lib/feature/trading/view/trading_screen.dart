// lib/features/trading/view/trading_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/trading_models.dart';
import '../model/trading_target_model.dart';
import '../model/news_analysis.dart';
import '../service/news_analysis_engine.dart';
import '../service/news_sentiment_classifier.dart';
import '../viewmodel/trading_viewmodel.dart';
import '../../../providers/providers.dart';
import 'package:uuid/uuid.dart';
import 'widget/growth_plan_widget.dart';
import 'widget/journal_widget.dart';
import 'widget/account_widget.dart';

class TradingScreen extends ConsumerWidget {
  const TradingScreen({super.key});

  static const _tabs = [
    'NEWS',
    'PLAN',
    'RULES',
    'JOURNAL',
    'BIAS',
    'TARGETS',
    'ACCOUNT',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingViewModelProvider);
    final vm = ref.read(tradingViewModelProvider.notifier);
    final newsList = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'TRADING',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          _SessionToggleButton(
            active: state.sessionActive,
            onToggle: state.sessionActive ? vm.endSession : vm.startSession,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Session Status Bar ──────────────────────────────────────────
          _SessionStatusBar(
            active: state.sessionActive,
            session: state.currentSession,
          ),

          // ── Tab Bar ─────────────────────────────────────────────────────
          _RichTabBar(
            tabs: _tabs,
            selected: state.activeTab ?? 'NEWS',
            onSelect: vm.setTab,
          ),

          // ── Tab Content ─────────────────────────────────────────────────
          Expanded(
            child: _tabContent(
              context: context,
              ref: ref,
              tab: state.activeTab ?? 'NEWS',
              state: state,
              vm: vm,
              news: newsList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent({
    required BuildContext context,
    required WidgetRef ref,
    required String tab,
    required TradingState state,
    required TradingViewModel vm,
    required List<NewsEvent> news,
  }) {
    switch (tab) {
      case 'NEWS':
        return _NewsFeedTab(news: news, vm: vm);
      case 'PLAN':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: GrowthPlanWidget(),
        );
      case 'RULES':
        return _RulesTab(rules: state.rules, vm: vm);
      case 'JOURNAL':
        return const JournalTab();
      case 'BIAS':
        return _BiasTab(biases: state.biasBoard, vm: vm, context: context);
      case 'TARGETS':
        return _TargetsTab(targets: state.targets, vm: vm, context: context);
      case 'ACCOUNT':
        return const AccountTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Session Toggle Button ─────────────────────────────────────────────────────

class _SessionToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onToggle;

  const _SessionToggleButton({required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          active ? 'END SESSION' : 'START SESSION',
          style: AppTypography.chip.copyWith(
            color: active ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Session Status Bar ────────────────────────────────────────────────────────

class _SessionStatusBar extends StatelessWidget {
  final bool active;
  final TradingSession session;

  const _SessionStatusBar({required this.active, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Active sessions
          ...TradingSession.values
              .where((s) => s != TradingSession.other)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SessionPill(session: s, active: s.isActive),
                ),
              ),
          const Spacer(),
          if (active)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: AppTypography.chip.copyWith(color: AppColors.success),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  final TradingSession session;
  final bool active;

  const _SessionPill({required this.session, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Text(
        session.label,
        style: AppTypography.chip.copyWith(
          color: active ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _RichTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _RichTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab,
                    style: AppTypography.label.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 1,
                    width: 20,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── News Feed Tab ─────────────────────────────────────────────────────────────

class _NewsFeedTab extends ConsumerWidget {
  final List<NewsEvent> news;
  final TradingViewModel vm;

  const _NewsFeedTab({required this.news, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Empty state must still be scrollable, otherwise RefreshIndicator has
    // nothing to hook into and the pull gesture is ignored.
    if (news.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refreshNews,
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rss_feed_outlined,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text('No news yet', style: AppTypography.body),
                    const SizedBox(height: 4),
                    Text('Pull down to refresh', style: AppTypography.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refreshNews,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: news.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.divider, height: 1, thickness: 0.5),
        itemBuilder: (context, i) => _NewsTile(
          event: news[i],
          onTag: (sentiment) => vm.tagNewsSentiment(news[i].id, sentiment),
        ),
      ),
    );
  }
}

class _NewsTile extends StatefulWidget {
  final NewsEvent event;
  final ValueChanged<NewsSentiment> onTag;

  const _NewsTile({required this.event, required this.onTag});

  @override
  State<_NewsTile> createState() => _NewsTileState();
}

class _NewsTileState extends State<_NewsTile> {
  bool _expanded = false;

  Color get _impactColor {
    switch (widget.event.impact) {
      case NewsImpact.high:
        return AppColors.impactHigh;
      case NewsImpact.medium:
        return AppColors.impactMedium;
      case NewsImpact.low:
        return AppColors.impactLow;
      case NewsImpact.unknown:
        return AppColors.impactNeutral;
    }
  }

  String get _impactLabel {
    switch (widget.event.impact) {
      case NewsImpact.high:
        return 'HIGH';
      case NewsImpact.medium:
        return 'MED';
      case NewsImpact.low:
        return 'LOW';
      case NewsImpact.unknown:
        return '—';
    }
  }

  /// Color for the gold-direction badge.
  Color _directionColor(AnalysisDirection d) {
    switch (d) {
      case AnalysisDirection.bullish:
        return AppColors.success;
      case AnalysisDirection.bearish:
        return AppColors.warning;
      case AnalysisDirection.volatile:
        return AppColors.accent;
      case AnalysisDirection.neutral:
        return AppColors.textMuted;
      case AnalysisDirection.unknown:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final analysis = NewsAnalysisEngine.analyzeForGold(event);
    final autoSentiment = NewsSentimentClassifier.classify(event, analysis);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _impactColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _impactColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _impactLabel,
                    style: AppTypography.chip.copyWith(
                      color: _impactColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _AutoSentimentChip(sentiment: autoSentiment),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.source,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(_timeAgo(event.publishedAt), style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 8),

            // ── Headline ────────────────────────────────────────────────
            Text(
              event.headline,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),

            // ── Gold direction badge + takeaway (collapsed view) ───────
            if (analysis != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _directionColor(
                        analysis.direction,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _directionColor(
                          analysis.direction,
                        ).withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${analysis.direction.arrow} ${analysis.direction.label} · ${analysis.assetDisplay}',
                      style: AppTypography.chip.copyWith(
                        color: _directionColor(analysis.direction),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                analysis.takeaway,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ] else ...[
              // No gold rule matched — still let the user expand to tag manually.
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'NO DIRECT GOLD IMPACT',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],

            // ── Expanded body ───────────────────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (analysis != null) ...[
                      _section(
                        'WHY THIS MOVES ${analysis.assetDisplay}',
                        analysis.why,
                      ),
                      if (analysis.beatScenario != null) ...[
                        const SizedBox(height: 10),
                        _section(
                          'IF IT BEATS FORECAST',
                          analysis.beatScenario!,
                        ),
                      ],
                      if (analysis.missScenario != null) ...[
                        const SizedBox(height: 10),
                        _section(
                          'IF IT MISSES FORECAST',
                          analysis.missScenario!,
                        ),
                      ],
                      if (analysis.whatToWatch != null) ...[
                        const SizedBox(height: 10),
                        _section('WHAT TO WATCH', analysis.whatToWatch!),
                      ],
                    ] else ...[
                      Text(
                        'This event doesn\'t have a direct rule for gold in the '
                        'knowledge base. It may still affect risk sentiment or '
                        'the dollar indirectly. Use your own read below.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _section('CALENDAR DATA', event.description!),
                    ],
                    const SizedBox(height: 14),
                    // User's own call — still useful for journaling
                    Text(
                      'MY CALL',
                      style: AppTypography.label.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _SentimentChip(
                          label: 'BULL',
                          color: AppColors.success,
                          selected: event.sentiment == NewsSentiment.bullish,
                          onTap: () => widget.onTag(NewsSentiment.bullish),
                        ),
                        const SizedBox(width: 6),
                        _SentimentChip(
                          label: 'BEAR',
                          color: AppColors.warning,
                          selected: event.sentiment == NewsSentiment.bearish,
                          onTap: () => widget.onTag(NewsSentiment.bearish),
                        ),
                        const SizedBox(width: 6),
                        _SentimentChip(
                          label: 'NEUT',
                          color: AppColors.textMuted,
                          selected: event.sentiment == NewsSentiment.neutral,
                          onTap: () => widget.onTag(NewsSentiment.neutral),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          body,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}

class _AutoSentimentChip extends StatelessWidget {
  final NewsSentiment sentiment;

  const _AutoSentimentChip({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (sentiment) {
      NewsSentiment.bullish => ('BULL', AppColors.success),
      NewsSentiment.bearish => ('BEAR', AppColors.warning),
      NewsSentiment.neutral => ('NEUT', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SentimentChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            color: selected ? color : AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ── Rules Tab ─────────────────────────────────────────────────────────────────

class _RulesTab extends StatelessWidget {
  final List<TradingRule> rules;
  final TradingViewModel vm;
  const _RulesTab({required this.rules, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'MY RULES',
                style: AppTypography.label.copyWith(letterSpacing: 2),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddRuleSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '+ ADD RULE',
                    style: AppTypography.chip.copyWith(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (rules.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 32,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text('No rules defined yet', style: AppTypography.body),
                  const SizedBox(height: 4),
                  Text(
                    'Add your own trading rules',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _RuleTile(
                rule: rules[i],
                index: i + 1,
                onDelete: () => vm.deleteRule(rules[i].id),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddRuleSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isNoTrade = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('ADD TRADING RULE', style: AppTypography.label),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(hintText: 'Rule title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Why this rule matters...',
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setSheetState(() => isNoTrade = !isNoTrade),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNoTrade
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isNoTrade
                              ? AppColors.warning
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: isNoTrade
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: AppColors.warning,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NO TRADE rule (hard stop)',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    vm.addRule(
                      title: title,
                      description: desc.isEmpty ? title : desc,
                      isNoTradeRule: isNoTrade,
                    );
                  },
                  child: Text(
                    'SAVE RULE',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.background,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final TradingRule rule;
  final int index;
  final VoidCallback onDelete;

  const _RuleTile({
    required this.rule,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rule.isNoTradeRule
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.title,
                        style: AppTypography.h3.copyWith(fontSize: 13),
                      ),
                    ),
                    if (rule.isNoTradeRule)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NO TRADE',
                          style: AppTypography.chip.copyWith(
                            color: AppColors.warning,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(rule.description, style: AppTypography.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bias Tab ──────────────────────────────────────────────────────────────────

class _BiasTab extends StatelessWidget {
  final List<BiasEntry> biases;
  final TradingViewModel vm;
  final BuildContext context;

  const _BiasTab({
    required this.biases,
    required this.vm,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('BIAS BOARD', style: AppTypography.label),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddBiasSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('ADD', style: AppTypography.chip),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (biases.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.compass_calibration_outlined,
                    color: AppColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text('No bias entries', style: AppTypography.body),
                  const SizedBox(height: 4),
                  Text(
                    'Set your directional bias before trading',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: biases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _BiasTile(
                bias: biases[i],
                onRemove: () => vm.removeBias(biases[i].id),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddBiasSheet(BuildContext context) {
    final instrumentCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    BiasDirection direction = BiasDirection.bullish;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('ADD BIAS', style: AppTypography.label),
              const SizedBox(height: 12),
              TextField(
                controller: instrumentCtrl,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Instrument (e.g. EURUSD)',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: BiasDirection.values.map((d) {
                  final sel = d == direction;
                  final color = d == BiasDirection.bullish
                      ? AppColors.success
                      : d == BiasDirection.bearish
                      ? AppColors.warning
                      : AppColors.textMuted;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => direction = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withValues(alpha: 0.1)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? color : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              d.name.toUpperCase(),
                              style: AppTypography.chip.copyWith(
                                color: sel ? color : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(hintText: 'Reasoning...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (instrumentCtrl.text.trim().isNotEmpty &&
                        reasonCtrl.text.trim().isNotEmpty) {
                      vm.addBias(
                        instrument: instrumentCtrl.text.trim(),
                        direction: direction,
                        reasoning: reasonCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.background,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiasTile extends StatelessWidget {
  final BiasEntry bias;
  final VoidCallback onRemove;

  const _BiasTile({required this.bias, required this.onRemove});

  Color get _color {
    switch (bias.direction) {
      case BiasDirection.bullish:
        return AppColors.success;
      case BiasDirection.bearish:
        return AppColors.warning;
      case BiasDirection.neutral:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bias.instrument.toUpperCase(),
                      style: AppTypography.h3.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bias.direction.name.toUpperCase(),
                        style: AppTypography.chip.copyWith(
                          color: _color,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(bias.reasoning, style: AppTypography.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Targets Tab ───────────────────────────────────────────────────────────────

class _TargetsTab extends StatelessWidget {
  final List<TradingTarget> targets;
  final TradingViewModel vm;
  final BuildContext context;

  const _TargetsTab({
    required this.targets,
    required this.vm,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    final active = targets
        .where((t) => t.status == TargetStatus.active)
        .toList();
    final completed = targets
        .where((t) => t.status == TargetStatus.completed)
        .toList();
    final abandoned = targets
        .where((t) => t.status == TargetStatus.abandoned)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text('TARGETS', style: AppTypography.label),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddTargetSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('NEW', style: AppTypography.chip),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (targets.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: AppColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text('No targets yet', style: AppTypography.body),
                  const SizedBox(height: 4),
                  Text(
                    'Set a capital growth target to begin',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              physics: const BouncingScrollPhysics(),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionLabel('ACTIVE'),
                  ...active.map(
                    (t) => _TargetCard(
                      target: t,
                      onUpdate: (cap) => vm.updateTargetCapital(t.id, cap),
                      onAbandon: () => vm.abandonTarget(t.id),
                      onDelete: () => vm.deleteTarget(t.id),
                    ),
                  ),
                ],
                if (completed.isNotEmpty) ...[
                  _sectionLabel('COMPLETED'),
                  ...completed.map(
                    (t) => _TargetCard(
                      target: t,
                      onDelete: () => vm.deleteTarget(t.id),
                    ),
                  ),
                ],
                if (abandoned.isNotEmpty) ...[
                  _sectionLabel('ABANDONED'),
                  ...abandoned.map(
                    (t) => _TargetCard(
                      target: t,
                      onDelete: () => vm.deleteTarget(t.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      label,
      style: AppTypography.label.copyWith(
        fontSize: 10,
        color: AppColors.textMuted,
      ),
    ),
  );

  void _showAddTargetSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final dailyCtrl = TextEditingController();
    final sessionCtrl = TextEditingController();
    final lotCtrl = TextEditingController();
    final maxTradesCtrl = TextEditingController(text: '2');
    final maxLossCtrl = TextEditingController(text: '2');
    final stopLossCtrl = TextEditingController();
    final tfValueCtrl = TextEditingController(text: '5');
    final notesCtrl = TextEditingController();

    TargetTimeframe tf = TargetTimeframe.days;
    bool stopAfterDaily = true;
    bool stopAfterLossThresh = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('NEW TARGET', style: AppTypography.label),
              const SizedBox(height: 16),
              _field(titleCtrl, 'Title (e.g. Grow to \$100 in 5 days)'),
              _field(startCtrl, 'Starting capital (\$)', number: true),
              _field(targetCtrl, 'Target capital (\$)', number: true),
              _field(dailyCtrl, 'Daily target (\$)', number: true),
              _field(sessionCtrl, 'Session target (\$)', number: true),
              _field(lotCtrl, 'Lot size (e.g. 0.01)', number: true),
              _field(maxTradesCtrl, 'Max trades per session', number: true),
              _field(maxLossCtrl, 'Max daily losses', number: true),
              _field(stopLossCtrl, 'Stop-loss threshold (\$)', number: true),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _field(tfValueCtrl, 'Duration', number: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVar,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TargetTimeframe>(
                          value: tf,
                          dropdownColor: AppColors.surface,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          items: TargetTimeframe.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v.label,
                                    style: AppTypography.body,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => tf = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: stopAfterDaily,
                onChanged: (v) => setState(() => stopAfterDaily = v),
                title: Text(
                  'Stop after daily target hit',
                  style: AppTypography.body,
                ),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accent,
              ),
              SwitchListTile(
                value: stopAfterLossThresh,
                onChanged: (v) => setState(() => stopAfterLossThresh = v),
                title: Text(
                  'Stop after loss threshold',
                  style: AppTypography.body,
                ),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accent,
              ),
              _field(notesCtrl, 'Notes (optional)', maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final start = double.tryParse(startCtrl.text) ?? 0;
                    final tgt = double.tryParse(targetCtrl.text) ?? 0;
                    final tfVal = int.tryParse(tfValueCtrl.text) ?? 5;
                    if (titleCtrl.text.trim().isEmpty ||
                        start <= 0 ||
                        tgt <= start) {
                      return;
                    }

                    Duration dur;
                    switch (tf) {
                      case TargetTimeframe.hours:
                        dur = Duration(hours: tfVal);
                        break;
                      case TargetTimeframe.days:
                        dur = Duration(days: tfVal);
                        break;
                      case TargetTimeframe.weeks:
                        dur = Duration(days: tfVal * 7);
                        break;
                      case TargetTimeframe.months:
                        dur = Duration(days: tfVal * 30);
                        break;
                    }

                    vm.addTarget(
                      TradingTarget(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        startingCapital: start,
                        targetCapital: tgt,
                        currentCapital: start,
                        dailyTarget: double.tryParse(dailyCtrl.text) ?? 0,
                        sessionTarget: double.tryParse(sessionCtrl.text) ?? 0,
                        lotSize: double.tryParse(lotCtrl.text) ?? 0.01,
                        maxTradesPerSession:
                            int.tryParse(maxTradesCtrl.text) ?? 2,
                        maxDailyLosses: int.tryParse(maxLossCtrl.text) ?? 2,
                        stopLossThreshold:
                            double.tryParse(stopLossCtrl.text) ?? 0,
                        stopAfterDailyTarget: stopAfterDaily,
                        stopAfterLossThreshold: stopAfterLossThresh,
                        timeframe: tf,
                        timeframeValue: tfVal,
                        startDate: DateTime.now(),
                        endDate: DateTime.now().add(dur),
                        status: TargetStatus.active,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'CREATE TARGET',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.background,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}

// ── Target Card ───────────────────────────────────────────────────────────────

class _TargetCard extends StatelessWidget {
  final TradingTarget target;
  final void Function(double)? onUpdate;
  final VoidCallback? onAbandon;
  final VoidCallback onDelete;

  const _TargetCard({
    required this.target,
    required this.onDelete,
    this.onUpdate,
    this.onAbandon,
  });

  Color get _statusColor {
    switch (target.status) {
      case TargetStatus.active:
        return AppColors.success;
      case TargetStatus.completed:
        return AppColors.accent;
      case TargetStatus.abandoned:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  target.title,
                  style: AppTypography.h3.copyWith(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  target.status.label,
                  style: AppTypography.chip.copyWith(
                    color: _statusColor,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${target.currentCapital.toStringAsFixed(2)}',
                style: AppTypography.h2.copyWith(fontSize: 18),
              ),
              Text(
                ' / \$${target.targetCapital.toStringAsFixed(2)}',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: target.progressPercent,
              minHeight: 3,
              backgroundColor: AppColors.surfaceVar,
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat('LOT', '${target.lotSize}'),
              const SizedBox(width: 16),
              _Stat('DAILY', '\$${target.dailyTarget.toStringAsFixed(0)}'),
              const SizedBox(width: 16),
              _Stat('SESSION', '\$${target.sessionTarget.toStringAsFixed(0)}'),
              const Spacer(),
              if (target.status == TargetStatus.active)
                Text(
                  '${target.daysRemaining}d left',
                  style: AppTypography.caption.copyWith(
                    color: target.daysRemaining < 2
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          if (target.status == TargetStatus.active) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1, thickness: 0.5),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showUpdateSheet(context),
                  child: Text(
                    'UPDATE CAPITAL',
                    style: AppTypography.label.copyWith(
                      color: AppColors.accent,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                if (onAbandon != null)
                  GestureDetector(
                    onTap: onAbandon,
                    child: Text(
                      'ABANDON',
                      style: AppTypography.label.copyWith(
                        color: AppColors.warning,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onDelete,
                child: Text(
                  'DELETE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpdateSheet(BuildContext context) {
    final addCtrl = TextEditingController();
    final setCtrl = TextEditingController(
      text: target.currentCapital.toStringAsFixed(2),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('UPDATE CAPITAL', style: AppTypography.label),
            const SizedBox(height: 12),
            TextField(
              controller: addCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Income / profit to add',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Set exact current capital',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(addCtrl.text);
                  if (val != null && onUpdate != null) {
                    onUpdate!(target.currentCapital + val);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ADD INCOME',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final val = double.tryParse(setCtrl.text);
                  if (val != null && onUpdate != null) {
                    onUpdate!(val);
                    Navigator.pop(ctx);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'SET CAPITAL',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        Text(value, style: AppTypography.mono.copyWith(fontSize: 12)),
      ],
    );
  }
}
