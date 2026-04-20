// lib/features/reading/view/widgets/book_progress_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/book_model.dart';
import '../../viewmodel/reading_viewmodel.dart';

class BookProgressWidget extends ConsumerWidget {
  const BookProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingViewModelProvider);
    final vm = ref.read(readingViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'BOOKS',
          trailing: GestureDetector(
            onTap: () => _showAddBookSheet(context, vm),
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
        ),

        // ── Currently reading ─────────────────────────────────────
        if (state.currentlyReading.isNotEmpty) ...[
          Text('READING', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...state.currentlyReading.map(
            (book) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.md),
              child: _BookCard(
                book: book,
                onUpdateProgress: (page) =>
                    vm.updateProgress(book.id, page),
                onDelete: () => vm.deleteBook(book.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Completed ─────────────────────────────────────────────
        if (state.completedBooks.isNotEmpty) ...[
          Text('COMPLETED', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...state.completedBooks.map(
            (book) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CompletedBookTile(book: book),
            ),
          ),
        ],

        // ── Empty state ───────────────────────────────────────────
        if (state.allBooks.isEmpty)
          _EmptyBooks(onAdd: () => _showAddBookSheet(context, vm)),
      ],
    );
  }

  void _showAddBookSheet(BuildContext context, ReadingViewModel vm) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();
    BookCategory category = BookCategory.selfDevelopment;

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
              Text('ADD BOOK', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: authorCtrl,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Author'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: pagesCtrl,
                keyboardType: TextInputType.number,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Total pages'),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: BookCategory.values.map((c) {
                  final isSelected = c == category;
                  return GestureDetector(
                    onTap: () => setState(() => category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.surfaceVar,
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        c.label,
                        style: AppTypography.chip.copyWith(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isNotEmpty &&
                        authorCtrl.text.trim().isNotEmpty) {
                      vm.addBook(
                        title: titleCtrl.text.trim(),
                        author: authorCtrl.text.trim(),
                        totalPages:
                            int.tryParse(pagesCtrl.text) ?? 200,
                        category: category,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    'ADD',
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

class _BookCard extends StatelessWidget {
  final BookModel book;
  final ValueChanged<int> onUpdateProgress;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onUpdateProgress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: book.readTodayAlready
              ? AppColors.success.withValues(alpha: 0.3)
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
                    Text(
                      book.title,
                      style: AppTypography.h3.copyWith(
                          fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(book.author,
                        style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  book.category.label,
                  style: AppTypography.chip.copyWith(fontSize: 9),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '${book.currentPage} / ${book.totalPages} pages',
                style: AppTypography.mono.copyWith(fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${(book.progressPercent * 100).toStringAsFixed(0)}%',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: book.progressPercent,
              backgroundColor: AppColors.surfaceVar,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _showUpdateSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'UPDATE PAGE',
                style: AppTypography.chip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateSheet(BuildContext context) {
    final ctrl = TextEditingController(
        text: book.currentPage.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
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
            Text('UPDATE PROGRESS', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Text(book.title, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Current page',
                suffixText: '/ ${book.totalPages}',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final page = int.tryParse(ctrl.text.trim());
                  if (page != null) {
                    onUpdateProgress(page);
                    Navigator.pop(context);
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
    );
  }
}

class _CompletedBookTile extends StatelessWidget {
  final BookModel book;

  const _CompletedBookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: AppSpacing.iconSm, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)),
                Text(book.author, style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            '${book.totalPages}p',
            style: AppTypography.mono.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBooks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.auto_stories_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('No books added yet',
                style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text('Add your first book to begin',
                style: AppTypography.caption),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.border, width: 0.5),
                ),
                child: Text('ADD BOOK',
                    style: AppTypography.chip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
