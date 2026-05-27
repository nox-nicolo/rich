// lib/features/meditation/view/meditation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/services/meditation_frequency_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/rich_section_header.dart';
import '../model/meditation_type.dart';
import '../viewmodel/meditation_viewmodel.dart';
import 'widget/streak_widget.dart';
import 'widget/mood_check_widget.dart';
import 'widget/readiness_indicator_widget.dart';
import 'widget/session_tile_widget.dart';

class MeditationScreen extends ConsumerWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'MEDITATION',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.completedToday)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _StatusChip(label: 'GATE OPEN', color: AppColors.success),
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
          : state.hasActiveSession
          ? _ActiveSessionView(state: state)
          : _IdleView(state: state),
    );
  }
}

class _IdleView extends ConsumerWidget {
  final MeditationState state;

  const _IdleView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(meditationViewModelProvider.notifier);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.x3l,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              StreakWidget(streak: state.streak),
              const SizedBox(height: AppSpacing.xl),
              MoodCheckWidget(
                selected: state.selectedMood,
                onSelect: vm.selectMood,
              ),
              const SizedBox(height: AppSpacing.xl),
              ReadinessIndicatorWidget(completedToday: state.completedToday),
              const SizedBox(height: AppSpacing.xl),
              const RichSectionHeader(title: 'SELECT SESSION'),
              ...MeditationType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SessionTileWidget(
                    type: type,
                    completedToday: state.isTypeCompletedToday(type),
                    onStart: () => vm.startSession(type),
                  ),
                ),
              ),
              if (state.todaySessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const RichSectionHeader(title: 'TODAY'),
                ...state.todaySessions.reversed.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                    child: SessionLogTile(session: s),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionView extends ConsumerStatefulWidget {
  final MeditationState state;

  const _ActiveSessionView({required this.state});

  @override
  ConsumerState<_ActiveSessionView> createState() => _ActiveSessionViewState();
}

class _ActiveSessionViewState extends ConsumerState<_ActiveSessionView> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _syncFrequency(widget.state);
  }

  @override
  void didUpdateWidget(covariant _ActiveSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFrequency(widget.state);
  }

  @override
  void dispose() {
    MeditationFrequencyService.instance.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  void _syncFrequency(MeditationState state) {
    final session = state.activeSession;
    if (session == null || !state.timerRunning) {
      MeditationFrequencyService.instance.stop();
      return;
    }

    MeditationFrequencyService.instance.play(session.type.frequencyHz);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationViewModelProvider);
    final vm = ref.read(meditationViewModelProvider.notifier);
    final session = state.activeSession!;

    final progress =
        1.0 - (state.timerSeconds / session.durationSeconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            session.type.label.toUpperCase(),
            style: AppTypography.label.copyWith(letterSpacing: 4),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(session.type.sublabel, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xs),
          Text(
            session.type.frequencyLabel,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.x5l),
          _TimerRing(
            progress: progress,
            timeString: RichTimeUtils.formatMMSS(state.timerSeconds),
          ),
          const SizedBox(height: AppSpacing.x5l),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: Icons.refresh_outlined,
                onTap: vm.resetTimer,
                muted: true,
              ),
              const SizedBox(width: AppSpacing.xxl),
              _CircleButton(
                icon: state.timerRunning
                    ? Icons.pause_outlined
                    : Icons.play_arrow_outlined,
                onTap: state.timerRunning ? vm.pauseTimer : vm.startTimer,
                large: true,
              ),
              const SizedBox(width: AppSpacing.xxl),
              _CircleButton(
                icon: Icons.check_outlined,
                onTap: () => _showCompleteSheet(context, vm),
                muted: true,
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: vm.cancelSession,
            child: Text(
              'CANCEL SESSION',
              style: AppTypography.label.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showCompleteSheet(BuildContext context, MeditationViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => _CompleteSessionSheet(vm: vm),
    );
  }
}

class _CompleteSessionSheet extends StatefulWidget {
  final MeditationViewModel vm;
  const _CompleteSessionSheet({required this.vm});

  @override
  State<_CompleteSessionSheet> createState() => _CompleteSessionSheetState();
}

class _CompleteSessionSheetState extends State<_CompleteSessionSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('COMPLETE SESSION', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteCtrl,
            autofocus: false,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Any reflection or note (optional)...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final note = _noteCtrl.text.trim();
                Navigator.pop(context);
                widget.vm.completeSession(note: note.isNotEmpty ? note : null);
              },
              child: Text(
                'DONE',
                style: AppTypography.h3.copyWith(
                  color: AppColors.background,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress;
  final String timeString;

  const _TimerRing({required this.progress, required this.timeString});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 1.5,
              backgroundColor: AppColors.surfaceVar,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          Text(
            timeString,
            style: AppTypography.display.copyWith(
              fontSize: 38,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool muted;
  final bool large;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.muted = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 68.0 : 50.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: large ? AppColors.accent : AppColors.surface,
          border: large
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(
          icon,
          size: large ? 30 : 22,
          color: large
              ? AppColors.background
              : (muted ? AppColors.textMuted : AppColors.textPrimary),
        ),
      ),
    );
  }
}

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
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(label, style: AppTypography.chip.copyWith(color: color)),
    );
  }
}
