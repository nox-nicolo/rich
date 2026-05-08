// lib/features/dashboard/view/widgets/discipline_score_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../model/dashboard_state_model.dart';

class DisciplineScoreWidget extends StatelessWidget {
  final int score;
  final MentalReadiness readiness;

  const DisciplineScoreWidget({
    required this.score,
    required this.readiness,
    super.key,
  });

  Color get _scoreColor {
    if (score >= AppConstants.scoreHigh)   return AppColors.success;
    if (score >= AppConstants.scoreMedium) return AppColors.caution;
    return AppColors.warning;
  }

  Color _colorFor(MentalReadiness r) {
    switch (r) {
      case MentalReadiness.high:     return AppColors.success;
      case MentalReadiness.medium:   return AppColors.caution;
      case MentalReadiness.low:      return AppColors.warning;
      case MentalReadiness.unchecked:return AppColors.textMuted;
    }
  }

  String _subtitle(MentalReadiness r) {
    switch (r) {
      case MentalReadiness.unchecked: return 'Awaiting signals';
      case MentalReadiness.low:       return 'Mood + low activity';
      case MentalReadiness.medium:    return 'Some signals in';
      case MentalReadiness.high:      return 'Meditation + activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final readinessColor = _colorFor(readiness);

    return Row(
      children: [

        // ── Discipline Score ───────────────────────────────────────────
        Expanded(
          child: GlossyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISCIPLINE',
                    style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: AppTypography.h1.copyWith(
                        color: _scoreColor,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 3),
                      child: Text('/100',
                          style: AppTypography.caption),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppColors.surfaceVar,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _scoreColor),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // ── Mental Readiness (auto-derived) ────────────────────────────
        Expanded(
          child: GlossyCard(
            accentBorder: readinessColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MIND', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  readiness.label,
                  style: AppTypography.h3.copyWith(
                    color: readinessColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: readinessColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _subtitle(readiness),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
