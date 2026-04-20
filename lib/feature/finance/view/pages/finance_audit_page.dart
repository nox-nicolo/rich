// lib/feature/finance/view/pages/finance_audit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/finance_models.dart';
import '../../viewmodel/finance_viewmodel.dart';

class FinanceAuditPage extends ConsumerWidget {
  const FinanceAuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeViewModelProvider);
    final entries = state.auditTrail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('AUDIT TRAIL', style: AppTypography.label.copyWith(fontSize: 12)),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No audit entries yet.',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _AuditEntryTile(entry: entries[i]),
            ),
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  final AuditTrailEntry entry;

  const _AuditEntryTile({required this.entry});

  Color get _actionColor {
    switch (entry.action) {
      case AuditAction.created: return AppColors.success;
      case AuditAction.updated: return const Color(0xFF3498DB);
      case AuditAction.deleted: return AppColors.warning;
    }
  }

  IconData get _actionIcon {
    switch (entry.action) {
      case AuditAction.created: return Icons.add_circle_outline;
      case AuditAction.updated: return Icons.edit_outlined;
      case AuditAction.deleted: return Icons.delete_outline;
    }
  }

  String get _formattedTimestamp {
    final ts = entry.timestamp;
    return '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}  '
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _actionColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(_actionIcon, size: AppSpacing.iconSm, color: _actionColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${entry.action.label.toUpperCase()} — ${entry.entityType}',
                style: AppTypography.label.copyWith(color: _actionColor, fontSize: 10),
              ),
              const Spacer(),
              Text(_formattedTimestamp, style: AppTypography.caption.copyWith(fontSize: 9)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Field
          Text(
            entry.fieldName.toUpperCase(),
            style: AppTypography.caption.copyWith(fontSize: 9),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Old → New value
          if (entry.oldValue != null || entry.newValue != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.oldValue != null) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        entry.oldValue!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                  if (entry.newValue != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.arrow_forward, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
                if (entry.newValue != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        entry.newValue!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Reason
          if (entry.reason != null && entry.reason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: ${entry.reason}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
