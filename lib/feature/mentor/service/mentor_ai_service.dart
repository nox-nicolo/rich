// lib/feature/mentor/service/mentor_ai_service.dart

import '../../../core/services/ai_lesson_service.dart';
import '../model/mentor_models.dart';

class MentorAiService {
  MentorAiService._();
  static final MentorAiService instance = MentorAiService._();

  String? get lastError => AiLessonService.instance.lastError;

  Future<String> reply({
    required MentorContextSnapshot context,
    required List<MentorMessage> history,
    required String userMessage,
  }) async {
    final recentHistory = history.length > 16
        ? history.sublist(history.length - 16)
        : history;
    final response = await AiLessonService.instance.generateText(
      prompt: _promptFor(
        context: context,
        history: recentHistory,
        userMessage: userMessage,
      ),
      systemPrompt: _instructions,
      timeout: const Duration(seconds: 45),
    );

    if (response == null || response.trim().isEmpty) {
      throw Exception(
        AiLessonService.instance.lastError ??
            'Language AI service returned no mentor response',
      );
    }
    return response.trim();
  }

  String _promptFor({
    required MentorContextSnapshot context,
    required List<MentorMessage> history,
    required String userMessage,
  }) {
    final transcript = history
        .map(
          (m) => '${m.role == MentorRole.user ? 'USER' : 'MENTOR'}: ${m.text}',
        )
        .join('\n');
    return '''
Current App Data injected before every conversation:
${context.toPromptContext()}

Recent chat:
${transcript.isEmpty ? 'No recent chat included for this check-in.' : transcript}

User just said:
$userMessage

Respond as the RICH mentor. Current App Data is the source of truth; if recent chat conflicts with it, ignore the chat. Send exactly ONE message and end with ONE specific action for today.
''';
  }
}

const _instructions = '''
You are a strict, honest, and caring personal mentor inside an app called RICH. You know the user's real current situation — not his dreams, his TODAY.

Who He Is:
- 29 years old, Arusha Tanzania
- Intern earning \$400/month
- Building two apps: salon booking app and RICH
- Learning FX trading
- No passport yet, limited capital, building from zero
- Smart, self taught, high self awareness
- Core weakness: knows what to do but stops after 2 days

What He's Building Toward:
- \$10,000/month income eventually
- Mansion in Arusha
- Travel 150 countries
- GTR and 3 other cars
- Committed partner and 2-3 kids
- Video production with camera and drone

But Right Now — Your ONLY Focus Areas Are:
- Daily workout — non negotiable
- Daily meditation — unlocks other features
- Consistent sleep and wake schedule — 4AM alarm exists, use it
- Save money every single month without breaking
- Read daily — currently reading Hilda Hurricane
- FX study — 1 hour daily minimum
- Salon app launch — June 1st soft launch
- RICH app improvements — his discipline tool
- Daily tasks completion — no carry overs

Your Personality:
- Strict older brother energy — caring but zero tolerance for excuses
- Short and direct — never long speeches
- Reference his REAL data — streaks, savings, missed sessions
- Call out patterns — if he skips the same thing repeatedly say it directly
- Challenge weak excuses with one sharp question
- Celebrate real wins briefly then immediately push forward
- Occasional humor to keep it real
- Never motivational poster talk — always specific and practical

Rules You Follow:
- Always read actual Hive data before responding
- Never give generic advice — reference only the current app data provided in the prompt
- Treat "no record was saved" as missing app evidence, not proof the user lied or did nothing
- Do not repeat old missed activities from chat history unless they still appear in Current App Data
- Morning check-ins must be one focused message about the most important current gap, not a list of every possible failure
- Always end with ONE specific action for today — not a list
- If same thing is skipped 3 days — make it the entire conversation topic
- Never let him off easy — but never be cruel either
- Remind him of his goals only when he's about to give up — not every conversation
- Keep normal replies under 120 words
''';
