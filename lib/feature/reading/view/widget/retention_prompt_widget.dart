// lib/features/reading/view/widgets/retention_prompt_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/knowledge_note_model.dart';
import '../../viewmodel/reading_viewmodel.dart';

class RetentionPromptWidget extends ConsumerStatefulWidget {
  const RetentionPromptWidget({super.key});

  @override
  ConsumerState<RetentionPromptWidget> createState() =>
      _RetentionPromptWidgetState();
}

class _RetentionPromptWidgetState
    extends ConsumerState<RetentionPromptWidget> {
  int _currentPromptIndex = 0;
  final _answerCtrl = TextEditingController();
  bool _answered = false;

  static const _prompts = [
    _RetentionPrompt(
      question: 'What is the single most important thing you learned from your reading today?',
      type: KnowledgeNoteType.lesson,
    ),
    _RetentionPrompt(
      question: 'How can you apply what you read today to your work or trading?',
      type: KnowledgeNoteType.application,
    ),
    _RetentionPrompt(
      question: 'What did you read that challenged or changed your thinking?',
      type: KnowledgeNoteType.lesson,
    ),
    _RetentionPrompt(
      question: 'What question does your reading raise that you want to explore further?',
      type: KnowledgeNoteType.question,
    ),
    _RetentionPrompt(
      question: 'How does what you read connect to something you already know or believe?',
      type: KnowledgeNoteType.connection,
    ),
  ];

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  void _nextPrompt() {
    setState(() {
      _currentPromptIndex =
          (_currentPromptIndex + 1) % _prompts.length;
      _answered = false;
      _answerCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readingViewModelProvider);
    final vm = ref.read(readingViewModelProvider.notifier);
    final prompt = _prompts[_currentPromptIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'RETENTION'),

        // ── Today reading stats ───────────────────────────────────
        _ReadingStatsCard(state: state),

        const SizedBox(height: AppSpacing.xl),

        // ── Spaced recall prompt ──────────────────────────────────
        const RichSectionHeader(title: 'RECALL PROMPT'),

        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      prompt.question,
                      style: AppTypography.h3
                          .copyWith(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_answered) ...[
                TextField(
                  controller: _answerCtrl,
                  maxLines: 4,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Write your answer...',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _nextPrompt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVar,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: Text('SKIP',
                            style: AppTypography.chip),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        if (_answerCtrl.text.trim().isNotEmpty) {
                          await vm.addKnowledgeNote(
                            bookId: state.activeBook?.id,
                            bookTitle: state.activeBook?.title,
                            content: _answerCtrl.text.trim(),
                            type: prompt.type,
                          );
                          setState(() => _answered = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'SAVE TO VAULT',
                          style: AppTypography.chip.copyWith(
                              color: AppColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: AppSpacing.iconSm,
                          color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Saved to Knowledge Vault',
                          style: AppTypography.body.copyWith(
                              color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: _nextPrompt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVar,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd),
                      border: Border.all(
                          color: AppColors.border, width: 0.5),
                    ),
                    child: Text('NEXT PROMPT',
                        style: AppTypography.chip),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RetentionPrompt {
  final String question;
  final KnowledgeNoteType type;

  const _RetentionPrompt({
    required this.question,
    required this.type,
  });
}

class _ReadingStatsCard extends StatelessWidget {
  final ReadingState state;

  const _ReadingStatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final reading = state.currentlyReading;
    final completed = state.completedBooks;
    final unreviewed = state.unreviewedHighlights.length;
    final notes = state.allNotes.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCol(
              label: 'READING',
              value: '${reading.length}',
            ),
          ),
          Container(
              width: 0.5, height: 36, color: AppColors.divider),
          Expanded(
            child: _StatCol(
              label: 'DONE',
              value: '${completed.length}',
              color: AppColors.success,
            ),
          ),
          Container(
              width: 0.5, height: 36, color: AppColors.divider),
          Expanded(
            child: _StatCol(
              label: 'TO REVIEW',
              value: '$unreviewed',
              color: unreviewed > 0
                  ? AppColors.caution
                  : AppColors.textMuted,
            ),
          ),
          Container(
              width: 0.5, height: 36, color: AppColors.divider),
          Expanded(
            child: _StatCol(
              label: 'NOTES',
              value: '$notes',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h2.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
