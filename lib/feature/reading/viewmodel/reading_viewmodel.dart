// lib/features/reading/viewmodel/reading_viewmodel.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';
import '../model/book_model.dart';
import '../model/highlight_model.dart';
import '../model/knowledge_note_model.dart';
import '../model/vocabulary_word_model.dart';
import '../repository/reading_repository.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../../core/services/dictionary_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

class ReadingState {
  final List<BookModel> allBooks;
  final List<HighlightModel> allHighlights;
  final List<KnowledgeNoteModel> allNotes;
  final List<VocabularyWord> vocabulary;
  final String activeTab;
  final String? selectedBookId;
  final bool isLoading;

  const ReadingState({
    required this.allBooks,
    required this.allHighlights,
    required this.allNotes,
    required this.vocabulary,
    required this.activeTab,
    this.selectedBookId,
    required this.isLoading,
  });

  factory ReadingState.initial() {
    return const ReadingState(
      allBooks:     [],
      allHighlights: [],
      allNotes:     [],
      vocabulary:   [],
      activeTab:    'BOOKS',
      isLoading:    true,
    );
  }

  ReadingState copyWith({
    List<BookModel>? allBooks,
    List<HighlightModel>? allHighlights,
    List<KnowledgeNoteModel>? allNotes,
    List<VocabularyWord>? vocabulary,
    String? activeTab,
    String? selectedBookId,
    bool? isLoading,
  }) {
    return ReadingState(
      allBooks:      allBooks      ?? this.allBooks,
      allHighlights: allHighlights ?? this.allHighlights,
      allNotes:      allNotes      ?? this.allNotes,
      vocabulary:    vocabulary    ?? this.vocabulary,
      activeTab:     activeTab     ?? this.activeTab,
      selectedBookId: selectedBookId ?? this.selectedBookId,
      isLoading:     isLoading     ?? this.isLoading,
    );
  }

  List<BookModel> get currentlyReading =>
      allBooks.where((b) => b.status == BookStatus.reading).toList();

  List<BookModel> get completedBooks =>
      allBooks.where((b) => b.status == BookStatus.completed).toList();

  List<HighlightModel> get unreviewedHighlights =>
      allHighlights.where((h) => !h.reviewed).toList();

  List<KnowledgeNoteModel> get pinnedNotes =>
      allNotes.where((n) => n.pinned).toList();

  /// Real pages read today across all currently-reading books.
  int get totalPagesReadToday {
    return allBooks
        .where((b) => b.readTodayAlready && b.isCurrentlyReading)
        .fold(0, (sum, b) => sum + b.pagesReadToday);
  }

  BookModel? get activeBook =>
      selectedBookId != null
          ? allBooks.firstWhere(
              (b) => b.id == selectedBookId,
              orElse: () => currentlyReading.isNotEmpty
                  ? currentlyReading.first
                  : allBooks.first,
            )
          : currentlyReading.isNotEmpty
              ? currentlyReading.first
              : null;
}

class ReadingViewModel extends StateNotifier<ReadingState> {
  final ReadingRepository _repo;

  ReadingViewModel(this._repo) : super(ReadingState.initial()) {
    _load();
  }

