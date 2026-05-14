// lib/feature/trading/view/widget/growth_plan_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/trading_growth_plan_model.dart';
import '../../viewmodel/trading_viewmodel.dart';

class GrowthPlanWidget extends ConsumerWidget {
  const GrowthPlanWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingViewModelProvider);
    final vm = ref.read(tradingViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'DAILY GROWTH PLAN',
                style: AppTypography.label.copyWith(letterSpacing: 2),
              ),
            ),
            _ActionButton(
              label: 'NEW PLAN',
              onTap: () => _showCreateSheet(context, ref),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        if (state.activeGrowthPlan != null) ...[
          _PlanHeader(plan: state.activeGrowthPlan!),
          const SizedBox(height: AppSpacing.md),
          if (state.activeGrowthPlan!.isComplete) ...[
            _CompleteCard(
              plan: state.activeGrowthPlan!,
              onNewPlan: () => _showCreateSheet(
                context,
                ref,
                seedCapital: state.activeGrowthPlan!.currentCapital,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else if (state.activeGrowthPlan!.isBroken) ...[
            _BrokenPlanBanner(
              plan: state.activeGrowthPlan!,
              onNewPlan: () => _showCreateSheet(
                context,
                ref,
                seedCapital: state.activeGrowthPlan!.currentCapital,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _DaysTable(plan: state.activeGrowthPlan!, vm: vm),
        ] else ...[
          _EmptyCard(onTap: () => _showCreateSheet(context, ref)),
        ],

        if (state.growthPlans.where((p) => !p.isActive).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'PAST PLANS',
            style: AppTypography.chip.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...state.growthPlans
              .where((p) => !p.isActive)
              .map(
                (p) => _PastTile(
                  plan: p,
                  onDelete: () => vm.deleteGrowthPlan(p.id),
                ),
              ),
        ],
      ],
    );
  }

  void _showCreateSheet(
    BuildContext context,
    WidgetRef ref, {
    double? seedCapital,
  }) {
    final vm = ref.read(tradingViewModelProvider.notifier);
    final state = ref.read(tradingViewModelProvider);
    final nameCtrl = TextEditingController(text: 'Growth Plan');
    final initialCapital = seedCapital ?? state.startingCapital;
    final startCtrl = TextEditingController(
      text: initialCapital > 0 ? initialCapital.toStringAsFixed(2) : '',
    );
    final targetCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '25');
    final daysCtrl = TextEditingController(text: '30');
    final slCtrl = TextEditingController(text: '2');
    final activeTargetLot = state.activeTarget?.lotSize;
    final lotCtrl = TextEditingController(
      text: activeTargetLot != null ? activeTargetLot.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
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
              Text('CREATE GROWTH PLAN', style: AppTypography.label),
              const SizedBox(height: 16),
              _Field(ctrl: nameCtrl, hint: 'Plan name'),
              const SizedBox(height: 10),
              _Field(
                ctrl: startCtrl,
                hint: 'Starting capital (USD)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _Field(
                ctrl: targetCtrl,
                hint: 'Target capital (USD)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _Field(
                ctrl: rateCtrl,
                hint: 'Daily growth % (e.g. 25)',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _Field(
                ctrl: daysCtrl,
                hint: 'Number of days (e.g. 30)',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _Field(
                ctrl: slCtrl,
                hint: 'Max SL per step % (e.g. 2)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _Field(
                ctrl: lotCtrl,
                hint: 'Starting lot size (uses active target if set)',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
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
                    final rate = double.tryParse(rateCtrl.text.trim());
                    final days = int.tryParse(daysCtrl.text.trim());
                    final sl = double.tryParse(slCtrl.text.trim()) ?? 2.0;
                    final lot = double.tryParse(lotCtrl.text.trim());
                    if (name.isEmpty ||
                        start == null ||
                        target == null ||
                        rate == null ||
                        days == null) {
                      return;
                    }
                    Navigator.pop(ctx);
                    await vm.createGrowthPlan(
                      name: name,
                      startingCapital: start,
                      targetCapital: target,
                      dailyGrowthPercent: rate,
                      totalDays: days,
                      stopLossPercent: sl,
                      startingLotSize: lot,
                    );
                  },
                  child: Text(
                    'GENERATE PLAN',
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
      ),
    );
  }
}

// ── Plan header ───────────────────────────────────────────────────────────────

class _PlanHeader extends StatelessWidget {
  final TradingGrowthPlan plan;
  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
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
              Text(
                '${plan.dailyGrowthPercent.toStringAsFixed(0)}%/day · SL ${plan.stopLossPercent.toStringAsFixed(0)}%',
                style: AppTypography.chip.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: plan.progressPercent,
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
                'Day ${plan.completedDays}/${plan.totalDays}',
                style: AppTypography.caption,
              ),
              Text(
                '\$${plan.startingCapital.toStringAsFixed(2)} → \$${plan.targetCapital.toStringAsFixed(2)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Days table ────────────────────────────────────────────────────────────────

class _DaysTable extends StatelessWidget {
  final TradingGrowthPlan plan;
  final TradingViewModel vm;
  const _DaysTable({required this.plan, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVar,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _H(text: 'DAY', flex: 1),
              _H(text: 'START', flex: 3),
              _H(text: 'TARGET', flex: 2),
              _H(text: 'SL', flex: 2),
              _H(text: 'END', flex: 3),
              _H(text: 'LOT', flex: 2),
              _H(text: '', flex: 3),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...plan.days.map((day) => _DayRow(day: day, planId: plan.id, vm: vm)),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final GrowthPlanDay day;
  final String planId;
  final TradingViewModel vm;
  const _DayRow({required this.day, required this.planId, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isPending = day.status == GrowthDayStatus.pending;
    final isDone = day.status == GrowthDayStatus.completed;
    final isMissed = day.status == GrowthDayStatus.missed;

    Color bg = Colors.transparent;
    if (isDone) bg = AppColors.success.withValues(alpha: 0.05);
    if (isMissed) bg = AppColors.warning.withValues(alpha: 0.05);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          _C(
            text: '${day.day}',
            flex: 1,
            color: isPending ? AppColors.textSecondary : AppColors.textMuted,
          ),
          _C(text: '\$${_fmt(day.startBalance)}', flex: 3),
          _C(
            text: '\$${_fmt(day.dailyTarget)}',
            flex: 2,
            color: AppColors.accent.withValues(alpha: 0.8),
          ),
          _C(
            text: '-\$${_fmt(day.stopLoss)}',
            flex: 2,
            color: AppColors.warning.withValues(alpha: 0.8),
          ),
          _C(text: '\$${_fmt(day.expectedEnd)}', flex: 3),
          _C(text: day.lotSize, flex: 2, color: AppColors.textMuted),
          Expanded(
            flex: 3,
            child: isPending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Btn(
                        label: '✓',
                        color: AppColors.success,
                        onTap: () => vm.markGrowthDay(
                          planId,
                          day.day,
                          GrowthDayStatus.completed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _Btn(
                        label: '✗',
                        color: AppColors.warning,
                        onTap: () => vm.markGrowthDay(
                          planId,
                          day.day,
                          GrowthDayStatus.missed,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      day.status.label,
                      style: AppTypography.chip.copyWith(
                        fontSize: 10,
                        color: isDone ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

// ── Broken plan banner ───────────────────────────────────────────────────────

class _BrokenPlanBanner extends StatelessWidget {
  final TradingGrowthPlan plan;
  final VoidCallback onNewPlan;
  const _BrokenPlanBanner({required this.plan, required this.onNewPlan});

  @override
  Widget build(BuildContext context) {
    final firstMissed = plan.days.firstWhere(
      (d) => d.status == GrowthDayStatus.missed,
    );
    final loss = firstMissed.stopLoss;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'PLAN BROKEN',
                style: AppTypography.label.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Day ${firstMissed.day} hit SL (-\$${loss.toStringAsFixed(2)}). '
            'Capital is now ~\$${plan.currentCapital.toStringAsFixed(2)}, so the '
            'remaining target table no longer matches reality. Recalibrate '
            'with a new plan from current capital.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNewPlan,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppColors.warning,
              ),
              label: Text(
                'RECALIBRATE — NEW PLAN',
                style: AppTypography.chip.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning, width: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan complete card ───────────────────────────────────────────────────────

class _CompleteCard extends StatelessWidget {
  final TradingGrowthPlan plan;
  final VoidCallback onNewPlan;
  const _CompleteCard({required this.plan, required this.onNewPlan});

  @override
  Widget build(BuildContext context) {
    final reached = plan.currentCapital;
    final gain = reached - plan.startingCapital;
    final pct = plan.startingCapital > 0
        ? (gain / plan.startingCapital) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                'PLAN COMPLETE',
                style: AppTypography.label.copyWith(
                  color: AppColors.success,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All ${plan.totalDays} days marked done. '
            'Capital: \$${plan.startingCapital.toStringAsFixed(2)} → '
            '\$${reached.toStringAsFixed(2)} '
            '(${gain >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%). '
            'Set a new target to keep compounding.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewPlan,
              icon: const Icon(Icons.trending_up, size: 16),
              label: Text(
                'START NEW PLAN',
                style: AppTypography.chip.copyWith(
                  color: AppColors.background,
                  letterSpacing: 2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyCard({required this.onTap});

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
              Icons.trending_up_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text('No growth plan active', style: AppTypography.body),
            const SizedBox(height: 4),
            Text(
              'Tap NEW PLAN to build your daily goal table',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Past plan tile ────────────────────────────────────────────────────────────

class _PastTile extends StatelessWidget {
  final TradingGrowthPlan plan;
  final VoidCallback onDelete;
  const _PastTile({required this.plan, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: AppTypography.body),
                Text(
                  '${plan.completedDays}/${plan.totalDays} days · ${plan.dailyGrowthPercent.toStringAsFixed(0)}%/day',
                  style: AppTypography.caption,
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _H extends StatelessWidget {
  final String text;
  final int flex;
  const _H({required this.text, this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: AppTypography.chip.copyWith(
        color: AppColors.textMuted,
        fontSize: 9,
      ),
    ),
  );
}

class _C extends StatelessWidget {
  final String text;
  final int flex;
  final Color? color;
  const _C({required this.text, this.flex = 1, this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: AppTypography.caption.copyWith(
        color: color ?? AppColors.textSecondary,
        fontSize: 11,
      ),
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
        style: AppTypography.chip.copyWith(color: color, fontSize: 11),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: inputType,
    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(hintText: hint),
  );
}
