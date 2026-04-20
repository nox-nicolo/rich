// lib/feature/reading/view/pdf_reader_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/book_model.dart';
import '../model/highlight_model.dart';
import '../viewmodel/reading_viewmodel.dart';

// Kindle-ish warm paper background for day mode; near-black for night.
const Color _sepia   = Color(0xFFF4ECD8);
const Color _nightBg = Color(0xFF0B0B0B);

/// Invert color matrix for night-mode PDFs — flips RGB, keeps alpha.
/// This gives a "dark Kindle" look without needing a PDF-native dark theme.
const List<double> _nightInvertMatrix = <double>[
  -1,  0,  0, 0, 255,
   0, -1,  0, 0, 255,
   0,  0, -1, 0, 255,
   0,  0,  0, 1,   0,
];

// ── Highlight colours per annotation type ─────────────────────────────────────
//
// These are painted directly into the PDF (via [HighlightAnnotation]) AND
// used as the selection-overlay color so the user can see the text they're
// about to mark. They're all soft pastels: strong enough to read through
// them, light enough that they don't obscure the letters underneath.
const Color _highlightNoted = Color(0xFFFFE57A); // warm yellow
const Color _highlightVocab = Color(0xFF80C0FF); // sky blue
const Color _highlightIdea  = Color(0xFF9EE493); // mint green

Color _colorFor(HighlightType t) {
  switch (t) {
    case HighlightType.noted: return _highlightNoted;
    case HighlightType.vocab: return _highlightVocab;
    case HighlightType.idea:  return _highlightIdea;
  }
}

class PdfReaderScreen extends ConsumerStatefulWidget {
  final BookModel book;
  const PdfReaderScreen({required this.book, super.key});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  // GlobalKey into SfPdfViewerState — needed because getSelectedTextLines()
  // lives on the State, not the controller.
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey<SfPdfViewerState>();
  bool    _showControls = true;
  int     _currentPage  = 1;
  int     _totalPages   = 0;
  bool    _nightMode    = false;
  String? _selectedText;

  /// Set to true once we add at least one annotation in this session so we
  /// know we need to flush the PDF bytes back to disk on exit. If no
  /// annotations were added we skip the save to avoid rewriting the file.
  bool _annotationsDirty = false;

  @override
  void initState() {
    super.initState();
    // Resume from the last saved page. If the book was just added this will
    // be 0 and the viewer opens at page 1 — that's fine.
    _currentPage = widget.book.currentPage > 0 ? widget.book.currentPage : 1;

    // Kindle-like full-screen reading — hide status + nav bars.
    // They reappear briefly on an edge-swipe and auto-hide again.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore normal system UI when leaving the reader.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _savePage(int page) {
    ref.read(readingViewModelProvider.notifier)
        .updateProgress(widget.book.id, page);
  }

  /// Flush any newly-added highlight annotations back to the PDF file on
  /// disk. Best-effort — if syncfusion's save path fails we just log and
  /// keep going so the user isn't blocked from exiting the reader.
  Future<void> _persistAnnotations() async {
    if (!_annotationsDirty) return;
    final filePath = widget.book.filePath;
    if (filePath == null) return;
    try {
      final bytes = await _controller.saveDocument();
      await File(filePath).writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Swallow — we don't want a save failure to block Navigator.pop.
    }
  }

  /// Gated exit — persist annotations first, then pop. Used both by the
  /// back button and by [PopScope.onPopInvokedWithResult].
  Future<void> _exitReader() async {
    await _persistAnnotations();
    if (mounted) Navigator.of(context).pop();
  }

  void _markComplete() async {
    await ref.read(readingViewModelProvider.notifier)
        .markCompleted(widget.book.id);
    if (mounted) await _exitReader();
  }

