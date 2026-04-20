// lib/features/betting/view/widgets/lockdown_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/lockdown_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

class LockdownWidget extends ConsumerWidget {
  const LockdownWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bettingViewModelProvider);
    final vm = ref.read(bettingViewModelProvider.notifier);
    final lockdown = state.lockdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'LOCKDOWN'),

        // ── Current status ────────────────────────────────────────
        _StatusCard(
          isLocked: lockdown.isLocked,
          consecutiveLosses: lockdown.consecutiveLosses,
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Lock reason detail ────────────────────────────────────
        if (lockdown.isLocked && lockdown.reason != null) ...[
          _ReasonCard(lockdown: lockdown),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Cooldown timer if applicable ──────────────────────────
        if (lockdown.hasCooldown && lockdown.cooldownActive) ...[
          const SizedBox(height: AppSpacing.sm),
        ],

        // ── Actions ───────────────────────────────────────────────
        const SizedBox(height: AppSpacing.lg),
        const RichSectionHeader(title: 'CONTROLS'),

        if (!lockdown.isLocked)
          _ManualLockButton(onLock: vm.manualLock)
        else if (lockdown.reason != LockdownReason.tradingSessionActive &&
            !lockdown.cooldownActive)
          _UnlockButton(onUnlock: vm.unlock),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isLocked;
  final int consecutiveLosses;

  const _StatusCard({
    required this.isLocked,
    required this.consecutiveLosses,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
            color: color,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocked ? 'BETTING LOCKED' : 'BETTING OPEN',
                  style: AppTypography.label.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Consecutive losses: $consecutiveLosses',
                      style: AppTypography.caption.copyWith(
                        color: consecutiveLosses >= 2
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final LockdownModel lockdown;

  const _ReasonCard({required this.lockdown});

  @override
  Widget build(BuildContext context) {
    final reason = lockdown.reason!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reason.label, style: AppTypography.h3.copyWith(fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Text(reason.description, style: AppTypography.body),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    reason.unlockInstruction,
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualLockButton extends StatelessWidget {
  final VoidCallback onLock;

  const _ManualLockButton({required this.onLock});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLock,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: AppSpacing.iconSm, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manual Lock',
                      style: AppTypography.h3.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Lock betting by choice when discipline requires it',
                      style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: AppSpacing.iconSm, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final VoidCallback onUnlock;

  const _UnlockButton({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onUnlock,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceVar,
          foregroundColor: AppColors.textPrimary,
        ),
        child: Text(
          'UNLOCK BETTING',
          style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }
}
