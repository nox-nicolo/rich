// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,

    // ── Color Scheme ───────────────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      surface:        AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVar,
      primary:        AppColors.accent,
      onPrimary:      AppColors.background,
      secondary:      AppColors.accentMuted,
      onSecondary:    AppColors.background,
      error:          AppColors.warning,
      onSurface:      AppColors.textPrimary,
      outline:        AppColors.border,
    ),

    // ── AppBar ─────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: AppTypography.h2,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSpacing.iconMd,
      ),
    ),

    // ── Card ───────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),

    // ── Chip ───────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVar,
      selectedColor: AppColors.accent,
      labelStyle: AppTypography.chip,
      side: const BorderSide(color: AppColors.border, width: 0.5),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),

    // ── Divider ────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 0.5,
      space: 1,
    ),

    // ── Text ───────────────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayLarge:   AppTypography.display,
      headlineLarge:  AppTypography.h1,
      headlineMedium: AppTypography.h2,
      headlineSmall:  AppTypography.h3,
      bodyLarge:      AppTypography.body,
      bodyMedium:     AppTypography.body,
      bodySmall:      AppTypography.bodySmall,
      labelSmall:     AppTypography.label,
      labelMedium:    AppTypography.caption,
    ),

    // ── Bottom Navigation Bar ──────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceVar,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.caption
              .copyWith(color: AppColors.accent);
        }
        return AppTypography.caption;
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
              color: AppColors.accent, size: AppSpacing.iconLg);
        }
        return const IconThemeData(
            color: AppColors.textMuted, size: AppSpacing.iconLg);
      }),
    ),

    // ── Input / TextField ──────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.accent, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.warning, width: 0.5),
      ),
      hintStyle: AppTypography.body,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    ),

    // ── Bottom Sheet ───────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
    ),

    // ── Elevated Button ────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.h3.copyWith(
          color: AppColors.background,
          fontSize: 13,
        ),
      ),
    ),

    // ── Text Button ────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: AppTypography.label,
      ),
    ),

    // ── List Tile ──────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor: AppColors.surface,
      iconColor: AppColors.textMuted,
      textColor: AppColors.textPrimary,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    ),

    // ── Switch ─────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.background;
        }
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return AppColors.surfaceVar;
      }),
    ),
  );
}