  /// Save the currently-selected PDF text as a highlight of the chosen type.
  /// Vocab triggers the dictionary lookup inside the viewmodel; all types
  /// also paint an in-PDF HighlightAnnotation in the type's colour so the
  /// mark is visible on subsequent opens.
  Future<void> _saveSelection(HighlightType type, String bookTitle) async {
    final text = _selectedText?.trim();
    if (text == null || text.isEmpty) return;

    // Paint the in-PDF highlight BEFORE we clear the selection — once
    // cleared, getSelectedTextLines() returns nothing.
    _applyPdfHighlight(type);

    setState(() => _selectedText = null);
    try {
      _controller.clearSelection();
    } catch (_) {
      // Older syncfusion versions don't expose clearSelection — no-op.
    }

    await ref.read(readingViewModelProvider.notifier).addHighlight(
          bookId:     widget.book.id,
          bookTitle:  bookTitle,
          content:    text,
          type:       type,
          pageNumber: _currentPage,
        );

    if (!mounted) return;
    final msg = switch (type) {
      HighlightType.noted => 'Saved to Highlights',
      HighlightType.vocab => 'Added to Vocabulary — looking up definition…',
      HighlightType.idea  => 'Saved to Vault',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.caption),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Paint a HighlightAnnotation over the current selection in the PDF
  /// itself. Syncfusion handles the page-relative rects; we just pass in
  /// the text lines and a colour. Wrapped in try/catch because annotation
  /// APIs vary between syncfusion versions.
  void _applyPdfHighlight(HighlightType type) {
    try {
      final state = _viewerKey.currentState;
      if (state == null) return;
      final lines = state.getSelectedTextLines();
      if (lines.isEmpty) return;
      final annotation = HighlightAnnotation(textBoundsCollection: lines);
      annotation.color = _colorFor(type);
      _controller.addAnnotation(annotation);
      _annotationsDirty = true;
    } catch (_) {
      // Annotation API not available on this syncfusion version — we still
      // save the highlight to Hive so nothing is lost, the mark just won't
      // appear as a visual highlight inside the PDF.
    }
  }

  void _showEditGoalSheet(BookModel book) {
    final ctrl = TextEditingController(text: '${book.dailyPageGoal}');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('DAILY PAGE GOAL', style: AppTypography.label),
            const SizedBox(height: 4),
            Text('Minimum pages to read per day for this book.',
                style: AppTypography.caption),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'e.g. 20'),
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
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final goal = int.tryParse(ctrl.text.trim());
                  if (goal == null || goal < 1) return;
                  Navigator.pop(ctx);
                  await ref.read(readingViewModelProvider.notifier)
                      .setDailyGoal(widget.book.id, goal);
                },
                child: Text('SAVE GOAL',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.background, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live book so daily progress / goal updates reflect immediately.
    final book = ref.watch(readingViewModelProvider.select((s) =>
        s.allBooks.firstWhere((b) => b.id == widget.book.id,
            orElse: () => widget.book)));
    final filePath = book.filePath;

    if (filePath == null || !File(filePath).existsSync()) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: AppSpacing.iconSm, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('PDF file not found', style: AppTypography.body),
              const SizedBox(height: 8),
              Text(filePath ?? 'No path saved',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Warm "paper" bg during the day, deep black at night. The PDF itself
    // is rendered on top by syncfusion — in night mode we invert the whole
    // viewer with a color matrix so pages read as white-on-black.
    final bg = _nightMode ? _nightBg : _sepia;

    // The raw viewer widget, unstyled. Wrapped in a Theme below so the
    // text-selection overlay uses a visible contrasting colour (the default
    // inherits from the app theme, which in this app is white-on-dark, so
    // the selection ends up invisible on a PDF page).
    final viewer = SfPdfViewer.file(
      File(filePath),
      key: _viewerKey,
      controller: _controller,
      initialScrollOffset: Offset(0, 0),
      initialPageNumber: _currentPage,
      // We render our own selection action bar below; disable the default.
      canShowTextSelectionMenu: false,
      onTextSelectionChanged: (details) {
        final text = details.selectedText?.trim() ?? '';
        if (text.isEmpty) {
          if (_selectedText != null) {
            setState(() => _selectedText = null);
          }
          return;
        }
        if (text != _selectedText) {
          setState(() => _selectedText = text);
        }
      },
      onPageChanged: (details) {
        setState(() => _currentPage = details.newPageNumber);
        _savePage(details.newPageNumber);
      },
      onDocumentLoaded: (details) {
        final count = details.document.pages.count;
        setState(() => _totalPages = count);
        // Persist the real page count the first time the PDF opens —
        // needed so updateProgress() can clamp correctly and
        // progress% works on the shelf.
        if (book.totalPages != count) {
          ref.read(readingViewModelProvider.notifier)
              .setTotalPages(widget.book.id, count);
        }
      },
    );

    // Override the text-selection theme so the selection rectangle is
    // visibly tinted yellow on top of the PDF page. Without this override
    // we inherit the app's dark-theme selection color which on a bright
    // PDF page appears as near-white on white — totally invisible.
    final themedViewer = Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: _highlightNoted.withValues(alpha: 0.55),
          selectionHandleColor: const Color(0xFFFFB800),
          cursorColor: const Color(0xFFFFB800),
        ),
      ),
      child: viewer,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _exitReader();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // ── PDF Viewer (optionally inverted for night mode) ──────────
              Positioned.fill(
                child: _nightMode
                    ? ColorFiltered(
                        colorFilter:
                            const ColorFilter.matrix(_nightInvertMatrix),
                        child: themedViewer,
                      )
                    : themedViewer,
              ),

