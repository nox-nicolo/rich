// lib/feature/finance/view/pages/add_income_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';
import '../widgets/finance_form_widgets.dart';

class AddIncomePage extends ConsumerStatefulWidget {
  const AddIncomePage({super.key});

  @override
  ConsumerState<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends ConsumerState<AddIncomePage> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  PaymentMethod?  _method;
  DateTime        _date     = DateTime.now();
  bool            _saving   = false;

  @override
  void initState() {
    super.initState();
    // Live-update the split preview as the user types.
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _vendorCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(financeViewModelProvider.notifier).addIncomeSplit(
        title:         _titleCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        amount:        double.parse(_amountCtrl.text.trim()),
        date:          _date,
        paymentMethod: _method,
        vendor:        _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
        note:          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('ADD INCOME', style: AppTypography.label.copyWith(fontSize: 12)),
        leading: IconButton(
          icon: const Icon(Icons.close, size: AppSpacing.iconMd, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.success))
                  : Text('SAVE',
                      style: AppTypography.label.copyWith(color: AppColors.success)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info header
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded,
                        color: AppColors.success, size: AppSpacing.iconMd),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Income is automatically split across all five buckets '
                        '— see the preview below.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FinanceField(
                label: 'TITLE',
                controller: _titleCtrl,
                hintText: 'e.g. Salary Payment',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'AMOUNT (TZS)',
                controller: _amountCtrl,
                hintText: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              _SplitPreview(amountText: _amountCtrl.text),
              const SizedBox(height: AppSpacing.md),

              FinanceDropdownField<PaymentMethod?>(
                label: 'PAYMENT METHOD',
                value: _method,
                items: [null, ...PaymentMethod.values],
                itemLabel: (m) => m?.label ?? 'Not specified',
                onChanged: (m) => setState(() => _method = m),
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceDateField(label: 'DATE', date: _date, onTap: _pickDate),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'SOURCE / VENDOR (optional)',
                controller: _vendorCtrl,
                hintText: 'e.g. Company Name',
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'DESCRIPTION (optional)',
                controller: _descCtrl,
                hintText: 'Short description',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'NOTE (optional)',
                controller: _noteCtrl,
                hintText: 'Any additional notes',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.x3l),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitPreview extends StatelessWidget {
  final String amountText;
  const _SplitPreview({required this.amountText});

  @override
  Widget build(BuildContext context) {
    final parsed = double.tryParse(amountText.trim()) ?? 0;
    final splits = FinanceViewModel.computeIncomeSplit(parsed);
    final percent = FinanceViewModel.incomeSplitPercent;

    // Render in the same order as the percentage map so the list feels stable.
    final rows = percent.keys.map((cat) {
      final pct    = (percent[cat]! * 100).toStringAsFixed(0);
      final amount = splits[cat] ?? 0;
      return _SplitRow(label: cat.label, percent: pct, amount: amount);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AUTO SPLIT', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  final String label;
  final String percent;
  final double amount;
  const _SplitRow({
    required this.label,
    required this.percent,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$percent%',
                style: AppTypography.mono.copyWith(color: AppColors.textMuted)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
          ),
          Text(amount.toStringAsFixed(2),
              style: AppTypography.mono.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}
