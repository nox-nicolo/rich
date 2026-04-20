// lib/features/reading/view/widgets/highlights_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/highlight_model.dart';
import '../../viewmodel/reading_viewmodel.dart';

class HighlightsWidget extends ConsumerWidget {
  const HighlightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingViewModelProvider);
    final vm = ref.read(readingViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'HIGHLIGHTS',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.unreviewedHighlights.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.caution.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: AppColors.caution.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${state.unreviewedHighlights.length} new',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.caution,
                      fontSize: 10,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _showAddHighlightSheet(
                    context, vm, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.add,
                      size: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        if (state.allHighlights.isEmpty)
          _EmptyHighlights()
        else
          ...state.allHighlights.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HighlightTile(
                highlight: h,
                onReview: () => vm.markHighlightReviewed(h.id),
              ),
            ),
          ),
      ],
    );
  }

  Color _typeColorFor(HighlightType t) {
    switch (t) {
      case HighlightType.noted:
        return AppColors.textPrimary;
      case HighlightType.vocab:
        return const Color(0xFF4A9EFF);
      case HighlightType.idea:
        return AppColors.success;
    }
  }

  void _showAddHighlightSheet(
    BuildContext context,
    ReadingViewModel vm,
    ReadingState state,
  ) {
    final contentCtrl = TextEditingController();
    HighlightType type = HighlightType.noted;
    String? selectedBookId = state.activeBook?.id;
    String? selectedBookTitle = state.activeBook?.title;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('ADD HIGHLIGHT', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: HighlightType.values.map((t) {
                  final isSelected = t == type;
                  final color = _typeColorFor(t);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: () => setState(() => type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 1 : 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t.label,
                              style: AppTypography.chip.copyWith(
                                color: isSelected ? color : AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                autofocus: true,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Paste or type your highlight...'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentCtrl.text.trim().isNotEmpty) {
                      vm.addHighlight(
                        bookId: selectedBookId ?? 'general',
                        bookTitle:
                            selectedBookTitle ?? 'General',
                        content: contentCtrl.text.trim(),
                        type: type,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    'SAVE',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.background, fontSize: 13),
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

class _HighlightTile extends StatelessWidget {
  final HighlightModel highlight;
  final VoidCallback onReview;

  const _HighlightTile({
    required this.highlight,
    required this.onReview,
  });

  Color get _typeColor {
    switch (highlight.type) {
      case HighlightType.noted:
        return AppColors.textPrimary;
      case HighlightType.vocab:
        return const Color(0xFF4A9EFF);
      case HighlightType.idea:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: !highlight.reviewed
              ? _typeColor.withValues(alpha: 0.2)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  highlight.type.label,
                  style: AppTypography.chip.copyWith(
                    color: _typeColor,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  highlight.bookTitle,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                RichDateUtils.timeAgo(highlight.savedAt),
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            highlight.content,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (highlight.personalNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              highlight.personalNote!,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (!highlight.reviewed) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onReview,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: Text('MARK REVIEWED',
                      style: AppTypography.chip.copyWith(
                          fontSize: 10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHighlights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.bookmark_border_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No highlights yet', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Save insights as you read',
                style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
