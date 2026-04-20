// lib/features/life/view/widgets/recovery_mode_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/recovery_model.dart';
import '../../viewmodel/life_viewmodel.dart';

class RecoveryModeWidget extends ConsumerWidget {
  const RecoveryModeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeViewModelProvider);
    final vm = ref.read(lifeViewModelProvider.notifier);

    final todaySessions = state.todayRecoverySessions
        .where((s) => s.endedAt != null)
        .toList();
    final recentHistory = state.recentRecoverySessions
        .where((s) => s.endedAt != null)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'RECOVERY'),
        _TodaySummary(
          minutes: state.todayRecoveryMinutes,
          sessions: todaySessions.length,
          live: state.isInRecovery,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.isInRecovery)
          _ActiveRecoveryCard(
            session: state.activeRecovery!,
            onEnd: () => _showEndSheet(context, vm),
          )
        else
          _RecoverySelector(
            onStart: (mode) => vm.startRecovery(mode),
          ),
        if (recentHistory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('RECENT', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...recentHistory.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _HistoryRow(session: s),
              )),
        ],
      ],
    );
  }

  void _showEndSheet(BuildContext context, LifeViewModel vm) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
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
            Text('END RECOVERY', style: AppTypography.label),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'How do you feel now? (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  vm.endRecovery(
                    note: ctrl.text.trim().isEmpty
                        ? null
                        : ctrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  'END SESSION',
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

class _RecoverySelector extends StatelessWidget {
  final ValueChanged<RecoveryMode> onStart;

  const _RecoverySelector({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: RecoveryMode.values.map((mode) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onStart(mode),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.cardPad),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border:
                    Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: AppTypography.h3
                              .copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(mode.description,
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

class _ActiveRecoveryCard extends StatefulWidget {
  final RecoverySession session;
  final VoidCallback onEnd;

  const _ActiveRecoveryCard({
    required this.session,
    required this.onEnd,
  });

  @override
  State<_ActiveRecoveryCard> createState() => _ActiveRecoveryCardState();
}

class _ActiveRecoveryCardState extends State<_ActiveRecoveryCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _elapsed() {
    final diff = DateTime.now().difference(widget.session.startedAt);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${diff.inMinutes}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'RECOVERY ACTIVE',
                style: AppTypography.label.copyWith(
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              Text(_elapsed(),
                  style: AppTypography.mono.copyWith(
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.session.mode.label,
            style: AppTypography.h3.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(widget.session.mode.description,
              style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.onEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.border, width: 0.5),
                ),
                child: Text('END', style: AppTypography.chip),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final int minutes;
  final int sessions;
  final bool live;

  const _TodaySummary({
    required this.minutes,
    required this.sessions,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final color = minutes > 0 || live
        ? AppColors.success
        : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY', style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$minutes',
                      style: AppTypography.h1.copyWith(
                        color: color,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('min', style: AppTypography.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sessions',
                style: AppTypography.h3.copyWith(color: color),
              ),
              Text(
                sessions == 1 ? 'session' : 'sessions',
                style: AppTypography.caption,
              ),
              if (live) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('LIVE',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        )),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final RecoverySession session;

  const _HistoryRow({required this.session});

  String _stamp() {
    final s = session.startedAt;
    final now = DateTime.now();
    final isToday = s.year == now.year &&
        s.month == now.month &&
        s.day == now.day;
    final hh = s.hour.toString().padLeft(2, '0');
    final mm = s.minute.toString().padLeft(2, '0');
    if (isToday) return '$hh:$mm';
    return '${s.month}/${s.day} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final mins = session.endedAt!.difference(session.startedAt).inMinutes;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(_stamp(),
              style: AppTypography.mono.copyWith(
                  color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              session.mode.label,
              style: AppTypography.body.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${mins}m',
              style: AppTypography.mono.copyWith(
                  color: AppColors.success)),
        ],
      ),
    );
  }
}
