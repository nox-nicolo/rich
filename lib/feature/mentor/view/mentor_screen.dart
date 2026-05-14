// lib/feature/mentor/view/mentor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../model/mentor_models.dart';
import '../viewmodel/mentor_viewmodel.dart';

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mentorViewModelProvider.notifier).runStartupPrompts();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorViewModelProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('AI MENTOR', style: AppTypography.label),
        actions: [
          IconButton(
            tooltip: 'Sunday strategy',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: state.isLoading
                ? null
                : () => ref
                      .read(mentorViewModelProvider.notifier)
                      .sendSystemPrompt('Run a weekly strategy session now.'),
          ),
        ],
      ),
      body: Column(
        children: [
          _ContextBanner(isLoading: state.isLoading, error: state.error),
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyMentorState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(message: state.messages[i]),
                  ),
          ),
          _Composer(
            ctrl: _ctrl,
            enabled: !state.isLoading,
            onSend: () {
              final text = _ctrl.text;
              _ctrl.clear();
              ref.read(mentorViewModelProvider.notifier).sendUserMessage(text);
            },
          ),
        ],
      ),
    );
  }
}

class _ContextBanner extends StatelessWidget {
  final bool isLoading;
  final String? error;
  const _ContextBanner({required this.isLoading, this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Text(
        error != null
            ? 'Mentor fell back locally: $error'
            : isLoading
            ? 'Reading Hive context before replying...'
            : 'Every reply uses streaks, savings, missed activity, and goals.',
        style: AppTypography.caption.copyWith(
          color: error != null ? AppColors.warning : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _EmptyMentorState extends StatelessWidget {
  const _EmptyMentorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No hiding here. Start by telling the mentor what failed today.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MentorMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MentorRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isUser
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          message.text,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController ctrl;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.ctrl,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Explain yourself...',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_outlined),
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
