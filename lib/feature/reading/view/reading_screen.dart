// lib/feature/reading/view/reading_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/book_model.dart';
import '../model/vocabulary_word_model.dart';
import '../viewmodel/reading_viewmodel.dart';
import 'pdf_reader_screen.dart';
import 'widget/highlights_widget.dart';
import 'widget/knowledge_vault_widget.dart';
import 'widget/retention_prompt_widget.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  static const _tabs = ['SHELF', 'HIGHLIGHTS', 'VAULT', 'RETAIN', 'VOCAB'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingViewModelProvider);
    final vm = ref.read(readingViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'READING',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.currentlyReading.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(label: 'READING', color: AppColors.accent),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 1,
              ),
            )
          : Column(
              children: [
                _ReadingTabBar(
                  tabs: _tabs,
                  selected: state.activeTab,
                  onSelect: vm.setTab,
                ),
                Expanded(child: _tabContent(context, ref, state, vm)),
              ],
            ),
    );
  }

  Widget _tabContent(
    BuildContext context,
    WidgetRef ref,
    ReadingState state,
    ReadingViewModel vm,
  ) {
    switch (state.activeTab) {
      case 'SHELF':
        return _ShelfTab(state: state, vm: vm);
      case 'HIGHLIGHTS':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: HighlightsWidget(),
        );
      case 'VAULT':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KnowledgeVaultWidget(),
        );
      case 'RETAIN':
        return const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: RetentionPromptWidget(),
        );
      case 'VOCAB':
        return _VocabTab(state: state, vm: vm);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Shelf Tab ─────────────────────────────────────────────────────────────────

