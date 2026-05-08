// lib/feature/finance/view/pages/budget_allocations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';
import '../widgets/finance_form_widgets.dart';

class BudgetAllocationsPage extends ConsumerStatefulWidget {
  const BudgetAllocationsPage({super.key});

  @override
  ConsumerState<BudgetAllocationsPage> createState() =>
      _BudgetAllocationsPageState();
}

class _BudgetAllocationsPageState
    extends ConsumerState<BudgetAllocationsPage> {
  /// Derive daily / weekly / monthly from one base amount.
  static Map<FinancePeriod, double> _computeAllPeriods(
      FinancePeriod base, double amount) {
    late double daily, weekly, monthly;
    switch (base) {
      case FinancePeriod.daily:
        daily = amount;
        weekly = amount * 7;
        monthly = amount * 30;
      case FinancePeriod.weekly:
        daily = amount / 7;
        weekly = amount;
        monthly = amount * 30 / 7;
      case FinancePeriod.monthly:
        daily = amount / 30;
        weekly = amount * 7 / 30;
        monthly = amount;
      case FinancePeriod.yearly:
        daily = amount / 365;
        weekly = amount / 52;
        monthly = amount / 12;
    }
    return {
      FinancePeriod.daily: double.parse(daily.toStringAsFixed(2)),
      FinancePeriod.weekly: double.parse(weekly.toStringAsFixed(2)),
      FinancePeriod.monthly: double.parse(monthly.toStringAsFixed(2)),
    };
  }

  DateTime _periodStart(FinancePeriod period, DateTime now) {
    switch (period) {
      case FinancePeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case FinancePeriod.weekly:
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
      case FinancePeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case FinancePeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _periodEnd(FinancePeriod period, DateTime now) {
    switch (period) {
      case FinancePeriod.daily:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case FinancePeriod.weekly:
        return _periodStart(period, now).add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case FinancePeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case FinancePeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

  Future<void> _saveAllPeriods({
    required FinanceCategory cat,
    required FinancePeriod base,
    required double amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final computed = _computeAllPeriods(base, amount);
    for (final entry in computed.entries) {
      if (entry.value <= 0) continue;
      await ref.read(financeViewModelProvider.notifier).saveAllocation(
            BudgetAllocation(
              id: const Uuid().v4(),
              category: cat,
              period: entry.key,
              startDate: _periodStart(entry.key, now),
              endDate: _periodEnd(entry.key, now),
              allocatedAmount: entry.value,
              note: note,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('BUDGET ALLOCATIONS',
            style: AppTypography.label.copyWith(fontSize: 12)),
        leading: IconButton(
          icon: const Icon(Icons.close,
              size: AppSpacing.iconMd, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: FinanceCategory.values.map((cat) {
          // Saved allocations per period
          final allocMap = <FinancePeriod, BudgetAllocation?>{};
          for (final p in [
            FinancePeriod.daily,
            FinancePeriod.weekly,
            FinancePeriod.monthly,
          ]) {
            final list = state.allocations
                .where((a) => a.category == cat && a.period == p)
                .toList()
              ..sort((a, b) => b.startDate.compareTo(a.startDate));
            allocMap[p] = list.isNotEmpty ? list.first : null;
          }

          final account = state.accountFor(cat);
          final hasAny = allocMap.values.any((a) => a != null);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _AllocationCard(
              category: cat,
              account: account,
              allocations: allocMap,
              hasAny: hasAny,
              onApply: (base, amount, note) =>
                  _saveAllPeriods(cat: cat, base: base, amount: amount, note: note),
              onDeleteAll: hasAny
                  ? () async {
                      for (final a in allocMap.values) {
                        if (a != null) {
                          await ref
                              .read(financeViewModelProvider.notifier)
                              .deleteAllocation(a.id);
                        }
                      }
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Allocation Card ───────────────────────────────────────────────────────────

class _AllocationCard extends StatefulWidget {
  final FinanceCategory category;
  final FinanceAccount? account;
  final Map<FinancePeriod, BudgetAllocation?> allocations;
  final bool hasAny;
  final Future<void> Function(FinancePeriod base, double amount, String? note)
      onApply;
  final Future<void> Function()? onDeleteAll;

  const _AllocationCard({
    required this.category,
    required this.account,
    required this.allocations,
    required this.hasAny,
    required this.onApply,
    this.onDeleteAll,
  });

  @override
  State<_AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<_AllocationCard> {
  // Manual-override mode only
  bool _manualEdit = false;
  bool _saving = false;
  FinancePeriod _basePeriod = FinancePeriod.monthly;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() => setState(() {});

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _balance => widget.account?.currentBalance ?? 0;

  Map<FinancePeriod, double> get _autoBreakdown =>
      _BudgetAllocationsPageState._computeAllPeriods(
          FinancePeriod.monthly, _balance);

  Map<FinancePeriod, double> get _manualPreview {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return _BudgetAllocationsPageState._computeAllPeriods(_basePeriod, amount);
  }

  void _openManualEdit() {
    // Pre-fill from saved allocation or from balance
    final existing = widget.allocations[FinancePeriod.monthly] ??
        widget.allocations[FinancePeriod.weekly] ??
        widget.allocations[FinancePeriod.daily];
    if (existing != null) {
      _basePeriod = existing.period;
      _amountCtrl.text = existing.allocatedAmount.toStringAsFixed(0);
      _noteCtrl.text = existing.note ?? '';
    } else if (_balance > 0) {
      _basePeriod = FinancePeriod.monthly;
      _amountCtrl.text = _balance.toStringAsFixed(0);
      _noteCtrl.text = '';
    } else {
      _amountCtrl.text = '';
      _noteCtrl.text = '';
    }
    setState(() => _manualEdit = true);
  }

  @override
  Widget build(BuildContext context) {
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
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Text(widget.category.label.toUpperCase(),
                  style: AppTypography.label),
              const Spacer(),
              if (!_manualEdit) ...[
                if (widget.hasAny && widget.onDeleteAll != null)
                  GestureDetector(
                    onTap: widget.onDeleteAll,
                    child: Text('CLEAR',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.warning)),
                  ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: _openManualEdit,
                  child: Text('EDIT',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () => setState(() => _manualEdit = false),
                  child: Text('CANCEL',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (!_manualEdit)
            // ── Auto display ─────────────────────────────────────────────────
            _AutoDisplay(
              balance: _balance,
              breakdown: _balance > 0 ? _autoBreakdown : null,
              savedAllocations: widget.hasAny ? widget.allocations : null,
              onApply: _balance > 0 && !widget.hasAny
                  ? () async {
                      setState(() => _saving = true);
                      await widget.onApply(
                          FinancePeriod.monthly, _balance, null);
                      if (mounted) setState(() => _saving = false);
                    }
                  : null,
              saving: _saving,
            )
          else
            // ── Manual override ──────────────────────────────────────────────
            _ManualEditForm(
              amountCtrl: _amountCtrl,
              noteCtrl: _noteCtrl,
              basePeriod: _basePeriod,
              preview: _manualPreview,
              saving: _saving,
              onPeriodChanged: (p) => setState(() => _basePeriod = p),
              onSave: () async {
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                setState(() => _saving = true);
                await widget.onApply(
                    _basePeriod, amount, _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim());
                if (mounted) {
                  setState(() {
                    _saving = false;
                    _manualEdit = false;
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}

// ── Auto display ──────────────────────────────────────────────────────────────

class _AutoDisplay extends StatelessWidget {
  final double balance;
  final Map<FinancePeriod, double>? breakdown;
  final Map<FinancePeriod, BudgetAllocation?>? savedAllocations;
  final VoidCallback? onApply;
  final bool saving;

  const _AutoDisplay({
    required this.balance,
    required this.breakdown,
    required this.savedAllocations,
    required this.onApply,
    required this.saving,
  });

  static const _periods = [
    FinancePeriod.daily,
    FinancePeriod.weekly,
    FinancePeriod.monthly,
  ];

  @override
  Widget build(BuildContext context) {
    // Prefer saved allocations for display; fall back to auto-computed
    final hasSaved = savedAllocations != null &&
        savedAllocations!.values.any((a) => a != null);

    if (balance <= 0 && !hasSaved) {
      return Text('No funds in this section yet.',
          style: AppTypography.body.copyWith(color: AppColors.textMuted));
    }

    final amounts = <FinancePeriod, double>{};
    for (final p in _periods) {
      if (hasSaved) {
        amounts[p] = savedAllocations![p]?.allocatedAmount ?? 0;
      } else {
        amounts[p] = breakdown?[p] ?? 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasSaved)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'AUTO — from TZS ${_fmt(balance)} balance',
              style: AppTypography.chip.copyWith(
                color: AppColors.textMuted,
                fontSize: 9,
              ),
            ),
          ),
        Row(
          children: _periods.map((p) {
            final val = amounts[p] ?? 0;
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.label.toUpperCase(),
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    val > 0 ? 'TZS ${_fmt(val)}' : '—',
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: val > 0
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (onApply != null) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: saving ? null : onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 0.5),
              ),
              child: saving
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5))
                  : Text(
                      'APPLY BUDGET',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Manual override form ──────────────────────────────────────────────────────

class _ManualEditForm extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final FinancePeriod basePeriod;
  final Map<FinancePeriod, double> preview;
  final bool saving;
  final void Function(FinancePeriod) onPeriodChanged;
  final Future<void> Function() onSave;

  const _ManualEditForm({
    required this.amountCtrl,
    required this.noteCtrl,
    required this.basePeriod,
    required this.preview,
    required this.saving,
    required this.onPeriodChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    const periods = [
      FinancePeriod.daily,
      FinancePeriod.weekly,
      FinancePeriod.monthly,
    ];
    final previewAmount = preview.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: periods.map((p) {
              final sel = basePeriod == p;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => onPeriodChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: sel
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      p.label.toUpperCase(),
                      style: AppTypography.chip.copyWith(
                        color: sel
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FinanceField(
          label: 'AMOUNT (TZS)',
          controller: amountCtrl,
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (previewAmount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _PreviewRow(preview: preview, basePeriod: basePeriod),
        ],
        const SizedBox(height: AppSpacing.sm),
        FinanceField(
          label: 'NOTE (optional)',
          controller: noteCtrl,
          hintText: 'Purpose of this budget',
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5))
                : Text('SAVE',
                    style: AppTypography.label
                        .copyWith(color: AppColors.success)),
          ),
        ),
      ],
    );
  }
}

// ── Preview row (manual edit) ─────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  final Map<FinancePeriod, double> preview;
  final FinancePeriod basePeriod;

  const _PreviewRow({required this.preview, required this.basePeriod});

  @override
  Widget build(BuildContext context) {
    const periods = [
      FinancePeriod.daily,
      FinancePeriod.weekly,
      FinancePeriod.monthly,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: periods.map((p) {
          final isBase = p == basePeriod;
          final val = preview[p] ?? 0;
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.label.toUpperCase(),
                  style: AppTypography.chip.copyWith(
                    color:
                        isBase ? AppColors.accent : AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'TZS ${_fmt(val)}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: isBase
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
