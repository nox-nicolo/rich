// lib/features/life/view/widgets/language_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/ai_lesson_service.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/language_model.dart';
import '../../viewmodel/life_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT WIDGET — shown when LANGUAGE tab is active
// ─────────────────────────────────────────────────────────────────────────────

class LanguageWidget extends ConsumerWidget {
  const LanguageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);

    if (!state.hasActiveLanguage) {
      return _LanguagePickerScreen(allLanguages: state.allLanguages);
    }

    return _LanguageDashboard(progress: state.activeLanguage!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE PICKER — shown when no language is active
// ─────────────────────────────────────────────────────────────────────────────

class _LanguagePickerScreen extends ConsumerWidget {
  final List<LanguageProgress> allLanguages;
  const _LanguagePickerScreen({required this.allLanguages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(lifeViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'LEARN A LANGUAGE'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'One language at a time.',
                style: AppTypography.h3.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete every topic before moving to the next language. '
                'Depth beats breadth.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('CHOOSE YOUR LANGUAGE', style: AppTypography.label),
        const SizedBox(height: AppSpacing.md),
        ...SupportedLanguage.values.map((lang) {
          final existing = allLanguages.where((l) => l.language == lang);
          final hasProgress = existing.isNotEmpty;
          final progress = hasProgress ? existing.first : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => vm.enrollLanguage(lang),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                lang.label,
                                style: AppTypography.h3.copyWith(fontSize: 14),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                lang.nativeName,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(lang.speakers, style: AppTypography.caption),
                              const SizedBox(width: AppSpacing.sm),
                              _DifficultyBadge(difficulty: lang.difficulty),
                            ],
                          ),
                          if (hasProgress && progress != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _MiniProgressBar(percent: progress.progressPercent),
                            const SizedBox(height: 2),
                            Text(
                              '${progress.progressPercent}% — ${progress.completedTopics}/20 topics',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      hasProgress ? Icons.play_arrow : Icons.arrow_forward_ios,
                      size: AppSpacing.iconSm,
                      color: hasProgress
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE DASHBOARD — shown when a language is active
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageDashboard extends ConsumerStatefulWidget {
  final LanguageProgress progress;
  const _LanguageDashboard({required this.progress});

  @override
  ConsumerState<_LanguageDashboard> createState() => _LanguageDashboardState();
}

class _LanguageDashboardState extends ConsumerState<_LanguageDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lifeViewModelProvider);
    final lang = state.activeLanguage ?? widget.progress;
    final vm = ref.read(lifeViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        RichSectionHeader(
          title: '${lang.language.flag}  ${lang.language.label.toUpperCase()}',
          trailing: GestureDetector(
            onTap: () => _showPauseDialog(context, vm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text('SWITCH', style: AppTypography.chip),
            ),
          ),
        ),

        // ── Progress card ────────────────────────────────────────────────────
        _ProgressCard(lang: lang),
        const SizedBox(height: AppSpacing.lg),

        // ── Sub-tabs: Topics / Flashcards / Vocabulary ───────────────────────
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTypography.label.copyWith(fontSize: 11),
          tabs: const [
            Tab(text: 'TOPICS'),
            Tab(text: 'FLASHCARDS'),
            Tab(text: 'PRACTICE'),
            Tab(text: 'WORDS'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Tab content ──────────────────────────────────────────────────────
        SizedBox(
          height: 520,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _TopicsList(lang: lang),
              _FlashcardSession(lang: lang),
              _PracticeTutor(lang: lang),
              _VocabularyList(lang: lang),
            ],
          ),
        ),
      ],
    );
  }

  void _showPauseDialog(BuildContext ctx, LifeViewModel vm) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SWITCH LANGUAGE', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your progress is saved. You can resume this language anytime.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  vm.pauseLanguage();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'CHOOSE ANOTHER LANGUAGE',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Text('KEEP STUDYING', style: AppTypography.chip),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final LanguageProgress lang;
  const _ProgressCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.currentPhase.label.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(lang.currentPhase.range, style: AppTypography.caption),
                  ],
                ),
              ),
              Text(
                '${lang.progressPercent}%',
                style: AppTypography.h1.copyWith(
                  fontSize: 32,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MiniProgressBar(percent: lang.progressPercent, height: 6),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatChip(label: 'TOPICS', value: '${lang.completedTopics}/20'),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(label: 'WORDS', value: '${lang.wordsLearned}'),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(label: 'XP', value: '${lang.totalXp}'),
              const SizedBox(width: AppSpacing.sm),
              if (lang.dueForReview.isNotEmpty)
                _StatChip(
                  label: 'REVIEW',
                  value: '${lang.dueForReview.length}',
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPICS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _TopicsList extends ConsumerWidget {
  final LanguageProgress lang;
  const _TopicsList({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: lang.topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) {
        final topic = lang.topics[i];
        final unlocked = lang.isTopicUnlocked(i);

        return GestureDetector(
          onTap: unlocked ? () => _openLesson(ctx, topic) : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPad),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: topic.isCompleted
                    ? AppColors.success.withValues(alpha: 0.3)
                    : unlocked
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: topic.isCompleted
                        ? AppColors.success.withValues(alpha: 0.15)
                        : unlocked
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : AppColors.surfaceVar,
                  ),
                  child: Center(
                    child: topic.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.success,
                          )
                        : unlocked
                        ? Text(
                            '${topic.order}',
                            style: AppTypography.mono.copyWith(
                              fontSize: 11,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(
                            Icons.lock_outline,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: AppTypography.h3.copyWith(
                          fontSize: 13,
                          color: unlocked
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(topic.phase.label, style: AppTypography.caption),
                          if (topic.isCompleted) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'DONE',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (unlocked && !topic.isCompleted)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openLesson(BuildContext ctx, TopicModel topic) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => _LessonScreen(topic: topic)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LESSON SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _LessonScreen extends ConsumerStatefulWidget {
  final TopicModel topic;
  const _LessonScreen({required this.topic});

  @override
  ConsumerState<_LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<_LessonScreen> {
  String? _lessonText;
  bool _isLoadingLesson = true;

  @override
  void initState() {
    super.initState();
    _fetchLesson();
  }

  Future<void> _fetchLesson({bool forceRefresh = false}) async {
    final vm = ref.read(lifeViewModelProvider.notifier);
    final text = await vm
        .loadLesson(widget.topic.id, forceRefresh: forceRefresh)
        .timeout(
          const Duration(seconds: 110),
          onTimeout: () {
            vm.stopLessonGeneration(
              'The AI lesson took too long. Check your connection and try again.',
            );
            return _localFallbackLesson();
          },
        );
    if (!mounted) return;
    setState(() {
      _lessonText = text;
      _isLoadingLesson = false;
    });
  }

  void _retryLesson() {
    setState(() {
      _lessonText = null;
      _isLoadingLesson = true;
    });
    _fetchLesson(forceRefresh: true);
  }

  String _localFallbackLesson() {
    return '''
## ${widget.topic.title}

${widget.topic.description}

## OFFLINE MODE
The AI tutor is taking longer than expected. Start with the topic goal, review your vocabulary, and try opening the lesson again when the connection is stronger.

Your progress is saved. Retry the AI lesson before completing this topic.
''';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lifeViewModelProvider);
    final vm = ref.read(lifeViewModelProvider.notifier);
    final lang = state.activeLanguage;
    final matchingTopics =
        lang?.topics.where((t) => t.id == widget.topic.id).toList() ?? [];
    final topic = matchingTopics.isNotEmpty
        ? matchingTopics.first
        : widget.topic;
    final aiUnavailable = state.lessonError != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          topic.title,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: _isLoadingLesson ? null : _retryLesson,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text('REGENERATE', style: AppTypography.chip),
              ),
            ),
          ),
          if (!topic.isCompleted && !aiUnavailable)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: GestureDetector(
                onTap: () async {
                  await vm.completeTopic(topic.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'COMPLETE',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingLesson
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 1,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Generating your lesson…',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : _lessonText == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 1,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.lessonError != null) ...[
                    _LessonNotice(message: state.lessonError!),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _retryLesson,
                        child: Text(
                          'RETRY AI LESSON',
                          style: AppTypography.chip,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  // Phase badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      topic.phase.label.toUpperCase(),
                      style: AppTypography.chip.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Lesson content rendered as markdown-like text
                  _LessonContent(text: _lessonText!),

                  const SizedBox(height: AppSpacing.x3l),

                  // Complete button at bottom
                  if (!topic.isCompleted && !aiUnavailable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await vm.completeTopic(topic.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                          'MARK COMPLETE',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LESSON CONTENT RENDERER
// ─────────────────────────────────────────────────────────────────────────────

class _LessonNotice extends StatelessWidget {
  final String message;
  const _LessonNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.caution.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.caution.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Text(
        message,
        style: AppTypography.caption.copyWith(color: AppColors.caution),
      ),
    );
  }
}

class _LessonContent extends StatelessWidget {
  final String text;
  const _LessonContent({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              line.replaceFirst('## ', ''),
              style: AppTypography.h3.copyWith(
                color: AppColors.accent,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          );
        }
        if (line.startsWith('- ') || line.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.xs,
              left: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: AppTypography.body.copyWith(color: AppColors.accent),
                ),
                Expanded(
                  child: Text(
                    line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          );
        }
        if (line.startsWith('1.') ||
            line.startsWith('2.') ||
            line.startsWith('3.')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(line, style: AppTypography.body),
          );
        }
        if (line.trim().isEmpty) {
          return const SizedBox(height: AppSpacing.sm);
        }
        if (line.contains('|')) {
          // Vocabulary table row
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(line, style: AppTypography.mono.copyWith(fontSize: 12)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(line, style: AppTypography.body),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLASHCARD SESSION
// ─────────────────────────────────────────────────────────────────────────────

class _FlashcardSession extends ConsumerStatefulWidget {
  final LanguageProgress lang;
  const _FlashcardSession({required this.lang});

  @override
  ConsumerState<_FlashcardSession> createState() => _FlashcardSessionState();
}

class _FlashcardSessionState extends ConsumerState<_FlashcardSession> {
  late List<VocabularyItem> _deck;
  int _currentIndex = 0;
  bool _showAnswer = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Priority 1: words due for spaced-repetition review
    // Priority 2: new words (masteryLevel == 0) — always show these first
    // Priority 3: all known words for general practice
    final due = widget.lang.dueForReview;
    final newWords = widget.lang.vocabulary
        .where((v) => v.masteryLevel == 0)
        .toList();
    if (due.isNotEmpty) {
      _deck = due;
    } else if (newWords.isNotEmpty) {
      _deck = newWords;
    } else {
      _deck = List.from(widget.lang.vocabulary);
    }
    _deck.shuffle();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  VocabularyItem get _current => _deck[_currentIndex];

  Future<void> _speak(String word) async {
    final lang = ref.read(lifeViewModelProvider).activeLanguage;
    if (lang == null) return;
    await _tts.setLanguage(_ttsLocale(lang.language));
    await _tts.speak(word);
  }

  String _ttsLocale(SupportedLanguage lang) {
    switch (lang) {
      case SupportedLanguage.mandarin:
        return 'zh-CN';
      case SupportedLanguage.spanish:
        return 'es-ES';
      case SupportedLanguage.hindi:
        return 'hi-IN';
      case SupportedLanguage.arabic:
        return 'ar-SA';
      case SupportedLanguage.french:
        return 'fr-FR';
      case SupportedLanguage.portuguese:
        return 'pt-BR';
      case SupportedLanguage.russian:
        return 'ru-RU';
      case SupportedLanguage.japanese:
        return 'ja-JP';
      case SupportedLanguage.english:
        return 'en-UK';
      case SupportedLanguage.german:
        return 'de-DE';
    }
  }

  void _next(bool wasEasy) {
    final vm = ref.read(lifeViewModelProvider.notifier);
    final updatedVocab = List<VocabularyItem>.from(widget.lang.vocabulary);
    final idx = updatedVocab.indexWhere((v) => v.word == _current.word);
    if (idx >= 0) {
      updatedVocab[idx] = wasEasy
          ? updatedVocab[idx].markEasy()
          : updatedVocab[idx].markHard();
      vm.updateVocabularyMastery(updatedVocab);
    }

    setState(() {
      _showAnswer = false;
      if (_currentIndex < _deck.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // loop
        _deck.shuffle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              color: AppColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No vocabulary yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start a topic — words appear here automatically',
              style: AppTypography.caption,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentIndex + 1} / ${_deck.length}',
              style: AppTypography.mono.copyWith(fontSize: 12),
            ),
            Text(
              '${widget.lang.dueForReview.length} due for review',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Card
        GestureDetector(
          onTap: () => setState(() => _showAnswer = !_showAnswer),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: _showAnswer
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // Word + speak button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _current.word,
                      style: AppTypography.h1.copyWith(fontSize: 36),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => _speak(_current.word),
                      child: const Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Phonetic
                Text(
                  _current.phonetic,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showAnswer ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _current.translation,
                        style: AppTypography.h3.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _current.example,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _current.exampleTranslation,
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                if (!_showAnswer) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'TAP TO REVEAL',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        if (_showAnswer) ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _next(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'HARD',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => _next(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'EASY',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            'Mastery: ${'■' * _current.masteryLevel}${'□' * (5 - _current.masteryLevel)}',
            style: AppTypography.mono.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI PRACTICE TUTOR
// ─────────────────────────────────────────────────────────────────────────────

class _PracticeTutor extends ConsumerStatefulWidget {
  final LanguageProgress lang;
  const _PracticeTutor({required this.lang});

  @override
  ConsumerState<_PracticeTutor> createState() => _PracticeTutorState();
}

class _PracticeTutorState extends ConsumerState<_PracticeTutor> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<_PracticeMessage> _messages = [];
  bool _sending = false;
  bool _speechReady = false;
  bool _listening = false;
  String? _speechStatus;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _PracticeMessage.tutor(
        'Karibu. I am your ${widget.lang.language.label} practice tutor. '
        'Say anything you can, even one sentence, and I will correct you and keep the conversation going.',
      ),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          _speechStatus = status;
          _listening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _speechStatus = error.errorMsg;
        });
      },
    );
    if (!mounted) return;
    setState(() => _speechReady = ready);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Speech recognition is not available yet.',
            style: AppTypography.caption,
          ),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    await _tts.stop();
    await _speech.listen(
      localeId: _ttsLocale(widget.lang.language),
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        _inputCtrl.text = words;
        _inputCtrl.selection = TextSelection.collapsed(offset: words.length);
        if (result.finalResult) {
          setState(() => _listening = false);
          _send(words);
        }
      },
    );
    if (mounted) {
      setState(() {
        _listening = true;
        _speechStatus = 'listening';
      });
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _sending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    }

    setState(() {
      _messages.add(_PracticeMessage.user(text));
      _sending = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => '${m.isUser ? 'Student' : 'Tutor'}: ${m.text}')
        .join('\n');

    final reply = await AiLessonService.instance.generatePracticeReply(
      languageName: widget.lang.language.label,
      learnerMessage: text,
      conversationHistory: history,
      progressPercent: widget.lang.progressPercent,
    );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add(
        _PracticeMessage.tutor(
          reply ??
              'I could not reach the AI tutor just now. Try again with a short sentence.',
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.setLanguage(_ttsLocale(widget.lang.language));
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_cleanForSpeech(text));
  }

  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\*\*|[_|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _ttsLocale(SupportedLanguage lang) {
    switch (lang) {
      case SupportedLanguage.english:
        return 'en-US';
      case SupportedLanguage.mandarin:
        return 'zh-CN';
      case SupportedLanguage.spanish:
        return 'es-ES';
      case SupportedLanguage.hindi:
        return 'hi-IN';
      case SupportedLanguage.arabic:
        return 'ar-SA';
      case SupportedLanguage.french:
        return 'fr-FR';
      case SupportedLanguage.portuguese:
        return 'pt-BR';
      case SupportedLanguage.russian:
        return 'ru-RU';
      case SupportedLanguage.japanese:
        return 'ja-JP';
      case SupportedLanguage.german:
        return 'de-DE';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'Introduce yourself',
      'Order coffee',
      'Ask for directions',
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _listening
                      ? 'Listening... speak naturally, then pause.'
                      : 'Practice like a real conversation. Speak or type, then get corrected.',
                  style: AppTypography.caption.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (_speechStatus != null && !_listening && !_speechReady) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_speechStatus!, style: AppTypography.caption),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _send(prompts[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(prompts[i], style: AppTypography.chip),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length + (_sending ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              if (_sending && i == _messages.length) {
                return const _PracticeTypingBubble();
              }
              final message = _messages[i];
              return _PracticeBubble(
                message: message,
                onSpeak: message.isUser ? null : () => _speak(message.text),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 3,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type in ${widget.lang.language.label}...',
                  hintStyle: AppTypography.caption,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _sending ? null : _toggleListening,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _listening
                      ? AppColors.warning.withValues(alpha: 0.18)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _listening
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none_outlined,
                  color: _listening ? AppColors.warning : AppColors.accent,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _sending ? null : () => _send(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending ? AppColors.surfaceVar : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: _sending ? AppColors.textMuted : AppColors.background,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PracticeMessage {
  final String text;
  final bool isUser;

  const _PracticeMessage._({required this.text, required this.isUser});

  factory _PracticeMessage.user(String text) =>
      _PracticeMessage._(text: text, isUser: true);

  factory _PracticeMessage.tutor(String text) =>
      _PracticeMessage._(text: text, isUser: false);
}

class _PracticeBubble extends StatelessWidget {
  final _PracticeMessage message;
  final VoidCallback? onSpeak;
  const _PracticeBubble({required this.message, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? AppColors.accent : AppColors.surface;
    final textColor = message.isUser
        ? AppColors.background
        : AppColors.textPrimary;

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: message.isUser
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTypography.body.copyWith(
                color: textColor,
                height: 1.45,
              ),
            ),
            if (onSpeak != null) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: onSpeak,
                child: Icon(
                  Icons.volume_up_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeTypingBubble extends StatelessWidget {
  const _PracticeTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text('Tutor is thinking...', style: AppTypography.caption),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOCABULARY LIST
// ─────────────────────────────────────────────────────────────────────────────

class _VocabularyList extends StatelessWidget {
  final LanguageProgress lang;
  const _VocabularyList({required this.lang});

  @override
  Widget build(BuildContext context) {
    final words = lang.vocabulary;

    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              color: AppColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No vocabulary yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete topics to build your word bank',
              style: AppTypography.caption,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) {
        final word = words[i];
        return _VocabWordTile(word: word, lang: lang);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOCABULARY WORD TILE — tappable, shows example, speaks word aloud
// ─────────────────────────────────────────────────────────────────────────────

class _VocabWordTile extends StatefulWidget {
  final VocabularyItem word;
  final LanguageProgress lang;
  const _VocabWordTile({required this.word, required this.lang});

  @override
  State<_VocabWordTile> createState() => _VocabWordTileState();
}

class _VocabWordTileState extends State<_VocabWordTile> {
  bool _expanded = false;
  final FlutterTts _tts = FlutterTts();

  String _ttsLocale(SupportedLanguage lang) {
    switch (lang) {
      case SupportedLanguage.english:
        return 'en-US';
      case SupportedLanguage.mandarin:
        return 'zh-CN';
      case SupportedLanguage.spanish:
        return 'es-ES';
      case SupportedLanguage.hindi:
        return 'hi-IN';
      case SupportedLanguage.arabic:
        return 'ar-SA';
      case SupportedLanguage.french:
        return 'fr-FR';
      case SupportedLanguage.portuguese:
        return 'pt-BR';
      case SupportedLanguage.russian:
        return 'ru-RU';
      case SupportedLanguage.japanese:
        return 'ja-JP';
      case SupportedLanguage.german:
        return 'de-DE';
    }
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage(_ttsLocale(widget.lang.language));
    await _tts.setSpeechRate(0.45); // slightly slower for learners
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _expanded
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            word.word,
                            style: AppTypography.h3.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // 🔊 Speak button — tap to hear pronunciation
                          GestureDetector(
                            onTap: () => _speak(word.word),
                            child: const Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        word.phonetic,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        word.translation,
                        style: AppTypography.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Mastery dots
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (j) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: j < word.masteryLevel
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      word.isMastered ? 'MASTERED' : 'Lv ${word.masteryLevel}',
                      style: AppTypography.caption.copyWith(
                        color: word.isMastered
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            // Expanded: example sentence + speak button
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.example,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          word.exampleTranslation,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  // Speak full example sentence
                  GestureDetector(
                    onTap: () => _speak(word.example),
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: const Icon(
                        Icons.record_voice_over_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _MiniProgressBar extends StatelessWidget {
  final int percent;
  final double height;
  const _MiniProgressBar({required this.percent, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: LinearProgressIndicator(
        value: percent / 100,
        minHeight: height,
        backgroundColor: AppColors.surfaceVar,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: highlight
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              color: highlight ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case 'Moderate':
        return AppColors.success;
      case 'Challenging':
        return AppColors.warning;
      case 'Advanced':
        return AppColors.caution;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        difficulty,
        style: AppTypography.caption.copyWith(color: _color, fontSize: 9),
      ),
    );
  }
}
