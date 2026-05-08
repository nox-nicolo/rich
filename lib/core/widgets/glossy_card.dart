// lib/core/widgets/glossy_card.dart
//
// Reusable glossy card shell. Used by every dashboard widget so they all
// share the same depth, gradient, top sheen, and soft drop shadow — the
// "premium glass" look set by the milestone card.
//
// API:
//   GlossyCard(child: ...)
//   GlossyCard(child: ..., onTap: () => ...)              // tappable card
//   GlossyCard(child: ..., accentBorder: AppColors.warning) // tinted border
//   GlossyCard(child: ..., accentTint: AppColors.warning)   // tinted overlay
//   GlossyCard(child: ..., padding: EdgeInsets.all(...), radius: ...)

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GlossyCard extends StatelessWidget {
  final Widget                 child;
  final EdgeInsetsGeometry     padding;
  final VoidCallback?          onTap;
  /// Override for the outer border colour. Defaults to a subtle [AppColors.border].
  final Color?                 accentBorder;
  /// Optional low-opacity wash over the gradient (e.g. NewsFlash uses
  /// [AppColors.warning] to flag importance). Pass null for the standard
  /// neutral glass treatment.
  final Color?                 accentTint;
  final double                 radius;

  const GlossyCard({
    super.key,
    required this.child,
    this.padding      = const EdgeInsets.all(AppSpacing.cardPad),
    this.onTap,
    this.accentBorder,
    this.accentTint,
    this.radius       = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            AppColors.surfaceVar,
            AppColors.surface,
            AppColors.background,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accentBorder?.withValues(alpha: 0.35) ??
              AppColors.border.withValues(alpha: 0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color:       Colors.black.withValues(alpha: 0.4),
            blurRadius:  18,
            spreadRadius: -4,
            offset:      const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Optional accent wash for tinted cards (NewsFlash, lock warnings).
          if (accentTint != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentTint!.withValues(alpha: 0.08),
                          accentTint!.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top edge sheen — a 1px gradient line that mimics light catching
          // on glass.
          Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Actual content
          child,
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child:    card,
    );
  }
}