class _ShelfTab extends ConsumerWidget {
  final ReadingState state;
  final ReadingViewModel vm;
  const _ShelfTab({required this.state, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = state.allBooks;

    return Stack(
      children: [
        books.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text('No books yet', style: AppTypography.body),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a PDF from your device',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  100,
                ),
                children: [
                  // Currently reading
                  if (state.currentlyReading.isNotEmpty) ...[
                    Text(
                      'NOW READING',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReorderableSection(
                      books: state.currentlyReading,
                      onReorder: (o, n) =>
                          vm.reorderBooks(BookStatus.reading, o, n),
                      buildCard: (b) => _BookCard(
                        book: b,
                        canOpen: true,
                        onTap: () => _openBook(context, ref, b),
                        onMarkDone: () => vm.markCompleted(b.id),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Wishlist / queued
                  if (books.any((b) => b.status == BookStatus.wishlist)) ...[
                    Text(
                      'UP NEXT',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReorderableSection(
                      books: books
                          .where((b) => b.status == BookStatus.wishlist)
                          .toList(),
                      onReorder: (o, n) =>
                          vm.reorderBooks(BookStatus.wishlist, o, n),
                      buildCard: (b) => _BookCard(
                        book: b,
                        canOpen: state.currentlyReading.isEmpty,
                        locked: state.currentlyReading.isNotEmpty,
                        onTap: state.currentlyReading.isEmpty
                            ? () => _openBook(context, ref, b)
                            : () => _showLockMessage(context),
                        onMarkDone: () => vm.markCompleted(b.id),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Completed
                  if (state.completedBooks.isNotEmpty) ...[
                    Text(
                      'COMPLETED',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReorderableSection(
                      books: state.completedBooks,
                      onReorder: (o, n) =>
                          vm.reorderBooks(BookStatus.completed, o, n),
                      buildCard: (b) => _BookCard(
                        book: b,
                        canOpen: true,
                        onTap: () => _openBook(context, ref, b),
                        onMarkDone: null,
                      ),
                    ),
                  ],
                ],
              ),

        // ── FAB ──────────────────────────────────────────────────────────
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            onPressed: () => _showAddBookSheet(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _openBook(BuildContext context, WidgetRef ref, BookModel book) async {
    // Start reading if not already
    await ref.read(readingViewModelProvider.notifier).startReading(book.id);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
    );
  }

  void _showLockMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finish your current book before starting the next one.'),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _showAddBookSheet(BuildContext context, WidgetRef ref) {
    final vm = ref.read(readingViewModelProvider.notifier);
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '20');
    String? pickedPath;
    BookCategory category = BookCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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
                Text('ADD BOOK', style: AppTypography.label),
                const SizedBox(height: 16),

                // Pick PDF button
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final path = result.files.single.path!;
                      final name = result.files.single.name
                          .replaceAll('.pdf', '')
                          .replaceAll('_', ' ');
                      setBS(() {
                        pickedPath = path;
                        if (titleCtrl.text.isEmpty) titleCtrl.text = name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pickedPath != null
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.surfaceVar,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pickedPath != null
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pickedPath != null
                              ? Icons.check_circle_outline
                              : Icons.picture_as_pdf_outlined,
                          size: 20,
                          color: pickedPath != null
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedPath != null
                                ? pickedPath!.split('/').last
                                : 'Pick PDF from device',
                            style: AppTypography.body.copyWith(
                              color: pickedPath != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(hintText: 'Book title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: authorCtrl,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(hintText: 'Author'),
                ),
                const SizedBox(height: 10),

                // Category
                DropdownButtonFormField<BookCategory>(
                  initialValue: category,
                  dropdownColor: AppColors.surface,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(hintText: 'Category'),
                  items: BookCategory.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setBS(() => category = v);
                  },
                ),

                const SizedBox(height: 10),
                TextField(
                  controller: goalCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Daily page goal (e.g. 20)',
                  ),
                ),

                const SizedBox(height: 20),
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
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final author = authorCtrl.text.trim();
                      final goal = int.tryParse(goalCtrl.text.trim()) ?? 20;
                      if (title.isEmpty) return;
                      Navigator.pop(ctx);
                      await vm.addBook(
                        title: title,
                        author: author.isNotEmpty ? author : 'Unknown',
                        category: category,
                        filePath: pickedPath,
                        dailyPageGoal: goal < 1 ? 20 : goal,
                      );
                    },
                    child: Text(
                      'ADD TO SHELF',
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
      ),
    );
  }
}

// ── Reorderable Section ───────────────────────────────────────────────────────

/// Drag-to-reorder list of books within one shelf section.
/// Uses `shrinkWrap` + `NeverScrollableScrollPhysics` so it nests inside the
/// outer section ListView; the outer view handles scrolling.
class _ReorderableSection extends StatelessWidget {
  final List<BookModel> books;
  final void Function(int, int) onReorder;
  final Widget Function(BookModel) buildCard;

  const _ReorderableSection({
    required this.books,
    required this.onReorder,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      children: [
        for (var i = 0; i < books.length; i++)
          ReorderableDelayedDragStartListener(
            key: ValueKey(books[i].id),
            index: i,
            child: buildCard(books[i]),
          ),
      ],
    );
  }
}

// ── Cover Thumbnail ───────────────────────────────────────────────────────────

/// PDF first-page cover if one has been cached to disk; otherwise a themed
/// icon placeholder (matches the original shelf card look).
class _CoverThumb extends StatelessWidget {
  final BookModel book;
  final bool locked;
  const _CoverThumb({required this.book, required this.locked});

  @override
  Widget build(BuildContext context) {
    final hasCover =
        book.coverPath != null && File(book.coverPath!).existsSync();

    if (hasCover) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(book.coverPath!),
          width: 42,
          height: 56,
          fit: BoxFit.cover,
          // If the cached image file is corrupt, fall back to the icon.
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hasPdf = book.filePath != null;
    return Container(
      width: 42,
      height: 56,
      decoration: BoxDecoration(
        color: locked
            ? AppColors.locked
            : book.isCompleted
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        locked
            ? Icons.lock_outline
            : book.isCompleted
            ? Icons.check_circle_outline
            : hasPdf
            ? Icons.picture_as_pdf_outlined
            : Icons.menu_book_outlined,
        size: 20,
        color: locked
            ? AppColors.textMuted
            : book.isCompleted
            ? AppColors.success
            : AppColors.accent,
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final BookModel book;
  final bool canOpen;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onMarkDone;

  const _BookCard({
    required this.book,
    required this.canOpen,
    required this.onTap,
    this.locked = false,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final hasPdf = book.filePath != null;

    return GestureDetector(
      onTap: hasPdf ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked ? AppColors.border : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Cover thumbnail if rendered, else icon placeholder.
            _CoverThumb(book: book, locked: locked),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTypography.body.copyWith(
                      color: locked
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.totalPages > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: book.progressPercent,
                        backgroundColor: AppColors.surfaceVar,
                        valueColor: AlwaysStoppedAnimation(
                          book.isCompleted
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(book.progressPercent * 100).toStringAsFixed(0)}%  ·  page ${book.currentPage} / ${book.totalPages}',
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                  ],
                  // Daily page goal line — only for the book currently being read
                  if (book.isCurrentlyReading) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          book.dailyGoalMet
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 10,
                          color: book.dailyGoalMet
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TODAY  ${book.pagesReadToday} / ${book.dailyPageGoal}',
                          style: AppTypography.chip.copyWith(
                            fontSize: 9,
                            color: book.dailyGoalMet
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (locked)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Finish current book to unlock',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPdf && !locked)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                if (onMarkDone != null && !book.isCompleted)
                  GestureDetector(
                    onTap: onMarkDone,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'DONE',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vocab Tab ─────────────────────────────────────────────────────────────────

class _VocabTab extends ConsumerWidget {
  final ReadingState state;
  final ReadingViewModel vm;
  const _VocabTab({required this.state, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        state.vocabulary.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.spellcheck,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text('No vocabulary yet', style: AppTypography.body),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  100,
                ),
                itemCount: state.vocabulary.length,
                itemBuilder: (_, i) => _VocabCard(
                  word: state.vocabulary[i],
                  onReview: () =>
                      vm.incrementVocabReview(state.vocabulary[i].id),
                  onDelete: () => vm.deleteVocabWord(state.vocabulary[i].id),
                ),
              ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            onPressed: () => _showAddWordSheet(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showAddWordSheet(BuildContext context, WidgetRef ref) {
    final vm = ref.read(readingViewModelProvider.notifier);
    final wordCtrl = TextEditingController();
    final meanCtrl = TextEditingController();
    final exCtrl = TextEditingController();

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
            Text('ADD WORD', style: AppTypography.label),
            const SizedBox(height: 12),
            TextField(
              controller: wordCtrl,
              autofocus: true,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Word'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: meanCtrl,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Meaning / definition',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: exCtrl,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Example sentence (optional)',
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
                onPressed: () async {
                  final word = wordCtrl.text.trim();
                  final mean = meanCtrl.text.trim();
                  if (word.isEmpty || mean.isEmpty) return;
                  Navigator.pop(ctx);
                  await vm.addVocabWord(
                    word: word,
                    meaning: mean,
                    exampleSentence: exCtrl.text.trim().isNotEmpty
                        ? exCtrl.text.trim()
                        : null,
                  );
                },
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
    );
  }
}

/// Expandable vocab card — collapsed shows the word, phonetic, and a
/// one-line meaning; expanded shows every POS definition, examples,
/// synonyms/antonyms, and an editable personal note.
///
/// Designed to feel like a mini offline dictionary so users don't have to
/// leave the app to understand a word they saved while reading.
class _VocabCard extends ConsumerStatefulWidget {
  final VocabularyWord word;
  final VoidCallback onReview;
  final VoidCallback onDelete;
  const _VocabCard({
    required this.word,
    required this.onReview,
    required this.onDelete,
  });

  @override
  ConsumerState<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends ConsumerState<_VocabCard> {
  bool _expanded = false;
  bool _refreshing = false;
  bool _speaking = false;
  final FlutterTts _tts = FlutterTts();

  VocabularyWord get _word => widget.word;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakWord() async {
    if (_speaking) return;
    setState(() => _speaking = true);

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.speak(_word.word);
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _speaking = false);
        });
      }
    }
  }

  Future<void> _refreshDefinition() async {
    setState(() => _refreshing = true);
    final ok = await ref
        .read(readingViewModelProvider.notifier)
        .refreshVocabDefinition(_word.id);
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Definition updated' : 'Could not find a definition',
          style: AppTypography.caption,
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editPersonalNote() {
    final ctrl = TextEditingController(text: _word.personalNote ?? '');
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
            Text(
              'MY NOTE · ${_word.word.toUpperCase()}',
              style: AppTypography.label,
            ),
            const SizedBox(height: 4),
            Text(
              'Mnemonic, context, or why you saved this word.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Your thoughts on this word...',
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(readingViewModelProvider.notifier)
                      .updateVocabPersonalNote(_word.id, ctrl.text);
                },
                child: Text(
                  'SAVE NOTE',
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: word · phonetic · review · delete ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              _word.word,
                              style: AppTypography.h3.copyWith(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_word.phonetic != null &&
                              _word.phonetic!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              _word.phonetic!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _word.meaning,
                        style: AppTypography.caption,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Speak word',
                      child: GestureDetector(
                        onTap: _speakWord,
                        child: Icon(
                          _speaking
                              ? Icons.volume_up
                              : Icons.volume_up_outlined,
                          size: 17,
                          color: _speaking
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onReview,
                      child: Text(
                        '${_word.reviewCount}×',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),

            // ── Expanded rich-dictionary panel ────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Definitions grouped by part of speech
              if (_word.meaningsByPos.isNotEmpty)
                ..._word.meaningsByPos.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PosBlock(pos: e.key, defs: e.value),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No rich dictionary data saved for this word.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

              // Examples
              if (_word.examples.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('EXAMPLES', style: AppTypography.label),
                const SizedBox(height: 4),
                ..._word.examples
                    .take(4)
                    .map(
                      (ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '· "$ex"',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
              ],

              // Synonyms / Antonyms
              if (_word.synonyms.isNotEmpty)
                _ChipRow(
                  label: 'SYN',
                  items: _word.synonyms.take(8).toList(),
                  color: const Color(0xFF4A9EFF),
                ),
              if (_word.antonyms.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ChipRow(
                  label: 'ANT',
                  items: _word.antonyms.take(8).toList(),
                  color: const Color(0xFFE5706B),
                ),
              ],

              // Personal note
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _editPersonalNote,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MY NOTE', style: AppTypography.label),
                      const SizedBox(height: 4),
                      Text(
                        _word.personalNote?.isNotEmpty == true
                            ? _word.personalNote!
                            : 'Tap to add mnemonic or personal context…',
                        style: AppTypography.caption.copyWith(
                          color: _word.personalNote?.isNotEmpty == true
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Source + refresh
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_word.sourceBookTitle != null)
                    Expanded(
                      child: Text(
                        'from ${_word.sourceBookTitle}${_word.sourcePage != null ? ' · p${_word.sourcePage}' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  GestureDetector(
                    onTap: _refreshing ? null : _refreshDefinition,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_refreshing)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.2,
                              color: AppColors.accent,
                            ),
                          )
                        else
                          const Icon(
                            Icons.refresh,
                            size: 12,
                            color: AppColors.accent,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _refreshing ? 'LOOKING UP' : 'REFRESH',
                          style: AppTypography.chip.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
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

/// One part-of-speech section inside an expanded vocab card.
class _PosBlock extends StatelessWidget {
  final String pos;
  final List<String> defs;
  const _PosBlock({required this.pos, required this.defs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pos.toUpperCase(),
            style: AppTypography.chip.copyWith(
              color: AppColors.accent,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...defs
            .take(4)
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 4),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Horizontal wrap of small word-chips for synonyms / antonyms.
class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  const _ChipRow({
    required this.label,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: AppTypography.chip.copyWith(color: color, fontSize: 9),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items.map((w) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  w,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _ReadingTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ReadingTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelect(tab),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                tab,
                style: AppTypography.label.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label, style: AppTypography.chip.copyWith(color: color)),
    );
  }
}
