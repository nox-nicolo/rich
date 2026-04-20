// lib/feature/finance/view/pages/add_expense_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';
import '../widgets/finance_form_widgets.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  FinanceCategory _category = FinanceCategory.general;
  PaymentMethod?  _method;
  DateTime        _date     = DateTime.now();
  bool            _saving   = false;

  @override
  void dispose() {
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
      await ref.read(financeViewModelProvider.notifier).addExpense(
        title:         _titleCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        category:      _category,
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
        title: Text('ADD EXPENSE', style: AppTypography.label.copyWith(fontSize: 12)),
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
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.warning))
                  : Text('SAVE',
                      style: AppTypography.label.copyWith(color: AppColors.warning)),
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded,
                        color: AppColors.warning, size: AppSpacing.iconMd),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Recording an expense reduces your account balance.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FinanceField(
                label: 'TITLE',
                controller: _titleCtrl,
                hintText: 'e.g. Groceries',
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

              FinanceDropdownField<FinanceCategory>(
                label: 'ACCOUNT CATEGORY',
                value: _category,
                items: FinanceCategory.values,
                itemLabel: (c) => c.label,
                onChanged: (c) => setState(() => _category = c!),
              ),
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
                label: 'VENDOR (optional)',
                controller: _vendorCtrl,
                hintText: 'e.g. Restaurant Name',
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'DESCRIPTION (optional)',
                controller: _descCtrl,
                hintText: 'Brief description',
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