              // ── Top bar ──────────────────────────────────────────────────
              if (_showControls)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12, right: 12, bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                          onPressed: _exitReader,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title,
                                  style: AppTypography.h3.copyWith(
                                      color: Colors.white, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('Page $_currentPage${_totalPages > 0 ? ' of $_totalPages' : ''}',
                                  style: AppTypography.caption
                                      .copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _nightMode
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _nightMode = !_nightMode),
                          tooltip: _nightMode ? 'Day mode' : 'Night mode',
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune,
                              color: Colors.white, size: 20),
                          onPressed: () => _showEditGoalSheet(book),
                          tooltip: 'Daily page goal',
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Bottom bar ──────────────────────────────────────────────
              // Hidden while the user has an active selection — the action
              // bar takes over that space.
              if (_showControls && _selectedText == null)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      left: 16, right: 16, top: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Daily page goal progress bar
                        Row(
                          children: [
                            Text(
                              'TODAY  ${book.pagesReadToday} / ${book.dailyPageGoal} pages',
                              style: AppTypography.chip.copyWith(
                                color: book.dailyGoalMet
                                    ? AppColors.success
                                    : Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (book.dailyGoalMet)
                              const Icon(Icons.check_circle,
                                  size: 12, color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: book.dailyPageGoal > 0
                                ? (book.pagesReadToday / book.dailyPageGoal)
                                    .clamp(0.0, 1.0)
                                : 0,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(
                              book.dailyGoalMet
                                  ? AppColors.success
                                  : AppColors.accent,
                            ),
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_totalPages > 0)
                              Text(
                                '${(_currentPage / _totalPages * 100).toStringAsFixed(0)}% complete',
                                style: AppTypography.caption
                                    .copyWith(color: Colors.white70),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: _markComplete,
                              child: Text('MARK FINISHED',
                                  style: AppTypography.label.copyWith(
                                      color: AppColors.success, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Text-selection action bar ───────────────────────────────
              // Overrides the bottom bar when text is selected. Tap a button
              // to categorise the highlight; the bar disappears after saving.
              if (_selectedText != null && _selectedText!.isNotEmpty)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _SelectionActionBar(
                    text: _selectedText!,
                    onSave: (type) => _saveSelection(type, book.title),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Text-selection action bar ─────────────────────────────────────────────────
//
// Sits at the bottom of the screen whenever there is an active PDF text
// selection. Shows a one-line preview of the selected text and three
// categorise-and-save buttons. Replaces the old manual-typing flow entirely.

class _SelectionActionBar extends StatelessWidget {
  final String text;
  final Future<void> Function(HighlightType type) onSave;
  const _SelectionActionBar({required this.text, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECTED',
                style: AppTypography.chip
                    .copyWith(color: AppColors.textMuted, fontSize: 9)),
            const SizedBox(height: 4),
            Text(
              text,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textPrimary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _SelectionBtn(
                  label: 'HIGHLIGHT',
                  icon:  Icons.bookmark_outline,
                  color: const Color(0xFFE5B800),
                  onTap: () => onSave(HighlightType.noted),
                ),
                const SizedBox(width: 8),
                _SelectionBtn(
                  label: 'VOCAB',
                  icon:  Icons.spellcheck,
                  color: const Color(0xFF4A9EFF),
                  onTap: () => onSave(HighlightType.vocab),
                ),
                const SizedBox(width: 8),
                _SelectionBtn(
                  label: 'IDEA',
                  icon:  Icons.lightbulb_outline,
                  color: AppColors.success,
                  onTap: () => onSave(HighlightType.idea),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SelectionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
