// lib/feature/dashboard/view/widget/daily_wisdom_card.dart
//
// Daily anchor card on the dashboard. Pulls one wisdom entry per calendar
// day from [DailyWisdom] and renders it as a glossy card with the quote
// front and centre, plus an "explanation" reveal so the user can read
// the why without opening another screen.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glossy_card.dart';
import '../../model/daily_wisdom.dart';

class DailyWisdomCard extends StatefulWidget {
  const DailyWisdomCard({super.key});

  @override
  State<DailyWisdomCard> createState() => _DailyWisdomCardState();
}

class _DailyWisdomCardState extends State<DailyWisdomCard> {
  bool _showExplanation = true;
  // Lets the user shuffle through entries instead of being stuck on
  // today's pick. Resets to today (offset 0) on next visit.
  int _offset = 0;

  WisdomEntry get _entry {
    final today = DateTime.now();
    return _offset == 0
        ? DailyWisdom.today(from: today)
        : DailyWisdom.at(date: today, offset: _offset);
  }

  void _next() => setState(() => _offset += 1);
  void _resetToday() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    final entry = _entry;

    return GlossyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.accent.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  '😤',
                  style: TextStyle(fontSize: 14, height: 1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'TODAY\'S WISDOM',
                style: AppTypography.label.copyWith(letterSpacing: 2.5),
              ),
              const Spacer(),
              if (_offset != 0)
                GestureDetector(
                  onTap: _resetToday,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'TODAY',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _next,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.textMuted,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Big opening quote glyph ────────────────────────────────
          Text(
            '"',
            style: AppTypography.h1.copyWith(
              color: AppColors.accent.withValues(alpha: 0.4),
              fontSize: 38,
              height: 0.6,
            ),
          ),
          const SizedBox(height: 4),

          // ── The quote itself ────────────────────────────────────────
          Text(
            entry.quote,
            style: AppTypography.h3.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.45,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Title + source ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 18,
                height: 1,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  entry.title.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              entry.source,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Explanation toggle ──────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showExplanation = !_showExplanation),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.textSecondary,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showExplanation ? 'HIDE EXPLANATION' : 'SHOW EXPLANATION',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showExplanation
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Explanation body ────────────────────────────────────────
          if (_showExplanation) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                entry.explanation,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