  void _load() {
    final books      = _repo.loadAllBooks()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final highlights = _repo.loadAllHighlights();
    final notes      = _repo.loadAllNotes();
    final vocab      = _repo.loadAllVocab();

    state = state.copyWith(
      allBooks:      books,
      allHighlights: highlights,
      allNotes:      notes,
      vocabulary:    vocab,
      isLoading:     false,
    );

    // Lazily generate missing PDF covers in the background so the shelf
    // starts showing thumbnails on subsequent frames without blocking load.
    for (final b in books) {
      if (b.filePath != null &&
          (b.coverPath == null || !File(b.coverPath!).existsSync())) {
        _ensureCover(b);
      }
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  void selectBook(String id) =>
      state = state.copyWith(selectedBookId: id);

  // ── Books ─────────────────────────────────────────────────────────────────

  Future<void> addBook({
    required String title,
    required String author,
    required BookCategory category,
    String? filePath,
    int totalPages = 0,
    int dailyPageGoal = 20,
  }) async {
    // New books go on wishlist if there's already an active book
    final hasActive = state.currentlyReading.isNotEmpty;
    final book = BookModel(
      id:           const Uuid().v4(),
      title:        title,
      author:       author,
      status:       hasActive ? BookStatus.wishlist : BookStatus.reading,
      category:     category,
      totalPages:   totalPages,
      currentPage:  0,
      startedAt:    DateTime.now(),
      lastReadAt:   DateTime.now(),
      dailyPageGoal: dailyPageGoal,
      filePath:     filePath,
      sortOrder:    DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.saveBook(book);
    state = state.copyWith(allBooks: [...state.allBooks, book]);
    if (book.filePath != null) _ensureCover(book);
  }

  /// Rearrange books within a section (same BookStatus). Rewrites every
  /// book's `sortOrder` so the global ordering reflects the new position.
  Future<void> reorderBooks(
      BookStatus section, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final all = [...state.allBooks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final sectionIndices = <int>[];
    for (var i = 0; i < all.length; i++) {
      if (all[i].status == section) sectionIndices.add(i);
    }
    if (oldIndex < 0 ||
        oldIndex >= sectionIndices.length ||
        newIndex < 0 ||
        newIndex >= sectionIndices.length) {
      return;
    }
    final sectionBooks =
        sectionIndices.map((i) => all[i]).toList();
    final moved = sectionBooks.removeAt(oldIndex);
    sectionBooks.insert(newIndex, moved);
    for (var i = 0; i < sectionIndices.length; i++) {
      all[sectionIndices[i]] = sectionBooks[i];
    }
    final updated = <BookModel>[];
    for (var i = 0; i < all.length; i++) {
      final b = all[i].copyWith(sortOrder: i);
      updated.add(b);
      await _repo.saveBook(b);
    }
    state = state.copyWith(allBooks: updated);
  }

  /// Generate a PNG thumbnail of the PDF's first page into
  /// `{appDocs}/covers/{bookId}.png` and persist the path on the book.
  /// Best-effort — silently swallows errors so a broken PDF doesn't
  /// derail shelf loading.
  Future<void> _ensureCover(BookModel book) async {
    if (book.filePath == null) return;
    if (book.coverPath != null && File(book.coverPath!).existsSync()) return;
    try {
      final doc = await PdfDocument.openFile(book.filePath!);
      final page = await doc.getPage(1);
      final img = await page.render(
        width: page.width * 1.5,
        height: page.height * 1.5,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await doc.close();
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/covers');
      if (!await coverDir.exists()) await coverDir.create(recursive: true);
      final file = File('${coverDir.path}/${book.id}.png');
      await file.writeAsBytes(img.bytes);
      final updated = book.copyWith(coverPath: file.path);
      await _repo.saveBook(updated);
      if (!mounted) return;
      state = state.copyWith(
        allBooks: state.allBooks
            .map((b) => b.id == book.id ? updated : b)
            .toList(),
      );
    } catch (_) {
      // Broken PDF / permission issue — leave coverPath null so the
      // shelf falls back to the icon placeholder.
    }
  }

  /// Try to start reading a book. Returns false if locked (prev book not done).
  Future<bool> startReading(String id) async {
    final book = state.allBooks.firstWhere((b) => b.id == id);
    // Allow if already reading, or no other book is currently being read
    final otherActive = state.currentlyReading.any((b) => b.id != id);
    if (otherActive) return false;

    if (book.status == BookStatus.wishlist ||
        book.status == BookStatus.paused) {
      final updated = book.copyWith(
          status: BookStatus.reading, lastReadAt: DateTime.now());
      await _repo.saveBook(updated);
      state = state.copyWith(
        allBooks: state.allBooks.map((b) => b.id == id ? updated : b).toList(),
        selectedBookId: id,
      );
    } else {
      state = state.copyWith(selectedBookId: id);
    }
    return true;
  }

  Future<void> markCompleted(String id) async {
    final updated = state.allBooks.map((b) {
      if (b.id != id) return b;
      return b.copyWith(
        status:      BookStatus.completed,
        completedAt: DateTime.now(),
        currentPage: b.totalPages > 0 ? b.totalPages : b.currentPage,
      );
    }).toList();
    final book = updated.firstWhere((b) => b.id == id);
    await _repo.saveBook(book);
    state = state.copyWith(allBooks: updated);
    VibrationService.strongPulse();
  }

  /// Save the reader's current page + update daily counter.
  ///
  /// `totalPages` is captured lazily from the PDF (see [setTotalPages]) —
  /// until it's known we accept any `newPage` without clamping, otherwise
  /// `clamp(0, 0)` would silently reset currentPage to 0 on every page flip
  /// and auto-resume would never work.
  Future<void> updateProgress(String id, int newPage) async {
    final updated = state.allBooks.map((b) {
      if (b.id != id) return b;

      // Clamp only when we actually know the page count.
      final safePage = b.totalPages > 0
          ? newPage.clamp(0, b.totalPages)
          : (newPage < 0 ? 0 : newPage);

      // Count forward progress toward the daily goal.
      // If this is the first update of a new day, the counter resets.
      final isNewDay = !b.readTodayAlready;
      final forward  = safePage > b.currentPage ? safePage - b.currentPage : 0;
      final newPagesReadToday =
          isNewDay ? forward : b.pagesReadToday + forward;

      final isComplete = b.totalPages > 0 && safePage >= b.totalPages;

      return b.copyWith(
        currentPage:    safePage,
        lastReadAt:     DateTime.now(),
        pagesReadToday: newPagesReadToday,
        status:         isComplete ? BookStatus.completed : b.status,
        completedAt:    isComplete ? DateTime.now() : b.completedAt,
      );
    }).toList();
    final book = updated.firstWhere((b) => b.id == id);
    final prior = state.allBooks.firstWhere((b) => b.id == id);
    final pagesDelta =
        book.currentPage > prior.currentPage ? book.currentPage - prior.currentPage : 0;
    final justCompleted = book.status == BookStatus.completed &&
        prior.status != BookStatus.completed;
    await _repo.saveBook(book);
    state = state.copyWith(allBooks: updated);

    if (pagesDelta > 0 || justCompleted) {
      await TrackingService.record(TrackingFeature.reading, {
        'pages':          pagesDelta,
        'booksCompleted': justCompleted ? 1 : 0,
      });
    }

    // Auto-mark Reading routine item
    final dashRepo = DashboardRepository();
    final progress = dashRepo.loadRoutineProgress();
    if (progress['Reading'] == false) {
      progress['Reading'] = true;
      await dashRepo.saveRoutineProgress(progress);
    }
  }

  /// Called by the PDF reader the first time a document loads so the real
  /// page count is persisted. Without this, [updateProgress]'s clamp keeps
  /// `currentPage` stuck at 0 and resume never works.
  Future<void> setTotalPages(String id, int totalPages) async {
    if (totalPages <= 0) return;
    final updated = state.allBooks.map((b) {
      if (b.id != id) return b;
      if (b.totalPages == totalPages) return b;
      return b.copyWith(totalPages: totalPages);
    }).toList();
    final book = updated.firstWhere((b) => b.id == id);
    await _repo.saveBook(book);
    state = state.copyWith(allBooks: updated);
  }

  /// Change the minimum pages-per-day target for a book.
  Future<void> setDailyGoal(String id, int goal) async {
    if (goal < 1) return;
    final updated = state.allBooks.map((b) {
      if (b.id != id) return b;
      return b.copyWith(dailyPageGoal: goal);
    }).toList();
    final book = updated.firstWhere((b) => b.id == id);
    await _repo.saveBook(book);
    state = state.copyWith(allBooks: updated);
  }

  Future<void> deleteBook(String id) async {
    await _repo.deleteBook(id);
    state = state.copyWith(
      allBooks: state.allBooks.where((b) => b.id != id).toList(),
    );
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  Future<void> addHighlight({
    required String bookId,
    required String bookTitle,
    required String content,
    required HighlightType type,
    int? pageNumber,
    String? personalNote,
  }) async {
    final highlight = HighlightModel(
      id:           const Uuid().v4(),
      bookId:       bookId,
      bookTitle:    bookTitle,
      content:      content,
      type:         type,
      pageNumber:   pageNumber,
      savedAt:      DateTime.now(),
      personalNote: personalNote,
    );
    await _repo.saveHighlight(highlight);
    state = state.copyWith(
      allHighlights: [...state.allHighlights, highlight],
    );

    await TrackingService.record(TrackingFeature.reading, {
      'highlights': 1,
    });

    // Auto-side-effects based on annotation type
    if (type == HighlightType.vocab) {
      // Pull the first real word out of the selection and strip punctuation.
      // If the user highlighted a phrase we still only lookup the first word
      // because dictionaryapi.dev doesn't handle multi-word entries.
      final tokens = content.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty);
      if (tokens.isEmpty) return; 
      final firstToken = tokens.first;
      
      final word = firstToken.replaceAll(RegExp(r"[^\w'-]"), '');
      if (word.isNotEmpty) {
        // Best-effort dictionary lookup. Never throws — falls back to a
        // placeholder record that can be refreshed later.
        final dict = await DictionaryService.instance.lookup(word);

        final String summary;
        if (dict != null && dict.primaryMeaning.isNotEmpty) {
          summary = dict.primaryMeaning;
        } else {
          summary = '(no definition found — tap to edit or refresh)';
        }

        final entry = VocabularyWord(
          id:              const Uuid().v4(),
          word:            word,
          meaning:         summary,
          phonetic:        dict?.phonetic,
          meaningsByPos:   dict?.meaningsByPos ?? const {},
          exampleSentence: dict?.exampleSentence,
          examples:        dict?.examples ?? const [],
          synonyms:        dict?.synonyms ?? const [],
          antonyms:        dict?.antonyms ?? const [],
          personalNote:    personalNote,
          sourceBookTitle: bookTitle,
          sourceBookId:    bookId,
          sourcePage:      pageNumber,
          savedAt:         DateTime.now(),
        );
        await _repo.saveVocabWord(entry);
        state = state.copyWith(vocabulary: [entry, ...state.vocabulary]);
      }
    } else if (type == HighlightType.idea) {
      // Auto-add to knowledge vault as a lesson note
      final note = KnowledgeNoteModel(
        id:        const Uuid().v4(),
        bookId:    bookId,
        bookTitle: bookTitle,
        content:   content,
        type:      KnowledgeNoteType.lesson,
        tags:      ['idea', 'reading'],
        createdAt: DateTime.now(),
      );
      await _repo.saveKnowledgeNote(note);
      state = state.copyWith(allNotes: [note, ...state.allNotes]);
    }
  }

  Future<void> markHighlightReviewed(String id) async {
    final updated = state.allHighlights.map((h) {
      if (h.id != id) return h;
      return h.copyWith(reviewed: true);
    }).toList();
    final highlight = updated.firstWhere((h) => h.id == id);
    await _repo.saveHighlight(highlight);
    state = state.copyWith(allHighlights: updated);
  }

  // ── Knowledge Notes ───────────────────────────────────────────────────────

  Future<void> addKnowledgeNote({
    String? bookId,
    String? bookTitle,
    required String content,
    required KnowledgeNoteType type,
    List<String> tags = const [],
  }) async {
    final note = KnowledgeNoteModel(
      id: const Uuid().v4(),
      bookId: bookId,
      bookTitle: bookTitle,
      content: content,
      type: type,
      tags: tags,
      createdAt: DateTime.now(),
    );
    await _repo.saveKnowledgeNote(note);
    state = state.copyWith(
      allNotes: [note, ...state.allNotes],
    );

    await TrackingService.record(TrackingFeature.reading, {
      'notes': 1,
    });
  }

  /// Save or update the user's personal reflection on a knowledge note.
  /// Empty / whitespace-only input clears the reflection (we construct the
  /// replacement directly because copyWith can't express "set this nullable
  /// field to null").
  Future<void> updateNoteReflection(String id, String reflection) async {
    final trimmed = reflection.trim();
    final updated = state.allNotes.map((n) {
      if (n.id != id) return n;
      return KnowledgeNoteModel(
        id: n.id,
        bookId: n.bookId,
        bookTitle: n.bookTitle,
        content: n.content,
        type: n.type,
        tags: n.tags,
        createdAt: n.createdAt,
        pinned: n.pinned,
        reflection: trimmed.isEmpty ? null : trimmed,
        reflectionUpdatedAt: trimmed.isEmpty ? null : DateTime.now(),
      );
    }).toList();
    final note = updated.firstWhere((n) => n.id == id);
    await _repo.saveKnowledgeNote(note);
    state = state.copyWith(allNotes: updated);
  }

  Future<void> togglePinNote(String id) async {
    final updated = state.allNotes.map((n) {
      if (n.id != id) return n;
      return n.copyWith(pinned: !n.pinned);
    }).toList();
    final note = updated.firstWhere((n) => n.id == id);
    await _repo.saveKnowledgeNote(note);
    state = state.copyWith(allNotes: updated);
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteKnowledgeNote(id);
    state = state.copyWith(
      allNotes: state.allNotes.where((n) => n.id != id).toList(),
    );
  }

  // ── Vocabulary ────────────────────────────────────────────────────────────

  Future<void> addVocabWord({
    required String word,
    required String meaning,
    String? exampleSentence,
    String? sourceBookTitle,
    String? sourceBookId,
    int? sourcePage,
  }) async {
    final entry = VocabularyWord(
      id:              const Uuid().v4(),
      word:            word.trim(),
      meaning:         meaning.trim(),
      exampleSentence: exampleSentence?.trim(),
      sourceBookTitle: sourceBookTitle,
      sourceBookId:    sourceBookId,
      sourcePage:      sourcePage,
      savedAt:         DateTime.now(),
    );
    await _repo.saveVocabWord(entry);
    state = state.copyWith(vocabulary: [entry, ...state.vocabulary]);

    await TrackingService.record(TrackingFeature.reading, {
      'vocab': 1,
    });
  }

  /// Re-fetch the dictionary entry for an existing vocab word. Useful when
  /// the first save happened offline or returned `(no definition found)` —
  /// the user can tap "refresh" on the card to try again.
  Future<bool> refreshVocabDefinition(String id) async {
    final existing = state.vocabulary.firstWhere(
      (w) => w.id == id,
      orElse: () => throw StateError('vocab word not found'),
    );
    final dict = await DictionaryService.instance.lookup(existing.word);
    if (dict == null || dict.meaningsByPos.isEmpty) return false;

    final refreshed = existing.copyWith(
      meaning: dict.primaryMeaning.isNotEmpty
          ? dict.primaryMeaning
          : existing.meaning,
      phonetic: dict.phonetic,
      meaningsByPos: dict.meaningsByPos,
      exampleSentence: dict.exampleSentence,
      examples: dict.examples,
      synonyms: dict.synonyms,
      antonyms: dict.antonyms,
    );
    await _repo.saveVocabWord(refreshed);
    state = state.copyWith(
      vocabulary:
          state.vocabulary.map((w) => w.id == id ? refreshed : w).toList(),
    );
    return true;
  }

  /// Save a personal note / mnemonic on a vocab word. Empty input clears it
  /// (built manually because copyWith cannot null-out a nullable field).
  Future<void> updateVocabPersonalNote(String id, String note) async {
    final trimmed = note.trim();
    final updated = state.vocabulary.map((w) {
      if (w.id != id) return w;
      return VocabularyWord(
        id: w.id,
        word: w.word,
        meaning: w.meaning,
        phonetic: w.phonetic,
        meaningsByPos: w.meaningsByPos,
        exampleSentence: w.exampleSentence,
        examples: w.examples,
        synonyms: w.synonyms,
        antonyms: w.antonyms,
        personalNote: trimmed.isEmpty ? null : trimmed,
        sourceBookTitle: w.sourceBookTitle,
        sourceBookId: w.sourceBookId,
        sourcePage: w.sourcePage,
        savedAt: w.savedAt,
        reviewCount: w.reviewCount,
      );
    }).toList();
    final word = updated.firstWhere((w) => w.id == id);
    await _repo.saveVocabWord(word);
    state = state.copyWith(vocabulary: updated);
  }

  Future<void> incrementVocabReview(String id) async {
    final updated = state.vocabulary.map((w) {
      if (w.id != id) return w;
      return w.copyWith(reviewCount: w.reviewCount + 1);
    }).toList();
    final word = updated.firstWhere((w) => w.id == id);
    await _repo.saveVocabWord(word);
    state = state.copyWith(vocabulary: updated);
  }

  Future<void> deleteVocabWord(String id) async {
    await _repo.deleteVocabWord(id);
    state = state.copyWith(
      vocabulary: state.vocabulary.where((w) => w.id != id).toList(),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final readingRepositoryProvider = Provider<ReadingRepository>(
  (_) => ReadingRepository(),
);

final readingViewModelProvider =
    StateNotifierProvider<ReadingViewModel, ReadingState>(
  (ref) => ReadingViewModel(ref.read(readingRepositoryProvider)),
);
