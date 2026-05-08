// lib/features/dashboard/view/widgets/news_flash_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../../../feature/trading/model/news_event.dart';

class NewsFlashWidget extends StatelessWidget {
  final NewsEvent news;
  const NewsFlashWidget({required this.news, super.key});

  @override
  Widget build(BuildContext context) {
    return GlossyCard(
      accentBorder: AppColors.warning,
      accentTint:   AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.bolt,
                  color: AppColors.warning,
                  size: AppSpacing.iconSm),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'HIGH IMPACT NEWS',
                style: AppTypography.label
                    .copyWith(color: AppColors.warning),
              ),
              const Spacer(),
              Text(
                RichDateUtils.timeAgo(news.publishedAt),
                style: AppTypography.caption,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Headline ───────────────────────────────────────────────────
          Text(
            news.headline,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpacing.xs + 2),

          // ── Source ─────────────────────────────────────────────────────
          Text(
            news.source,
            style: AppTypography.caption
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
