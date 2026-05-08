// lib/feature/betting/view/widget/betting_plan_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/betting_plan_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

class BettingPlanWidget extends ConsumerWidget {
  const BettingPlanWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bettingViewModelProvider);
    final vm = ref.read(bettingViewModelProvider.notifier);

    // The most recent plan, regardless of its status. If it's LOST, we offer
    // a recovery plan even though it's no longer "active" (active = status==active).
    final sortedPlans = [...state.plans]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final mostRecent = sortedPlans.isNotEmpty ? sortedPlans.first : null;
    final showRecovery =
        state.activePlan == null &&
        mostRecent != null &&
        mostRecent.status == BettingPlanStatus.lost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                'ROAD TO TARGET',
                style: AppTypography.label.copyWith(letterSpacing: 2),
              ),
            ),
            _ActionButton(
              label: 'NEW PLAN',
              onTap: () => _showCreatePlanSheet(context, ref),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Active plan ──────────────────────────────────────────────────────
        if (state.activePlan != null) ...[
          _PlanHeader(plan: state.activePlan!),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _showEditPhasesSheet(context, ref, state.activePlan!),
            child: state.activePlan!.phases.isNotEmpty
                ? _PhasesBar(plan: state.activePlan!)
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVar,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DEFINE PHASES',
                          style: AppTypography.chip.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AddStepRow(plan: state.activePlan!, ref: ref),
          const SizedBox(height: AppSpacing.sm),
          _StepsTable(plan: state.activePlan!, vm: vm),
        ] else if (showRecovery) ...[
          // Last plan failed and there's no replacement yet — show its summary
          // and a one-tap REUSE banner so the user can clone it instantly.
          _PlanHeader(plan: mostRecent),
          const SizedBox(height: AppSpacing.sm),
          _ReusePlanBanner(
            failedPlan: mostRecent,
            onReuse: () => vm.reusePlan(mostRecent),
            onEdit: () => _showRecoveryPlanSheet(context, ref, mostRecent),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StepsTable(plan: mostRecent, vm: vm),
        ] else ...[
          _EmptyPlanCard(onTap: () => _showCreatePlanSheet(context, ref)),
        ],

        // ── Past plans ───────────────────────────────────────────────────────
        // Exclude the recovery banner's plan from history so it isn't shown twice.
        if (state.plans
            .where(
              (p) => !p.isActive && (!showRecovery || p.id != mostRecent.id),
            )
            .isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'PLAN HISTORY',
            style: AppTypography.chip.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlanSummaryCard(
            plans: state.plans
                .where(
                  (p) =>
                      !p.isActive && (!showRecovery || p.id != mostRecent.id),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...state.plans
              .where(
                (p) => !p.isActive && (!showRecovery || p.id != mostRecent.id),
              )
              .map(
                (p) =>
                    _PastPlanTile(plan: p, onDelete: () => vm.deletePlan(p.id)),
              ),
        ],
      ],
    );
  }

  // ── Create plan sheet ──────────────────────────────────────────────────────

  void _showCreatePlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreatePlanSheet(ref: ref),
    );
  }

  void _showEditPhasesSheet(
    BuildContext context,
    WidgetRef ref,
    BettingPlan plan,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditPhasesSheet(ref: ref, plan: plan),
    );
  }

  void _showRecoveryPlanSheet(
    BuildContext context,
    WidgetRef ref,
    BettingPlan failedPlan,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RecoveryPlanSheet(ref: ref, failedPlan: failedPlan),
    );
  }
}

// ── Create plan sheet (StatefulWidget for proper lifecycle) ──────────────────

