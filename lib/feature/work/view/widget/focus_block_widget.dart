// lib/features/work/view/widgets/focus_block_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/focus_session_model.dart';
import '../../viewmodel/work_viewmodel.dart';

class FocusBlockWidget extends ConsumerWidget {
  const FocusBlockWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workViewModelProvider);
    final vm = ref.read(workViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'FOCUS BLOCKS'),
        if (state.hasActiveSession)
          _ActiveSessionCard(
            session: state.activeSession!,
            timerSeconds: state.timerSeconds,
            timerRunning: state.timerRunning,
            onPause: vm.pauseTimer,
            onResume: vm.startTimer,
            onComplete: () => _showCompleteSheet(context, vm),
            onCancel: vm.cancelFocusSession,
          )
        else
          _SessionSelector(
            onStart: (type) => vm.startFocusSession(type),
          ),
        if (state.todaySessions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('COMPLETED TODAY', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...state.todaySessions
              .where((s) => s.completed)
              .map((s) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.xs + 2),
                    child: _SessionLogTile(session: s),
                  )),
        ],
      ],
    );
  }

  void _showCompleteSheet(BuildContext context, WorkViewModel vm) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => Padding(
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
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('SESSION OUTCOME', style: AppTypography.label),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'What did you accomplish?',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  vm.completeFocusSession(outcome: ctrl.text.trim());
                },
                child: Text(
                  'COMPLETE',
                  style: AppTypography.h3.copyWith(
                      color: AppColors.background, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSelector extends StatelessWidget {
  final ValueChanged<FocusSessionType> onStart;

  const _SessionSelector({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: FocusSessionType.values.map((type) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onStart(type),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.cardPad),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: type.isDeepWork
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVar,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '${type.defaultDurationMinutes}m',
                      style: AppTypography.mono
                          .copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.label,
                            style: AppTypography.h3
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(type.sublabel,
                            style: AppTypography.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: AppSpacing.iconSm,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final FocusSessionModel session;
  final int timerSeconds;
  final bool timerRunning;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _ActiveSessionCard({
    required this.session,
    required this.timerSeconds,
    required this.timerRunning,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 -
        (timerSeconds / session.durationSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                session.type.label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                RichTimeUtils.formatMMSS(timerSeconds),
                style: AppTypography.mono,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVar,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text('CANCEL',
                    style: AppTypography.label
                        .copyWith(color: AppColors.textMuted)),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: timerRunning ? onPause : onResume,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    timerRunning ? 'PAUSE' : 'RESUME',
                    style: AppTypography.chip,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: AppTypography.chip
                        .copyWith(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionLogTile extends StatelessWidget {
  final FocusSessionModel session;

  const _SessionLogTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final h = session.startedAt.hour.toString().padLeft(2, '0');
    final m = session.startedAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              session.type.label,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          Text(
            '${session.durationMinutes}m',
            style: AppTypography.mono.copyWith(fontSize: 11),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('$h:$m', style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.check_circle_outline,
              size: AppSpacing.iconSm, color: AppColors.success),
        ],
      ),
    );
  }
}
