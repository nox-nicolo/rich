// lib/core/theme/app_typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ── Display — commanding, large headings ──────────────────────────────────
  static TextStyle display = GoogleFonts.dmSerifDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle h1 = GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle h2 = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle h3 = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ── Label — ALL CAPS metadata text ───────────────────────────────────────
  static TextStyle label = GoogleFonts.dmMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  // ── Chip / Badge ──────────────────────────────────────────────────────────
  static TextStyle chip = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ── Mono — counts, times, numbers ────────────────────────────────────────
  static TextStyle mono = GoogleFonts.dmMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // ── Caption ───────────────────────────────────────────────────────────────
  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}