class _CreatePlanSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreatePlanSheet({required this.ref});

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  final nameCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final oddsCtrl = TextEditingController(text: '1.5');
  final reinvCtrl = TextEditingController(text: '100');
  bool useRule = false;

  // Phase fields
  final List<_PhaseInput> _phases = [];

  @override
  void dispose() {
    nameCtrl.dispose();
    startCtrl.dispose();
    targetCtrl.dispose();
    oddsCtrl.dispose();
    reinvCtrl.dispose();
    for (final p in _phases) {
      p.nameCtrl.dispose();
      p.targetCtrl.dispose();
    }
    super.dispose();
  }

  void _addPhase() {
    setState(() {
      _phases.add(
        _PhaseInput(
          nameCtrl: TextEditingController(text: 'Phase ${_phases.length + 1}'),
          targetCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removePhase(int idx) {
    setState(() {
      _phases[idx].nameCtrl.dispose();
      _phases[idx].targetCtrl.dispose();
      _phases.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.ref.read(bettingViewModelProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('CREATE BETTING PLAN', style: AppTypography.label),
            const SizedBox(height: 16),

            _Field(ctrl: nameCtrl, hint: 'Plan name'),
            const SizedBox(height: 10),
            _Field(
              ctrl: startCtrl,
              hint: 'Starting capital (TZS)',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _Field(
              ctrl: targetCtrl,
              hint: 'Final target (TZS)',
              inputType: TextInputType.number,
            ),

            // ── Phases ──────────────────────────────────────────────────────
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'PHASES',
                  style: AppTypography.chip.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _addPhase,
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'ADD PHASE',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_phases.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'No phases — plan goes straight to final target',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ..._phases.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _Field(ctrl: e.value.nameCtrl, hint: 'Phase name'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _Field(
                        ctrl: e.value.targetCtrl,
                        hint: 'Target',
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removePhase(e.key),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Rollover toggle ─────────────────────────────────────────────
            const SizedBox(height: 14),
            Row(
              children: [
                Switch(
                  value: useRule,
                  onChanged: (v) => setState(() => useRule = v),
                  activeThumbColor: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-generate steps (rollover)',
                  style: AppTypography.caption,
                ),
              ],
            ),

            if (useRule) ...[
              const SizedBox(height: 8),
              _Field(
                ctrl: oddsCtrl,
                hint: 'Odds per bet (e.g. 1.5)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              _Field(
                ctrl: reinvCtrl,
                hint: 'Reinvest % of profit (e.g. 100)',
                inputType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final start = double.tryParse(startCtrl.text.trim());
                  final target = double.tryParse(targetCtrl.text.trim());

                  final phases = _phases
                      .asMap()
                      .entries
                      .map((e) {
                        final t = double.tryParse(
                          e.value.targetCtrl.text.trim(),
                        );
                        return PlanPhase(
                          number: e.key + 1,
                          name: e.value.nameCtrl.text.trim().isNotEmpty
                              ? e.value.nameCtrl.text.trim()
                              : 'Phase ${e.key + 1}',
                          target: t ?? 0,
                        );
                      })
                      .where((p) => p.target > 0)
                      .toList();
                  final effectiveTarget = phases.isEmpty
                      ? target
                      : phases.fold(0.0, (sum, phase) => sum + phase.target);
                  if (name.isEmpty ||
                      start == null ||
                      effectiveTarget == null) {
                    return;
                  }

                  Navigator.pop(context);
                  if (useRule) {
                    final odds = double.tryParse(oddsCtrl.text.trim()) ?? 1.5;
                    final reinv = double.tryParse(reinvCtrl.text.trim()) ?? 100;
                    await vm.createPlanFromRule(
                      name: name,
                      startingCapital: start,
                      targetCapital: effectiveTarget,
                      odds: odds,
                      reinvestPercent: reinv,
                      phases: phases,
                    );
                  } else {
                    await vm.createPlan(
                      name: name,
                      startingCapital: start,
                      targetCapital: effectiveTarget,
                      phases: phases,
                    );
                  }
                },
                child: Text(
                  'CREATE',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseInput {
  final TextEditingController nameCtrl;
  final TextEditingController targetCtrl;
  _PhaseInput({required this.nameCtrl, required this.targetCtrl});
}

// ── Reuse plan banner ─────────────────────────────────────────────────────────
//
// Shown above a failed plan. Primary action [REUSE] clones the plan
// one-tap — same name, capital, target, phases, all steps reset to pending.
// Secondary action [EDIT] opens the sheet for those who want to tweak first.

class _ReusePlanBanner extends StatelessWidget {
  final BettingPlan failedPlan;
  final VoidCallback onReuse;
  final VoidCallback onEdit;

  const _ReusePlanBanner({
    required this.failedPlan,
    required this.onReuse,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.refresh, size: 14, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Plan failed. Reuse it as-is?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              '${failedPlan.phases.length} phases · '
              '${failedPlan.steps.length} steps will be cloned',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReuse,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'REUSE PLAN',
                      style: AppTypography.label.copyWith(
                        color: AppColors.background,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'EDIT',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                    ),
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

// ── Recovery plan sheet ───────────────────────────────────────────────────────

class _RecoveryPlanSheet extends StatefulWidget {
  final WidgetRef ref;
  final BettingPlan failedPlan;
  const _RecoveryPlanSheet({required this.ref, required this.failedPlan});

  @override
  State<_RecoveryPlanSheet> createState() => _RecoveryPlanSheetState();
}

class _RecoveryPlanSheetState extends State<_RecoveryPlanSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController startCtrl;
  late final TextEditingController targetCtrl;
  late final TextEditingController oddsCtrl;
  late final TextEditingController reinvCtrl;
  bool useRule = true;
  // Phases editable inside the sheet, pre-filled from the failed plan.
  final List<_PhaseInput> _phases = [];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(
      text: 'Recovery — ${widget.failedPlan.name}',
    );
    startCtrl = TextEditingController(
      text: widget.failedPlan.startingCapital.toStringAsFixed(0),
    );
    targetCtrl = TextEditingController(
      text: widget.failedPlan.targetCapital.toStringAsFixed(0),
    );

    // Pre-fill odds + reinvest from the failed plan's first step if present;
    // these are the closest thing to the original rollover settings.
    final firstStep = widget.failedPlan.steps.isNotEmpty
        ? widget.failedPlan.steps.first
        : null;
    oddsCtrl = TextEditingController(
      text: firstStep != null ? firstStep.odds.toStringAsFixed(2) : '1.5',
    );
    // Reinvest % derived from kept ratio of first won step, else 100.
    final wonRef = widget.failedPlan.steps.firstWhere(
      (s) => s.status == BettingPlanStepStatus.won,
      orElse: () => const BettingPlanStep(step: 0, stake: 0, odds: 0),
    );
    final reinvDefault = wonRef.step != 0 && wonRef.stake > 0
        ? (() {
            final profit = wonRef.stake * wonRef.odds - wonRef.stake;
            if (profit <= 0) return 100.0;
            final keptRatio = (wonRef.kept / profit).clamp(0.0, 1.0);
            return ((1 - keptRatio) * 100).clamp(0.0, 100.0);
          })()
        : 100.0;
    reinvCtrl = TextEditingController(text: reinvDefault.toStringAsFixed(0));

    // Pre-fill phases from the failed plan
    for (final p in widget.failedPlan.phases) {
      _phases.add(
        _PhaseInput(
          nameCtrl: TextEditingController(text: p.name),
          targetCtrl: TextEditingController(text: p.target.toStringAsFixed(0)),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    startCtrl.dispose();
    targetCtrl.dispose();
    oddsCtrl.dispose();
    reinvCtrl.dispose();
    for (final p in _phases) {
      p.nameCtrl.dispose();
      p.targetCtrl.dispose();
    }
    super.dispose();
  }

  void _addPhase() {
    setState(() {
      _phases.add(
        _PhaseInput(
          nameCtrl: TextEditingController(text: 'Phase ${_phases.length + 1}'),
          targetCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removePhase(int idx) {
    setState(() {
      _phases[idx].nameCtrl.dispose();
      _phases[idx].targetCtrl.dispose();
      _phases.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.ref.read(bettingViewModelProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.refresh, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text('RECOVERY PLAN', style: AppTypography.label),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Failed: ${widget.failedPlan.name}  '
              '(${widget.failedPlan.wonSteps}W / ${widget.failedPlan.lostSteps}L · '
              '${widget.failedPlan.phases.length} phases · '
              '${widget.failedPlan.steps.length} steps)',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            _Field(ctrl: nameCtrl, hint: 'Plan name'),
            const SizedBox(height: 10),
            _Field(
              ctrl: startCtrl,
              hint: 'Starting capital (TZS)',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _Field(
              ctrl: targetCtrl,
              hint: 'Target (TZS)',
              inputType: TextInputType.number,
            ),

            // ── Phases ─────────────────────────────────────────────────────
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'PHASES',
                  style: AppTypography.chip.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(copied from failed plan — edit if needed)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _addPhase,
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'ADD PHASE',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_phases.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'No phases — recovery plan goes straight to final target',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ..._phases.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${e.key + 1}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Field(ctrl: e.value.nameCtrl, hint: 'Phase name'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _Field(
                        ctrl: e.value.targetCtrl,
                        hint: 'Target',
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removePhase(e.key),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Switch(
                  value: useRule,
                  onChanged: (v) => setState(() => useRule = v),
                  activeThumbColor: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-generate steps (rollover)',
                  style: AppTypography.caption,
                ),
              ],
            ),
            if (useRule) ...[
              const SizedBox(height: 4),
              Text(
                'Steps will be regenerated to match the phase targets above.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              _Field(
                ctrl: oddsCtrl,
                hint: 'Odds per bet (e.g. 1.5)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              _Field(
                ctrl: reinvCtrl,
                hint: 'Reinvest % (e.g. 100)',
                inputType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final start = double.tryParse(startCtrl.text.trim());
                  final target = double.tryParse(targetCtrl.text.trim());

                  // Build phases from the editable inputs
                  final phases = _phases
                      .asMap()
                      .entries
                      .map((e) {
                        final t = double.tryParse(
                          e.value.targetCtrl.text.trim(),
                        );
                        return PlanPhase(
                          number: e.key + 1,
                          name: e.value.nameCtrl.text.trim().isNotEmpty
                              ? e.value.nameCtrl.text.trim()
                              : 'Phase ${e.key + 1}',
                          target: t ?? 0,
                        );
                      })
                      .where((p) => p.target > 0)
                      .toList();
                  final effectiveTarget = phases.isEmpty
                      ? target
                      : phases.fold(0.0, (sum, phase) => sum + phase.target);
                  if (name.isEmpty ||
                      start == null ||
                      effectiveTarget == null) {
                    return;
                  }

                  Navigator.pop(context);
                  if (useRule) {
                    final odds = double.tryParse(oddsCtrl.text.trim()) ?? 1.5;
                    final reinv = double.tryParse(reinvCtrl.text.trim()) ?? 100;
                    await vm.createPlanFromRule(
                      name: name,
                      startingCapital: start,
                      targetCapital: effectiveTarget,
                      odds: odds,
                      reinvestPercent: reinv,
                      phases: phases,
                    );
                  } else {
                    await vm.createPlan(
                      name: name,
                      startingCapital: start,
                      targetCapital: effectiveTarget,
                      phases: phases,
                    );
                  }
                },
                child: Text(
                  'START RECOVERY',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit phases sheet ────────────────────────────────────────────────────────
//
// Lets the user add / remove / rename phases on an existing plan — the escape
// hatch for plans that were created without phases and got "stuck on phase 1".

class _EditPhasesSheet extends StatefulWidget {
  final WidgetRef ref;
  final BettingPlan plan;
  const _EditPhasesSheet({required this.ref, required this.plan});

  @override
  State<_EditPhasesSheet> createState() => _EditPhasesSheetState();
}

class _EditPhasesSheetState extends State<_EditPhasesSheet> {
  final List<_PhaseInput> _phases = [];

  @override
  void initState() {
    super.initState();
    for (final p in widget.plan.phases) {
      _phases.add(
        _PhaseInput(
          nameCtrl: TextEditingController(text: p.name),
          targetCtrl: TextEditingController(text: p.target.toStringAsFixed(0)),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final p in _phases) {
      p.nameCtrl.dispose();
      p.targetCtrl.dispose();
    }
    super.dispose();
  }

  void _addPhase() {
    setState(() {
      _phases.add(
        _PhaseInput(
          nameCtrl: TextEditingController(text: 'Phase ${_phases.length + 1}'),
          targetCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removePhase(int index) {
    setState(() {
      final p = _phases.removeAt(index);
      p.nameCtrl.dispose();
      p.targetCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.ref.read(bettingViewModelProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('EDIT PHASES', style: AppTypography.label),
            const SizedBox(height: 4),
            Text(
              widget.plan.name,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            if (_phases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No phases yet. Tap "+ ADD PHASE" to split your plan into stages.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            ..._phases.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${e.key + 1}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Field(ctrl: e.value.nameCtrl, hint: 'Name'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: _Field(
                        ctrl: e.value.targetCtrl,
                        hint: 'Target (TZS)',
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removePhase(e.key),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),
            GestureDetector(
              onTap: _addPhase,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    'ADD PHASE',
                    style: AppTypography.chip.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final phases = _phases
                      .asMap()
                      .entries
                      .map((e) {
                        final t = double.tryParse(
                          e.value.targetCtrl.text.trim(),
                        );
                        return PlanPhase(
                          number: e.key + 1,
                          name: e.value.nameCtrl.text.trim().isNotEmpty
                              ? e.value.nameCtrl.text.trim()
                              : 'Phase ${e.key + 1}',
                          target: t ?? 0,
                        );
                      })
                      .where((p) => p.target > 0)
                      .toList();
                  Navigator.pop(context);
                  await vm.updatePlanPhases(widget.plan.id, phases);
                },
                child: Text(
                  'SAVE',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan header card ─────────────────────────────────────────────────────────

class _PlanHeader extends StatelessWidget {
  final BettingPlan plan;
  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final progress = plan.progressPercent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
              ),
              _StatusBadge(status: plan.status),
            ],
          ),
          const SizedBox(height: 12),

          // Current balance (big) — readable full number so users can see
          // exactly where they stand.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'NOW',
                style: AppTypography.chip.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _fmtFull(plan.currentBalance),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ' TZS',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (plan.totalKept > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${_fmtFull(plan.totalKept)} TZS kept aside',
                style: AppTypography.caption.copyWith(color: AppColors.accent),
              ),
            ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVar,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Effective: ${_fmtFull(plan.effectiveBalance)} TZS',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Target: ${_fmtFull(plan.effectiveTargetCapital)} TZS',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatPill(
                label: 'W',
                value: '${plan.wonSteps}',
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              _StatPill(
                label: 'L',
                value: '${plan.lostSteps}',
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              _StatPill(
                label: 'Steps',
                value: '${plan.steps.length}',
                color: AppColors.textMuted,
              ),
              if (plan.totalKept > 0) ...[
                const SizedBox(width: 6),
                _StatPill(
                  label: 'Kept',
                  value: _fmt(plan.totalKept),
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)}K'
      : v.toStringAsFixed(0);

  /// Full number with thousands separators (e.g. 1,234,567).
  String _fmtFull(double v) {
    final rounded = v.round();
    final s = rounded.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${rounded < 0 ? '-' : ''}$buf';
  }
}

// ── Phases bar ───────────────────────────────────────────────────────────────

class _PhasesBar extends StatelessWidget {
  final BettingPlan plan;
  const _PhasesBar({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: plan.phases.map((phase) {
          final isCurrent = phase.number == plan.currentPhase;
          final phaseTotal = plan.finalBalanceForPhase(phase.number);
          final isReached = phaseTotal >= phase.target;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isReached
                    ? AppColors.success.withValues(alpha: 0.15)
                    : isCurrent
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isCurrent
                    ? Border.all(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 0.5,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    phase.name,
                    style: AppTypography.chip.copyWith(
                      fontSize: 9,
                      color: isReached
                          ? AppColors.success
                          : isCurrent
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtShort(phase.target),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: isReached
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isReached)
                    const Icon(
                      Icons.check_circle,
                      size: 10,
                      color: AppColors.success,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmtShort(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)}K'
      : v.toStringAsFixed(0);
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BettingPlanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BettingPlanStatus.active:
        color = AppColors.accent;
        break;
      case BettingPlanStatus.won:
        color = AppColors.success;
        break;
      case BettingPlanStatus.lost:
        color = AppColors.warning;
        break;
      case BettingPlanStatus.abandoned:
        color = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: AppTypography.chip.copyWith(color: color),
      ),
    );
  }
}

// ── Add step row ──────────────────────────────────────────────────────────────

class _AddStepRow extends StatelessWidget {
  final BettingPlan plan;
  final WidgetRef ref;
  const _AddStepRow({required this.plan, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (!plan.isActive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showAddStepSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              'ADD STEP',
              style: AppTypography.label.copyWith(color: AppColors.accent),
            ),
            const Spacer(),
            if (plan.nextPendingStep != null)
              Text(
                'Next: ${plan.nextPendingStep!.stake.toStringAsFixed(0)} TZS @ ${plan.nextPendingStep!.odds}x',
                style: AppTypography.caption,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddStepSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddStepSheet(plan: plan, ref: ref),
    );
  }
}

class _AddStepSheet extends StatefulWidget {
  final BettingPlan plan;
  final WidgetRef ref;
  const _AddStepSheet({required this.plan, required this.ref});

  @override
  State<_AddStepSheet> createState() => _AddStepSheetState();
}

class _AddStepSheetState extends State<_AddStepSheet> {
  late final TextEditingController stakeCtrl;
  late final TextEditingController oddsCtrl;
  late final TextEditingController keptCtrl;
  late int selectedPhase;

  @override
  void initState() {
    super.initState();
    stakeCtrl = TextEditingController();
    oddsCtrl = TextEditingController();
    keptCtrl = TextEditingController(text: '0');

    // Default phase: whatever the last step was assigned to, or 1.
    selectedPhase = widget.plan.steps.isNotEmpty
        ? widget.plan.steps.last.phase
        : (widget.plan.phases.isNotEmpty ? widget.plan.phases.first.number : 1);

    // Auto-suggest: balance after last won step
    stakeCtrl.text = widget.plan.currentBalance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    stakeCtrl.dispose();
    oddsCtrl.dispose();
    keptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.ref.read(bettingViewModelProvider.notifier);
    final available = widget.plan.currentBalance;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'STEP ${widget.plan.steps.length + 1}',
                  style: AppTypography.label,
                ),
                const Spacer(),
                Text(
                  'Available: ${available.toStringAsFixed(0)} TZS',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Phase picker (if plan has phases) ─────────────────────────
            if (widget.plan.phases.isNotEmpty) ...[
              Text(
                'PHASE',
                style: AppTypography.chip.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.plan.phases.map((p) {
                    final sel = p.number == selectedPhase;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedPhase = p.number),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? AppColors.accent : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            p.name,
                            style: AppTypography.chip.copyWith(
                              color: sel
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            _Field(
              ctrl: keptCtrl,
              hint: 'Keep aside (TZS) — 0 = all in',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _Field(
              ctrl: stakeCtrl,
              hint: 'Stake (TZS)',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _Field(
              ctrl: oddsCtrl,
              hint: 'Odds (e.g. 10)',
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),

            // Auto-calc preview
            ValueListenableBuilder(
              valueListenable: stakeCtrl,
              builder: (_, __, ___) => ValueListenableBuilder(
                valueListenable: oddsCtrl,
                builder: (_, __, ___) => ValueListenableBuilder(
                  valueListenable: keptCtrl,
                  builder: (_, __, ___) {
                    final stake = double.tryParse(stakeCtrl.text.trim()) ?? 0;
                    final odds = double.tryParse(oddsCtrl.text.trim()) ?? 0;
                    final kept = double.tryParse(keptCtrl.text.trim()) ?? 0;
                    final ret = stake * odds;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Return: ${_fmtNum(ret)} TZS${kept > 0 ? ' · Kept: ${_fmtNum(kept)} TZS' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final stake = double.tryParse(stakeCtrl.text.trim());
                  final odds = double.tryParse(oddsCtrl.text.trim());
                  final kept = double.tryParse(keptCtrl.text.trim()) ?? 0;
                  if (stake == null || odds == null) return;
                  Navigator.pop(context);
                  await vm.addStepToPlan(
                    stake: stake,
                    odds: odds,
                    kept: kept,
                    phase: selectedPhase,
                  );
                },
                child: Text(
                  'ADD STEP',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtNum(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : v.toStringAsFixed(0);
}

// ── Steps table ───────────────────────────────────────────────────────────────

class _StepsTable extends StatelessWidget {
  final BettingPlan plan;
  final BettingViewModel vm;
  const _StepsTable({required this.plan, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (plan.steps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No steps yet. Add your first bet above.',
          style: AppTypography.caption,
        ),
      );
    }

    // Group steps by phase for display.
    final byPhase = <int, List<BettingPlanStep>>{};
    for (final s in plan.steps) {
      byPhase.putIfAbsent(s.phase, () => []).add(s);
    }
    final phaseNumbers = byPhase.keys.toList()..sort();
    final totals = plan.phaseTotals;

    String phaseLabel(int n) {
      final p = plan.phases.where((e) => e.number == n);
      return p.isNotEmpty ? p.first.name : 'Phase $n';
    }

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _Col(text: '#', flex: 1, header: true),
              _Col(text: 'STAKE', flex: 3, header: true),
              _Col(text: 'ODDS', flex: 2, header: true),
              _Col(text: 'KEPT', flex: 2, header: true),
              _Col(text: 'RETURN', flex: 3, header: true),
              _Col(text: '', flex: 3, header: true, align: TextAlign.right),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),

        // Phase-grouped rows with per-phase subtotal.
        ...phaseNumbers.expand((n) {
          final phaseSteps = byPhase[n]!;
          final phaseTotal = totals[n] ?? 0;
          return [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 4,
                left: 4,
                right: 4,
              ),
              child: Row(
                children: [
                  Text(
                    phaseLabel(n).toUpperCase(),
                    style: AppTypography.chip.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${phaseTotal >= 0 ? '+' : ''}${_fmtSigned(phaseTotal)} TZS',
                    style: AppTypography.caption.copyWith(
                      color: phaseTotal >= 0
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            ...phaseSteps.map(
              (step) => _StepRow(
                step: step,
                planId: plan.id,
                vm: vm,
                planActive: plan.isActive,
              ),
            ),
          ];
        }),

        // ── Grand total banner ──
        if (plan.steps.any((s) => s.status != BettingPlanStepStatus.pending))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: plan.plannedNet >= 0
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.warning.withValues(alpha: 0.4),
                  width: 0.6,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PLAN TOTAL',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${plan.plannedNet >= 0 ? '+' : ''}${_fmtSigned(plan.plannedNet)} TZS',
                        style: AppTypography.h3.copyWith(
                          color: plan.plannedNet >= 0
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance ${_fmtSigned(plan.currentBalance)} · Kept ${_fmtSigned(plan.totalKept)} · Start ${_fmtSigned(plan.startingCapital)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _fmtSigned(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(0)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}

class _StepRow extends StatelessWidget {
  final BettingPlanStep step;
  final String planId;
  final BettingViewModel vm;
  final bool planActive;
  const _StepRow({
    required this.step,
    required this.planId,
    required this.vm,
    required this.planActive,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = step.status == BettingPlanStepStatus.pending;
    final isWon = step.status == BettingPlanStepStatus.won;

    Color rowColor = Colors.transparent;
    if (isWon) {
      rowColor = AppColors.success.withValues(alpha: 0.05);
    }
    if (step.status == BettingPlanStepStatus.lost) {
      rowColor = AppColors.warning.withValues(alpha: 0.05);
    }

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          _Col(text: '${step.step}', flex: 1),
          _Col(text: _fmt(step.stake), flex: 3),
          _Col(text: '${step.odds}x', flex: 2),
          _Col(
            text: step.kept > 0 ? _fmt(step.kept) : '-',
            flex: 2,
            color: step.kept > 0 ? AppColors.accent : AppColors.textMuted,
          ),
          _Col(text: _fmt(step.potentialReturn), flex: 3),
          Expanded(
            flex: 3,
            child: isPending && planActive
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _MiniBtn(
                        label: 'W',
                        color: AppColors.success,
                        onTap: () => vm.settlePlanStep(
                          planId,
                          step.step,
                          BettingPlanStepStatus.won,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _MiniBtn(
                        label: 'L',
                        color: AppColors.warning,
                        onTap: () => vm.settlePlanStep(
                          planId,
                          step.step,
                          BettingPlanStepStatus.lost,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      isPending ? '-' : step.status.label,
                      style: AppTypography.chip.copyWith(
                        color: isWon
                            ? AppColors.success
                            : isPending
                            ? AppColors.textMuted
                            : AppColors.warning,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : v.toStringAsFixed(0);
}

// ── Plan summary card (aggregate stats for past plans) ───────────────────────

class _PlanSummaryCard extends StatelessWidget {
  final List<BettingPlan> plans;
  const _PlanSummaryCard({required this.plans});

  @override
  Widget build(BuildContext context) {
    final wonPlans = plans
        .where((p) => p.status == BettingPlanStatus.won)
        .length;
    final lostPlans = plans
        .where((p) => p.status == BettingPlanStatus.lost)
        .length;
    final totalKept = plans.fold(0.0, (s, p) => s + p.totalKept);
    final totalNet = plans.fold(0.0, (s, p) => s + p.netProfit);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'WON',
            value: '$wonPlans',
            color: AppColors.success,
          ),
          _SummaryItem(
            label: 'LOST',
            value: '$lostPlans',
            color: AppColors.warning,
          ),
          _SummaryItem(
            label: 'KEPT',
            value: _fmtShort(totalKept),
            color: AppColors.accent,
          ),
          _SummaryItem(
            label: 'NET',
            value: '${totalNet >= 0 ? '+' : ''}${_fmtShort(totalNet)}',
            color: totalNet >= 0 ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    );
  }

  String _fmtShort(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(0)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h3.copyWith(color: color, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.chip.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.route_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text('No active plan', style: AppTypography.body),
            const SizedBox(height: 4),
            Text(
              'Tap NEW PLAN to define your road to target',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Past plan tile ────────────────────────────────────────────────────────────

class _PastPlanTile extends StatelessWidget {
  final BettingPlan plan;
  final VoidCallback onDelete;
  const _PastPlanTile({required this.plan, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final netColor = plan.netProfit >= 0
        ? AppColors.success
        : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _StatusBadge(status: plan.status),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: AppTypography.body),
                Text(
                  'Final: ${_fmt(plan.effectiveBalance)} / ${_fmt(plan.targetCapital)} TZS',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${plan.wonSteps}W/${plan.lostSteps}L',
                      style: AppTypography.caption,
                    ),
                    if (plan.totalKept > 0) ...[
                      Text(
                        ' · Kept ${_fmt(plan.totalKept)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                    Text(' · Net ', style: AppTypography.caption),
                    Text(
                      '${plan.netProfit >= 0 ? '+' : ''}${_fmt(plan.netProfit)}',
                      style: AppTypography.caption.copyWith(color: netColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.textMuted,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(0)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  final TextAlign align;
  final Color? color;
  const _Col({
    required this.text,
    this.flex = 1,
    this.header = false,
    this.align = TextAlign.left,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: header
            ? AppTypography.chip.copyWith(color: AppColors.textMuted)
            : AppTypography.caption.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(color: color, fontSize: 10),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.chip.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(color: AppColors.accent),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType inputType;
  const _Field({
    required this.ctrl,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
