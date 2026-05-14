// lib/feature/mentor/viewmodel/mentor_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../model/mentor_models.dart';
import '../repository/mentor_repository.dart';
import '../service/mentor_ai_service.dart';
import '../service/mentor_context_service.dart';

class MentorState {
  final List<MentorMessage> messages;
  final bool isLoading;
  final String? error;

  const MentorState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  factory MentorState.initial() => const MentorState(messages: []);

  MentorState copyWith({
    List<MentorMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MentorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MentorViewModel extends StateNotifier<MentorState> {
  final MentorRepository _repo;
  final MentorContextService _context;
  final MentorAiService _ai;

  MentorViewModel(this._repo, this._context, this._ai)
    : super(MentorState.initial()) {
    _load();
  }

  void _load() {
    state = state.copyWith(messages: _repo.loadMessages());
  }

  Future<void> runStartupPrompts() async {
    final now = DateTime.now();
    final today = _dateKey(now);
    if (_repo.loadLastMorningKey() != today && now.hour >= 6) {
      await _repo.saveLastMorningKey(today);
      await sendSystemPrompt(
        'Start the daily morning check-in. Read yesterday from context and ask why the specific missed items happened. Do not be soft.',
        includeHistory: false,
      );
    }

    if (now.weekday == DateTime.sunday &&
        now.hour >= 7 &&
        _repo.loadLastSundayKey() != today) {
      await _repo.saveLastSundayKey(today);
      await sendSystemPrompt(
        'Run the weekly Sunday strategy session. Review the week, identify what failed, and help plan next week inside RICH.',
      );
    }
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final previous = state.messages;
    final user = _message(MentorRole.user, trimmed);
    final next = [...previous, user];
    state = state.copyWith(messages: next, isLoading: true, clearError: true);
    await _repo.saveMessages(next);

    await _completeWithAi(trimmed, previous, visibleBase: next);
  }

  Future<void> sendSystemPrompt(
    String prompt, {
    bool includeHistory = true,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _completeWithAi(prompt, includeHistory ? state.messages : const []);
  }

  Future<void> _completeWithAi(
    String userMessage,
    List<MentorMessage> historyForAi, {
    List<MentorMessage>? visibleBase,
  }) async {
    try {
      final snapshot = _context.build();
      final reply = await _ai.reply(
        context: snapshot,
        history: historyForAi,
        userMessage: userMessage,
      );
      final assistant = _message(MentorRole.assistant, reply);
      final updated = [...(visibleBase ?? historyForAi), assistant];
      state = state.copyWith(messages: updated, isLoading: false);
      await _repo.saveMessages(updated);
    } catch (e) {
      final errorText = e.toString();
      final assistant = _message(
        MentorRole.assistant,
        'AI Mentor error: $errorText',
      );
      final updated = [...(visibleBase ?? historyForAi), assistant];
      state = state.copyWith(
        messages: updated,
        isLoading: false,
        error: errorText,
      );
      await _repo.saveMessages(updated);
    }
  }

  MentorMessage _message(MentorRole role, String text) {
    return MentorMessage(
      id: const Uuid().v4(),
      role: role,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

final mentorRepositoryProvider = Provider((_) => MentorRepository());
final mentorContextServiceProvider = Provider((_) => MentorContextService());
final mentorAiServiceProvider = Provider((_) => MentorAiService.instance);

final mentorViewModelProvider =
    StateNotifierProvider<MentorViewModel, MentorState>((ref) {
      return MentorViewModel(
        ref.read(mentorRepositoryProvider),
        ref.read(mentorContextServiceProvider),
        ref.read(mentorAiServiceProvider),
      );
    });
