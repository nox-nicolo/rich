// lib/feature/finance/view/widgets/finance_form_widgets.dart
//
// Shared form widgets used across Add Income, Add Expense, Transfer, and Budget pages.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// A labelled text form field matching the app design.
class FinanceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const FinanceField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.warning, width: 0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

/// A labelled dropdown matching the app design.
class FinanceDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const FinanceDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surfaceVar,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            onChanged: onChanged,
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// A labelled date picker row.
class FinanceDateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const FinanceDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  String get _formatted =>
      '${date.day.toString().padLeft(2, '0')} / '
      '${date.month.toString().padLeft(2, '0')} / ${date.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: AppSpacing.iconSm, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Text(_formatted,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
