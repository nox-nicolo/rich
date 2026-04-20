// lib/core/widgets/rich_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class RichBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool resizeForKeyboard;

  const RichBottomSheet({
    required this.child,
    this.title,
    this.resizeForKeyboard = false,
    super.key,
  });

  /// Static helper — use this instead of calling
  /// showModalBottomSheet directly throughout the app.
  ///
  /// Example:
  ///   RichBottomSheet.show(
  ///     context: context,
  ///     title: 'ADD NOTE',
  ///     resizeForKeyboard: true,
  ///     child: MyFormWidget(),
  ///   );
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool resizeForKeyboard = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => RichBottomSheet(
        title: title,
        resizeForKeyboard: resizeForKeyboard,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = resizeForKeyboard
        ? MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl
        : AppSpacing.xl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────────────
          if (title != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(title!, style: AppTypography.label),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── Content ──────────────────────────────────────────────────────
          child,
        ],
      ),
    );
  }
}
