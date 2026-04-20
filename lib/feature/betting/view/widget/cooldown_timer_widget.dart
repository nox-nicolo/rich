// lib/features/betting/view/widgets/cooldown_timer_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../viewmodel/betting_viewmodel.dart';

class CooldownTimerWidget extends ConsumerStatefulWidget {
  const CooldownTimerWidget({super.key});

  @override
  ConsumerState<CooldownTimerWidget> createState() =>
      _CooldownTimerWidgetState();
}

class _CooldownTimerWidgetState
    extends ConsumerState<CooldownTimerWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    if (d.inHours > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bettingViewModelProvider);
    final lockdown = state.lockdown;

    if (!lockdown.hasCooldown || !lockdown.cooldownActive) {
      return const SizedBox.shrink();
    }

    final remaining = lockdown.remainingCooldown!;
    final totalSeconds =
        lockdown.cooldownExpiresAt!.difference(lockdown.lockedAt!).inSeconds;
    final remainingSeconds = remaining.inSeconds;
    final progress =
        1.0 - (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
              const Icon(Icons.timer_outlined,
                  size: AppSpacing.iconSm, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'COOLDOWN ACTIVE',
                style: AppTypography.label
                    .copyWith(color: AppColors.warning),
              ),
              const Spacer(),
              Text(
                _formatDuration(remaining),
                style: AppTypography.mono.copyWith(
                  color: AppColors.warning,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVar,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Loss streak protection. Use this time to reflect, not plan the next bet.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
