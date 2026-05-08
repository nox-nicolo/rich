// lib/feature/milestones/view/pages/add_milestone_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/vibration_service.dart';
import '../../model/milestone.dart';
import '../../viewmodel/milestone_viewmodel.dart';

class AddMilestonePage extends ConsumerStatefulWidget {
  final Milestone? existing;
  const AddMilestonePage({super.key, this.existing});

  @override
  ConsumerState<AddMilestonePage> createState() => _AddMilestonePageState();
}

class _AddMilestonePageState extends ConsumerState<AddMilestonePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _processCtrl = TextEditingController();

  late Horizon _horizon;
  late DateTime _targetDate;
  late double _progress;
  late MilestoneStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _noteCtrl.text = e.note ?? '';
      _processCtrl.text = e.processSteps.join('\n');
      _horizon = e.horizon;
      _targetDate = e.targetDate;
      _progress = e.progress;
      _status = e.status;
    } else {
      _horizon = Horizon.sixMonth;
      _targetDate = defaultTargetFor(Horizon.sixMonth);
      _progress = 0;
      _status = MilestoneStatus.active;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _processCtrl.dispose();
    super.dispose();
  }

  void _switchHorizon(Horizon h) {
    setState(() {
      _horizon = h;
      // Realign the target to the horizon's calendar window whenever the
      // user flips the bucket — keeps a 6-month goal inside its half and
      // a yearly goal inside the current year.
      _targetDate = defaultTargetFor(h);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final last = maxTargetFor(_horizon, from: now);
    // Initial must sit within [first, last]; clamp if a stored date drifted
    // outside the window after a horizon switch.
    final initial = _targetDate.isAfter(last) ? last : _targetDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: last,
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final vm = ref.read(milestoneViewModelProvider.notifier);
      final existing = widget.existing;
      final processSteps = _parseProcessSteps(_processCtrl.text);

      // Progress=100% implies done. Status already pinned to done by any
      // explicit MARK DONE tap, so either path funnels here.
      final effectiveStatus = _progress >= 1.0 ? MilestoneStatus.done : _status;

      final wasDone = existing?.status == MilestoneStatus.done;
      final isDone = effectiveStatus == MilestoneStatus.done;
      final justReached = !wasDone && isDone;

      if (existing == null) {
        await vm.create(
          title: _titleCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
          processSteps: processSteps,
          horizon: _horizon,
          targetDate: _targetDate,
        );
      } else {
        await vm.update(
          existing.copyWith(
            title: _titleCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            clearNote: _noteCtrl.text.trim().isEmpty,
            processSteps: processSteps,
            horizon: _horizon,
            targetDate: _targetDate,
            progress: _progress,
            status: effectiveStatus,
          ),
        );
      }

      if (justReached) {
        VibrationService.strongPulse();
      }

      if (!mounted) return;

      if (justReached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            content: Text(
              'Goal reached — ${_titleCtrl.text.trim()}',
              style: AppTypography.body.copyWith(color: AppColors.background),
            ),
          ),
        );
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _parseProcessSteps(String raw) => raw
      .split('\n')
      .map((step) => step.trim())
      .where((step) => step.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          isEdit ? 'EDIT MILESTONE' : 'NEW MILESTONE',
          style: AppTypography.label.copyWith(fontSize: 12),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            size: AppSpacing.iconMd,
            color: AppColors.textSecondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.success,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: AppTypography.label.copyWith(
                      color: AppColors.success,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HORIZON', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _HorizonPill(
                    label: '6 MONTHS',
                    selected: _horizon == Horizon.sixMonth,
                    onTap: () => _switchHorizon(Horizon.sixMonth),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HorizonPill(
                    label: 'YEAR',
                    selected: _horizon == Horizon.yearly,
                    onTap: () => _switchHorizon(Horizon.yearly),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('TITLE', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _titleCtrl,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDec('e.g. Read 24 books'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('NOTE (optional)', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDec('What does success look like?'),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('PROCESS / STEPS', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _processCtrl,
                minLines: 4,
                maxLines: 8,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDec(
                  'One step per line\nExample: Finish outline\nExample: Practice every weekday',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Define the path to the milestone. Keep each step concrete.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('TARGET DATE', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSpacing.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${_targetDate.day.toString().padLeft(2, '0')}/'
                        '${_targetDate.month.toString().padLeft(2, '0')}/'
                        '${_targetDate.year}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        periodLabelFor(_horizon),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _horizon == Horizon.sixMonth
                    ? 'Capped at end of this half — Jun 30 or Dec 31.'
                    : 'Capped at end of this year — Dec 31.',
                style: AppTypography.caption,
              ),
              if (isEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                _ProgressSection(
                  progress: _progress,
                  status: _status,
                  onChanged: (v) => setState(() => _progress = v),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusActions(
                  status: _status,
                  onMarkDone: () => setState(() {
                    _progress = 1.0;
                    _status = MilestoneStatus.done;
                  }),
                  onReactivate: () => setState(() {
                    _status = MilestoneStatus.active;
                    if (_progress >= 1.0) _progress = 0.99;
                  }),
                  onDrop: () => setState(() {
                    _status = MilestoneStatus.dropped;
                  }),
                ),
              ],

              const SizedBox(height: AppSpacing.x3l),

              if (isEdit)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text(
                                'Delete milestone?',
                                style: AppTypography.h3,
                              ),
                              content: Text(
                                'This cannot be undone.',
                                style: AppTypography.body,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          await ref
                              .read(milestoneViewModelProvider.notifier)
                              .delete(widget.existing!.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'DELETE',
                    style: AppTypography.label.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.accent, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  );
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final MilestoneStatus status;
  final ValueChanged<double> onChanged;

  const _ProgressSection({
    required this.progress,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final accent = status == MilestoneStatus.done
        ? AppColors.success
        : status == MilestoneStatus.dropped
        ? AppColors.textMuted
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROGRESS', style: AppTypography.label),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTypography.mono.copyWith(color: accent, fontSize: 14),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: AppColors.elevated,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Text(
            'Slide to update where you are. Progress can\'t always be auto-tracked.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final MilestoneStatus status;
  final VoidCallback onMarkDone;
  final VoidCallback onReactivate;
  final VoidCallback onDrop;

  const _StatusActions({
    required this.status,
    required this.onMarkDone,
    required this.onReactivate,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    if (status == MilestoneStatus.done) {
      return _ActionButton(
        label: 'REACTIVATE',
        color: AppColors.accent,
        onTap: onReactivate,
      );
    }
    if (status == MilestoneStatus.dropped) {
      return _ActionButton(
        label: 'REACTIVATE',
        color: AppColors.accent,
        onTap: onReactivate,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'MARK DONE',
            color: AppColors.success,
            onTap: onMarkDone,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionButton(
            label: 'DROP',
            color: AppColors.textMuted,
            onTap: onDrop,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTypography.label.copyWith(color: color)),
      ),
    );
  }
}

class _HorizonPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _HorizonPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
