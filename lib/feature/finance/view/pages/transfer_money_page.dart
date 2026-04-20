// lib/feature/finance/view/pages/transfer_money_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';
import '../widgets/finance_form_widgets.dart';

class TransferMoneyPage extends ConsumerStatefulWidget {
  const TransferMoneyPage({super.key});

  @override
  ConsumerState<TransferMoneyPage> createState() => _TransferMoneyPageState();
}

class _TransferMoneyPageState extends ConsumerState<TransferMoneyPage> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  FinanceCategory _from   = FinanceCategory.general;
  FinanceCategory _to     = FinanceCategory.saving;
  DateTime        _date   = DateTime.now();
  bool            _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
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
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination cannot be the same.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(financeViewModelProvider.notifier).transfer(
        fromCategory: _from,
        toCategory:   _to,
        amount:       double.parse(_amountCtrl.text.trim()),
        date:         _date,
        note:         _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
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
    final state   = ref.watch(financeViewModelProvider);
    final fromAcc = state.accountFor(_from);
    final toAcc   = state.accountFor(_to);
    const transferColor = Color(0xFF3498DB);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('TRANSFER MONEY',
            style: AppTypography.label.copyWith(fontSize: 12)),
        leading: IconButton(
          icon: const Icon(Icons.close,
              size: AppSpacing.iconMd, color: AppColors.textSecondary),
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
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: transferColor))
                  : Text('SAVE',
                      style: AppTypography.label
                          .copyWith(color: transferColor)),
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
              // Visual from → to
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: transferColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                      color: transferColor.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CategoryChip(category: _from, balance: fromAcc?.currentBalance),
                    const Icon(Icons.arrow_forward_rounded,
                        color: transferColor, size: 20),
                    _CategoryChip(category: _to, balance: toAcc?.currentBalance),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FinanceDropdownField<FinanceCategory>(
                label: 'FROM ACCOUNT',
                value: _from,
                items: FinanceCategory.values,
                itemLabel: (c) => c.label,
                onChanged: (c) => setState(() => _from = c!),
              ),
              const SizedBox(height: AppSpacing.md),

              FinanceDropdownField<FinanceCategory>(
                label: 'TO ACCOUNT',
                value: _to,
                items: FinanceCategory.values,
                itemLabel: (c) => c.label,
                onChanged: (c) => setState(() => _to = c!),
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

              FinanceDateField(label: 'DATE', date: _date, onTap: _pickDate),
              const SizedBox(height: AppSpacing.md),

              FinanceField(
                label: 'NOTE (optional)',
                controller: _noteCtrl,
                hintText: 'Reason for transfer',
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

class _CategoryChip extends StatelessWidget {
  final FinanceCategory category;
  final double? balance;

  const _CategoryChip({required this.category, this.balance});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(category.label.toUpperCase(),
            style: AppTypography.chip.copyWith(fontSize: 10)),
        if (balance != null)
          Text(
            'TZS ${balance!.toStringAsFixed(0)}',
            style: AppTypography.mono.copyWith(fontSize: 11),
          ),
      ],
    );
  }
}
