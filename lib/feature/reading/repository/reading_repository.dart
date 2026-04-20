// lib/features/reading/repository/reading_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/book_model.dart';
import '../model/highlight_model.dart';
import '../model/knowledge_note_model.dart';
import '../model/vocabulary_word_model.dart';

class ReadingRepository {
  static const String _booksKey = 'reading_books';
  static const String _highlightsKey = 'reading_highlights';
  static const String _notesKey = 'reading_knowledge_notes';

  // ── Books ─────────────────────────────────────────────────────────────────

  Future<void> saveBook(BookModel book) async {
    final box = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> existing =
        List.from(box.get(_booksKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == book.id);
    if (index >= 0) {
      existing[index] = book.toMap();
    } else {
      existing.add(book.toMap());
    }
    await box.put(_booksKey, existing);
  }

  Future<void> deleteBook(String id) async {
    final box = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> existing =
        List.from(box.get(_booksKey, defaultValue: []) as List);
    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_booksKey, existing);
  }

  List<BookModel> loadAllBooks() {
    final box = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> raw =
        List.from(box.get(_booksKey, defaultValue: []) as List);
    return raw
        .map((e) =>
            BookModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<BookModel> loadCurrentlyReading() {
    return loadAllBooks()
        .where((b) => b.status == BookStatus.reading)
        .toList();
  }

  List<BookModel> loadCompleted() {
    return loadAllBooks()
        .where((b) => b.status == BookStatus.completed)
        .toList();
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  Future<void> saveHighlight(HighlightModel highlight) async {
    final box = HiveService.box(HiveBoxes.highlights);
    final List<dynamic> existing =
        List.from(box.get(_highlightsKey, defaultValue: []) as List);
    final index = existing
        .indexWhere((e) => (e as Map)['id'] == highlight.id);
    if (index >= 0) {
      existing[index] = highlight.toMap();
    } else {
      existing.add(highlight.toMap());
    }
    if (existing.length > 500) existing.removeAt(0);
    await box.put(_highlightsKey, existing);
  }

  List<HighlightModel> loadAllHighlights() {
    final box = HiveService.box(HiveBoxes.highlights);
    final List<dynamic> raw =
        List.from(box.get(_highlightsKey, defaultValue: []) as List);
    return raw
        .map((e) => HighlightModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<HighlightModel> loadHighlightsForBook(String bookId) {
    return loadAllHighlights()
        .where((h) => h.bookId == bookId)
        .toList();
  }

  List<HighlightModel> loadUnreviewed() {
    return loadAllHighlights()
        .where((h) => !h.reviewed)
        .toList();
  }

  // ── Knowledge Notes ───────────────────────────────────────────────────────

  Future<void> saveKnowledgeNote(KnowledgeNoteModel note) async {
    final box = HiveService.box(HiveBoxes.knowledgeVault);
    final List<dynamic> existing =
        List.from(box.get(_notesKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == note.id);
    if (index >= 0) {
      existing[index] = note.toMap();
    } else {
      existing.add(note.toMap());
    }
    if (existing.length > 300) existing.removeAt(0);
    await box.put(_notesKey, existing);
  }

  Future<void> deleteKnowledgeNote(String id) async {
    final box = HiveService.box(HiveBoxes.knowledgeVault);
    final List<dynamic> existing =
        List.from(box.get(_notesKey, defaultValue: []) as List);
    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_notesKey, existing);
  }

  List<KnowledgeNoteModel> loadAllNotes() {
    final box = HiveService.box(HiveBoxes.knowledgeVault);
    final List<dynamic> raw =
        List.from(box.get(_notesKey, defaultValue: []) as List);
    return raw
        .map((e) => KnowledgeNoteModel.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  List<KnowledgeNoteModel> loadPinnedNotes() {
    return loadAllNotes().where((n) => n.pinned).toList();
  }

  // ── Vocabulary ────────────────────────────────────────────────────────────

  static const String _vocabKey = 'reading_vocabulary';

  Future<void> saveVocabWord(VocabularyWord word) async {
    final box  = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> all =
        List.from(box.get(_vocabKey, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == word.id);
    if (idx >= 0) {
      all[idx] = word.toMap();
    } else {
      all.insert(0, word.toMap());
    }
    if (all.length > 1000) all.removeLast();
    await box.put(_vocabKey, all);
  }

  Future<void> deleteVocabWord(String id) async {
    final box  = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> all =
        List.from(box.get(_vocabKey, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_vocabKey, all);
  }

  List<VocabularyWord> loadAllVocab() {
    final box = HiveService.box(HiveBoxes.readingProgress);
    final List<dynamic> all =
        List.from(box.get(_vocabKey, defaultValue: []) as List);
    return all
        .map((e) => VocabularyWord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
