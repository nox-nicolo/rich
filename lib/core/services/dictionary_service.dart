// lib/core/services/dictionary_service.dart
//
// Thin wrapper around the free dictionaryapi.dev service (no key, no quota).
// Used by the reading feature to auto-fill vocab definitions when the user
// highlights a word in a PDF.
//
// This is BEST-EFFORT only — it must never throw. A failed lookup returns
// null and the caller falls back to a placeholder definition.
//
// The entry returned here captures EVERY interesting field the API exposes
// so the VOCAB tab can render a rich, expandable "mini-dictionary" card
// without having to hit the network again:
//   - phonetic transcription
//   - definitions grouped by part of speech (noun, verb, adjective...)
//   - every example sentence the API returned
//   - synonyms and antonyms (merged across all POS)

import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryEntry {
  final String word;
  final String? phonetic;

  /// Definitions grouped by part of speech:
  ///   { 'noun': ['a representative form', ...],
  ///     'verb': ['be illustrative of', ...] }
  /// The API returns the same word under multiple parts of speech, which is
  /// the closest thing to "different forms" available without a real
  /// morphology database — nouns, verbs, adjectives, adverbs, etc.
  final Map<String, List<String>> meaningsByPos;

  /// First example sentence found — kept for the compact card summary.
  final String? exampleSentence;

  /// Every example sentence returned by the API, across all POS.
  final List<String> examples;

  /// Merged synonyms / antonyms across every POS. Deduped.
  final List<String> synonyms;
  final List<String> antonyms;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    required this.meaningsByPos,
    this.exampleSentence,
    this.examples = const [],
    this.synonyms = const [],
    this.antonyms = const [],
  });

  /// Multi-line text suitable for the vocab tab summary. One line per part
  /// of speech, first definition only — otherwise the card gets cluttered.
  String get formattedMeaning {
    final buf = StringBuffer();
    meaningsByPos.forEach((pos, defs) {
      if (defs.isEmpty) return;
      buf.writeln('${pos.toUpperCase()}: ${defs.first}');
    });
    return buf.toString().trim();
  }

  /// Shortest possible one-liner — used as the collapsed summary on the
  /// vocab card when the full formatted meaning would be too tall.
  String get primaryMeaning {
    for (final entry in meaningsByPos.entries) {
      if (entry.value.isNotEmpty) return entry.value.first;
    }
    return '';
  }
}

class DictionaryService {
  DictionaryService._();
  static final DictionaryService instance = DictionaryService._();

  static const String _baseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en/';

  /// Look up a single English word. Returns null on any failure
  /// (no network, 404, parse error, multi-word input).
  Future<DictionaryEntry?> lookup(String word) async {
    final cleaned = word.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    // API only handles single words — skip phrases.
    if (cleaned.contains(RegExp(r'\s'))) return null;

    try {
      final uri = Uri.parse('$_baseUrl${Uri.encodeComponent(cleaned)}');
      final resp =
          await http.get(uri).timeout(const Duration(seconds: 8));
          
      if (resp.statusCode != 200) return null;
      
      final decoded = jsonDecode(resp.body);
      if (decoded is! List || decoded.isEmpty) return null;

      // The API may return multiple top-level entries for the same word
      // (different etymologies). Merge them all — we lose the distinction
      // but gain richness.
      final meanings = <String, List<String>>{};
      final examples = <String>[];
      final synonyms = <String>{};
      final antonyms = <String>{};
      String? phonetic;
      String? canonicalWord;

      for (final raw in decoded) {
        if (raw is! Map) continue;
        final first = Map<String, dynamic>.from(raw);
        canonicalWord ??= first['word'] as String?;

        // Prefer a top-level phonetic; fall back to the first non-empty
        // entry in the phonetics[] array.
        phonetic ??= first['phonetic'] as String?;
        if (phonetic == null || phonetic.isEmpty) {
          final phonetics = first['phonetics'] as List? ?? const [];
          for (final p in phonetics) {
            if (p is Map) {
              final t = p['text'] as String?;
              if (t != null && t.isNotEmpty) {
                phonetic = t;
                break;
              }
            }
          }
        }

        for (final m in (first['meanings'] as List? ?? const [])) {
          if (m is! Map) continue;
          final pos = (m['partOfSpeech'] as String? ?? '').trim();
          if (pos.isEmpty) continue;

          // POS-level synonyms/antonyms.
          for (final s in (m['synonyms'] as List? ?? const [])) {
            if (s is String && s.isNotEmpty) synonyms.add(s);
          }
          for (final a in (m['antonyms'] as List? ?? const [])) {
            if (a is String && a.isNotEmpty) antonyms.add(a);
          }

          final defs = <String>[];
          for (final d in (m['definitions'] as List? ?? const [])) {
            if (d is! Map) continue;
            final def = (d['definition'] as String?)?.trim();
            if (def != null && def.isNotEmpty) defs.add(def);
            final ex = (d['example'] as String?)?.trim();
            if (ex != null && ex.isNotEmpty) examples.add(ex);
            // Definition-level synonyms/antonyms too.
            for (final s in (d['synonyms'] as List? ?? const [])) {
              if (s is String && s.isNotEmpty) synonyms.add(s);
            }
            for (final a in (d['antonyms'] as List? ?? const [])) {
              if (a is String && a.isNotEmpty) antonyms.add(a);
            }
          }

          if (defs.isNotEmpty) {
            meanings.update(pos, (existing) => [...existing, ...defs],
                ifAbsent: () => defs);
          }
        }
      }

      if (meanings.isEmpty) return null;

      return DictionaryEntry(
        word: canonicalWord ?? cleaned,
        phonetic: phonetic,
        meaningsByPos: meanings,
        exampleSentence: examples.isNotEmpty ? examples.first : null,
        examples: examples,
        synonyms: synonyms.toList(),
        antonyms: antonyms.toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
