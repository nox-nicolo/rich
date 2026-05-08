// lib/core/services/ai_lesson_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

class AiLessonService {
  AiLessonService._();
  static final AiLessonService instance = AiLessonService._();

  static const String _apiKey = String.fromEnvironment('POLLINATIONS_API_KEY');
  static const String _legacyTextBaseUrl = 'https://text.pollinations.ai';
  static const String _unifiedBaseUrl = 'https://gen.pollinations.ai';

  static const List<_PollinationsTextRoute> _routes = [
    _PollinationsTextRoute(
      baseUrl: '$_unifiedBaseUrl/text',
      model: 'openai',
      label: 'Pollinations text/openai',
      requiresApiKey: true,
    ),
    _PollinationsTextRoute(
      baseUrl: _legacyTextBaseUrl,
      model: 'openai',
      label: 'Pollinations no-key/openai',
    ),
  ];

  String? lastError;

  // ── Generate a full language lesson ──────────────────────────────────────

  /// Returns a structured lesson string for [topicTitle] in [languageName].
  /// Returns null if the API call fails — caller falls back to offline content.
  Future<String?> generateLesson({
    required String languageName,
    required String topicTitle,
    required String topicDescription,
    required int currentProgressPercent,
  }) async {
    final prompt =
        '''
You are an expert language teacher. Teach a full, self-contained lesson for a student learning $languageName.

TOPIC: $topicTitle
DESCRIPTION: $topicDescription
STUDENT LEVEL: $currentProgressPercent% through the full curriculum

The lesson must teach the topic directly. Do not tell the student to research
elsewhere, "go find examples", or only give a summary. Explain the material as
if this is the student's main lesson for today.

FORMAT YOUR RESPONSE EXACTLY LIKE THIS:

## OVERVIEW
Explain what this topic covers and why it matters in real conversations.

## FULL EXPLANATION
Teach the topic step by step. Include rules, patterns, when to use them, and
how they change between formal and informal situations when relevant.

## EXAMPLES
Give 8-10 examples in $languageName. For each example include:
- the sentence in $languageName
- a simple phonetic pronunciation guide
- the English meaning
- a short note explaining the pattern

## VOCABULARY
List 10-14 essential words or phrases:
WORD | PHONETIC | MEANING | EXAMPLE SENTENCE

## PRONUNCIATION TIPS
Give specific pronunciation tips for sounds, rhythm, stress, tones, or letters
that matter for this topic.

## COMMON MISTAKES
Explain 4-6 mistakes learners make in this topic and how to avoid them.

## GUIDED PRACTICE
Give 5 practice exercises with answers immediately below each exercise.

## CULTURAL NOTE
Explain one cultural or real-life usage detail connected to the topic.

Keep it clear, practical, and encouraging. Aim for 1000-1400 words.
''';

    try {
      lastError = null;
      final response = await _getText(
        prompt,
      ).timeout(const Duration(seconds: 90));
      return _cleanText(response);
    } catch (e) {
      lastError = e.toString();
      // ignore: avoid_print
      print('[AiLessonService] lesson error: $e');
      return null;
    }
  }

  // ── Generate vocabulary for a completed topic ─────────────────────────────

  /// Returns a list of vocabulary items as JSON string.
  /// Caller parses and stores them in LanguageProgress.vocabulary.
  Future<String?> generateVocabularyForTopic({
    required String languageName,
    required String topicTitle,
  }) async {
    final prompt =
        '''
Generate exactly 8 vocabulary items for a $languageName learner studying "$topicTitle".

Respond ONLY with a valid JSON array, no markdown and no explanation:
[
  {
    "word": "word in $languageName",
    "translation": "English meaning",
    "phonetic": "pronunciation guide",
    "example": "example sentence in $languageName",
    "exampleTranslation": "English translation of example"
  }
]
''';

    try {
      lastError = null;
      final response = await _getText(
        prompt,
      ).timeout(const Duration(seconds: 45));
      return _cleanJsonArray(response);
    } catch (e) {
      lastError = e.toString();
      // ignore: avoid_print
      print('[AiLessonService] vocab error: $e');
      return null;
    }
  }

