// lib/features/work/view/widgets/meeting_prep_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/meeting_model.dart';
import '../../viewmodel/work_viewmodel.dart';

class MeetingPrepWidget extends ConsumerWidget {
  const MeetingPrepWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workViewModelProvider);
    final vm = ref.read(workViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'MEETINGS',
          trailing: GestureDetector(
            onTap: () => _showAddMeetingSheet(context, vm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border:
                    Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.add,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (state.upcomingMeetings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.x3l),
            child: Center(
              child: Text('No upcoming meetings',
                  style: AppTypography.body),
            ),
          )
        else
          ...state.upcomingMeetings.map(
            (meeting) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MeetingCard(
                meeting: meeting,
                onPrep: (notes) =>
                    vm.saveMeetingPrepNotes(meeting.id, notes),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddMeetingSheet(BuildContext context, WorkViewModel vm) {
    final titleCtrl = TextEditingController();
    final agendaCtrl = TextEditingController();
    DateTime startAt = _roundToNextQuarter(
      DateTime.now().add(const Duration(minutes: 15)),
    );
    int durationMinutes = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('ADD MEETING', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Meeting title...'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: agendaCtrl,
                maxLines: 3,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Agenda / materials (optional)...'),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('STARTS', style: AppTypography.chip
                  .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.xs + 2),
              Row(
                children: [
                  Expanded(
                    child: _PickerChip(
                      label: 'DATE',
                      value: _formatDate(startAt),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startAt,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            startAt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              startAt.hour,
                              startAt.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickerChip(
                      label: 'TIME',
                      value:
                          '${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}',
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(startAt),
                        );
                        if (picked != null) {
                          setState(() {
                            startAt = DateTime(
                              startAt.year,
                              startAt.month,
                              startAt.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              Text('DURATION',
                  style: AppTypography.chip
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.xs + 2),
              Row(
                children: [15, 30, 45, 60, 90].map((mins) {
                  final selected = mins == durationMinutes;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => durationMinutes = mins),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: selected ? 1 : 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${mins}m',
                              style: AppTypography.chip.copyWith(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    vm.addMeeting(
                      title: titleCtrl.text.trim(),
                      scheduledAt: startAt,
                      durationMinutes: durationMinutes,
                      agenda: agendaCtrl.text.trim().isEmpty
                          ? null
                          : agendaCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'ADD',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.background, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _roundToNextQuarter(DateTime dt) {
  final addMin = (15 - dt.minute % 15) % 15;
  final rounded = dt.add(Duration(minutes: addMin));
  return DateTime(
      rounded.year, rounded.month, rounded.day, rounded.hour, rounded.minute);
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  final today = DateTime.now();
  final isToday = dt.year == today.year &&
      dt.month == today.month &&
      dt.day == today.day;
  if (isToday) return 'Today';
  return '${months[dt.month - 1]} ${dt.day}';
}

class _PickerChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.chip
                    .copyWith(color: AppColors.textMuted, fontSize: 9)),
            Text(value,
                style: AppTypography.mono
                    .copyWith(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final ValueChanged<String> onPrep;

  const _MeetingCard({required this.meeting, required this.onPrep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: meeting.isSoon
              ? AppColors.caution.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (meeting.isSoon)
                Padding(
                  padding: const EdgeInsets.only(
                      right: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.caution.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'SOON',
                      style: AppTypography.chip.copyWith(
                          color: AppColors.caution, fontSize: 9),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  meeting.title,
                  style: AppTypography.h3.copyWith(fontSize: 13),
                ),
              ),
              Text(
                RichDateUtils.timeAgo(meeting.scheduledAt),
                style: AppTypography.caption,
              ),
            ],
          ),
          if (meeting.agenda != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(meeting.agenda!, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '${meeting.durationMinutes}min',
                style: AppTypography.mono.copyWith(fontSize: 11),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showPrepSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: meeting.hasPrepNotes
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSm),
                    border: Border.all(
                      color: meeting.hasPrepNotes
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    meeting.hasPrepNotes ? 'PREP DONE' : 'ADD PREP',
                    style: AppTypography.chip.copyWith(
                      color: meeting.hasPrepNotes
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () =>
                    context.go('/work/meeting/${meeting.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: meeting.isInProgress
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.18)
                        : AppColors.accent.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: meeting.isInProgress
                          ? const Color(0xFF2ECC71)
                          : AppColors.accent,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        meeting.isInProgress
                            ? Icons.mic
                            : Icons.play_arrow,
                        size: 12,
                        color: meeting.isInProgress
                            ? const Color(0xFF2ECC71)
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meeting.isInProgress ? 'LIVE' : 'START',
                        style: AppTypography.chip.copyWith(
                          color: meeting.isInProgress
                              ? const Color(0xFF2ECC71)
                              : AppColors.accent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPrepSheet(BuildContext context) {
    final ctrl = TextEditingController(text: meeting.prepNotes);
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
            Text('PREP NOTES', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Text(meeting.title, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              maxLines: 5,
              autofocus: true,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'What do you need to prepare?',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onPrep(ctrl.text.trim());
                  Navigator.pop(context);
                },
                child: Text(
                  'SAVE',
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
