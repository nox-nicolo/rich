// lib/features/dashboard/view/widgets/command_header_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/router/route_names.dart';
import '../../../../providers/providers.dart';

class CommandHeaderWidget extends ConsumerWidget {
  const CommandHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMode = ref.watch(userModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md,
        AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          // ── App wordmark ───────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RICH',
                style: AppTypography.display.copyWith(
                  fontSize: 22,
                  letterSpacing: 5,
                ),
              ),
              Text(
                RichTimeUtils.greetingByTime().toUpperCase(),
                style: AppTypography.label,
              ),
            ],
          ),

          const Spacer(),

          // ── Mode chip ──────────────────────────────────────────────────
          _ModeChip(mode: userMode),

          const SizedBox(width: AppSpacing.sm),

          // ── Settings ───────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.go(RouteNames.settings),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.border, width: 0.5),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: AppSpacing.iconSm,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final UserMode mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius:
            BorderRadius.circular(AppSpacing.radiusFull),
        border:
            Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            mode.label.toUpperCase(),
            style: AppTypography.chip
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