  // ── Generate a quiz question ───────────────────────────────────────────────

  Future<String?> generatePracticeReply({
    required String languageName,
    required String learnerMessage,
    required String conversationHistory,
    required int progressPercent,
  }) async {
    final prompt =
        '''
You are a warm, realistic $languageName conversation tutor.

Student progress: $progressPercent% through the course.

Conversation so far:
$conversationHistory

Student just said:
$learnerMessage

Respond like a live tutor. Keep it interactive and useful.

FORMAT:
## REPLY
Continue the conversation naturally in $languageName. Use simple language if the
student is early in the course. Include an English meaning in parentheses only
when needed.

## CORRECTION
If the student's message has mistakes, show the corrected version and explain
briefly. If it is correct, say what they did well.

## NEXT PROMPT
Ask one short follow-up question in $languageName that keeps the conversation going.

Keep the response under 180 words.
''';

    try {
      lastError = null;
      final response = await _getText(
        prompt,
      ).timeout(const Duration(seconds: 45));
      return _cleanText(response);
    } catch (e) {
      lastError = e.toString();
      // ignore: avoid_print
      print('[AiLessonService] practice error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateQuizQuestion({
    required String languageName,
    required String word,
    required String translation,
    required List<String> otherTranslations,
  }) async {
    final options = [...otherTranslations.take(3), translation]..shuffle();
    return {
      'question': 'What does "$word" mean in English?',
      'options': options,
      'correctAnswer': translation,
    };
  }

  Future<String> _getText(String prompt) async {
    Object? lastError;

    if (_apiKey.trim().isNotEmpty) {
      try {
        final text = await _postChatCompletion(prompt);
        if (text.trim().isNotEmpty) return text;
        lastError = 'Pollinations chat completion returned an empty response';
      } catch (e) {
        lastError = 'Pollinations chat completion: $e';
      }
    }

    for (final route in _routes) {
      if (route.requiresApiKey && _apiKey.trim().isEmpty) continue;

      try {
        final uri = route.uriFor(
          prompt: prompt,
          apiKey: _apiKey.trim().isEmpty ? null : _apiKey.trim(),
        );

        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError =
              '${route.label} HTTP ${response.statusCode}: ${response.body}';
          continue;
        }

        final text = response.body.trim();
        if (text.isNotEmpty) return text;
        lastError = '${route.label} returned an empty response';
      } catch (e) {
        lastError = '${route.label}: $e';
      }
    }

    throw Exception(lastError ?? 'No AI text route responded');
  }

  Future<String> _postChatCompletion(String prompt) async {
    final response = await http.post(
      Uri.parse('$_unifiedBaseUrl/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${_apiKey.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'openai',
        'private': true,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a concise, practical language tutor. Return plain markdown only.',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format');
    }

    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String) return content;
        }

        final text = first['text'];
        if (text is String) return text;
      }
    }

    final outputText = decoded['output_text'];
    if (outputText is String) return outputText;

    throw Exception('No text content in response');
  }

  String? _cleanText(String raw) {
    final text = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    return text.isEmpty ? null : text;
  }

  String? _cleanJsonArray(String raw) {
    final text = _cleanText(raw);
    if (text == null) return null;

    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start < 0 || end <= start) return text;

    return text.substring(start, end + 1).trim();
  }
}

class _PollinationsTextRoute {
  final String baseUrl;
  final String model;
  final String label;
  final bool requiresApiKey;

  const _PollinationsTextRoute({
    required this.baseUrl,
    required this.model,
    required this.label,
    this.requiresApiKey = false,
  });

  Uri uriFor({required String prompt, required String? apiKey}) {
    return Uri.parse('$baseUrl/${Uri.encodeComponent(prompt)}').replace(
      queryParameters: {
        'model': model,
        'private': 'true',
        'safe': 'true',
        if (apiKey != null) 'key': apiKey,
      },
    );
  }
}
