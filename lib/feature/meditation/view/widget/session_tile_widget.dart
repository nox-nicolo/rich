// lib/features/meditation/view/widgets/session_tile_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../model/meditation_type.dart';
import '../../model/meditation_session_model.dart';

class SessionTileWidget extends StatelessWidget {
  final MeditationType type;
  final bool completedToday;
  final VoidCallback onStart;

  const SessionTileWidget({
    required this.type,
    required this.completedToday,
    required this.onStart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: completedToday
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                type.durationLabel,
                style: AppTypography.mono.copyWith(fontSize: 11),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: AppTypography.h3.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(type.sublabel, style: AppTypography.caption),
                ],
              ),
            ),
            if (type.isGateQualifier)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'GATE',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.accent,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            completedToday
                ? const Icon(
                    Icons.check_circle_outline,
                    size: AppSpacing.iconSm,
                    color: AppColors.success,
                  )
                : const Icon(
                    Icons.arrow_forward_ios,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted,
                  ),
          ],
        ),
      ),
    );
  }
}

class SessionLogTile extends StatelessWidget {
  final MeditationSession session;

  const SessionLogTile({required this.session, super.key});

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              session.type.label,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (session.moodAfter != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                session.moodAfter!.shortLabel,
                style: AppTypography.caption,
              ),
            ),
          if (session.note != null && session.note!.isNotEmpty) ...[
            const Icon(Icons.notes_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            _timeLabel(session.startedAt),
            style: AppTypography.caption,
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            session.completed
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: AppSpacing.iconSm,
            color: session.completed
                ? AppColors.success
                : AppColors.warning,
          ),
        ],
      ),
    );
  }
}
