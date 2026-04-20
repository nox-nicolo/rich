// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background   = Color(0xFF0A0A0A);
  static const Color surface      = Color(0xFF111111);
  static const Color surfaceVar   = Color(0xFF1A1A1A);
  static const Color elevated     = Color(0xFF222222);

  // Accent
  static const Color accent       = Color(0xFFF5F5F5); // Pure White
  static const Color accentMuted  = Color(0xFFAAAAAA);

  // Text
  static const Color textPrimary  = Color(0xFFF5F5F5);
  static const Color textSecondary= Color(0xFF888888);
  static const Color textMuted    = Color(0xFF555555);
  static const Color textDisabled = Color(0xFF333333);

  // States
  static const Color locked       = Color(0xFF2A2A2A);
  static const Color lockedBorder = Color(0xFF333333);
  static const Color warning      = Color(0xFFC0392B);
  static const Color success      = Color(0xFF27AE60);
  static const Color caution      = Color(0xFFE67E22);

  // Impact
  static const Color impactHigh   = Color(0xFFC0392B);
  static const Color impactMedium = Color(0xFFE67E22);
  static const Color impactLow    = Color(0xFF27AE60);
  static const Color impactNeutral= Color(0xFF555555);

  // Divider
  static const Color divider      = Color(0xFF1F1F1F);
  static const Color border       = Color(0xFF2A2A2A);
}
