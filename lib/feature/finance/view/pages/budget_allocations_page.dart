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
  FinancePeriod _period = FinancePeriod.monthly;

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
        return _periodStart(period, now)
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case FinancePeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case FinancePeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FinancePeriod.values.map((p) {
                  final selected = _period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.5)
                                : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          p.label.toUpperCase(),
                          style: AppTypography.chip.copyWith(
                            color: selected
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
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: FinanceCategory.values.map((cat) {
                final allocs = state.allocations
                    .where((a) =>
                        a.category == cat && a.period == _period)
                    .toList()
                  ..sort((a, b) => b.startDate.compareTo(a.startDate));
                final current = allocs.isNotEmpty ? allocs.first : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AllocationCard(
                    category:          cat,
                    period:            _period,
                    currentAllocation: current,
                    onSave: (amount, note) async {
                      final now   = DateTime.now();
                      final start = _periodStart(_period, now);
                      final end   = _periodEnd(_period, now);
                      final newAlloc = BudgetAllocation(
                        id:              const Uuid().v4(),
                        category:        cat,
                        period:          _period,
                        startDate:       start,
                        endDate:         end,
                        allocatedAmount: amount,
                        note:            note.isEmpty ? null : note,
                        createdAt:       now,
                        updatedAt:       now,
                      );
                      await ref
                          .read(financeViewModelProvider.notifier)
                          .saveAllocation(newAlloc);
                    },
                    onDelete: current != null
                        ? () async {
                            await ref
                                .read(financeViewModelProvider.notifier)
                                .deleteAllocation(current.id);
                          }
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Allocation Card ───────────────────────────────────────────────────────────

class _AllocationCard extends StatefulWidget {
  final FinanceCategory category;
  final FinancePeriod period;
  final BudgetAllocation? currentAllocation;
  final Future<void> Function(double amount, String note) onSave;
  final Future<void> Function()? onDelete;

  const _AllocationCard({
    required this.category,
    required this.period,
    required this.currentAllocation,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<_AllocationCard> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  bool _editing = false;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.currentAllocation?.allocatedAmount.toStringAsFixed(0) ?? '');
    _noteCtrl =
        TextEditingController(text: widget.currentAllocation?.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alloc = widget.currentAllocation;
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
              Text(widget.category.label.toUpperCase(),
                  style: AppTypography.label),
              const Spacer(),
              if (!_editing)
                GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Text('EDIT',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              if (_editing && widget.onDelete != null) ...[
                GestureDetector(
                  onTap: () async {
                    await widget.onDelete!();
                    if (mounted) {
                      setState(() {
                        _editing = false;
                        _amountCtrl.text = '';
                      });
                    }
                  },
                  child: Text('CLEAR',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.warning)),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_editing) ...[
            if (alloc != null)
              Text(
                'TZS ${alloc.allocatedAmount.toStringAsFixed(0)} / ${widget.period.label}',
                style: AppTypography.h3.copyWith(fontSize: 14),
              )
            else
              Text('No allocation set', style: AppTypography.body),
          ] else ...[
            FinanceField(
              label: 'AMOUNT (TZS)',
              controller: _amountCtrl,
              hintText: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinanceField(
              label: 'NOTE (optional)',
              controller: _noteCtrl,
              hintText: 'Purpose of this budget',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('CANCEL', style: AppTypography.caption),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(_amountCtrl.text.trim());
                          if (amount == null || amount <= 0) return;
                          setState(() => _saving = true);
                          await widget.onSave(
                              amount, _noteCtrl.text.trim());
                          if (mounted) {
                            setState(() {
                              _saving  = false;
                              _editing = false;
                            });
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5))
                      : Text('SAVE',
                          style: AppTypography.label
                              .copyWith(color: AppColors.success)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
