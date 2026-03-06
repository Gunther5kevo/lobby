import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// All text styles for GuildChat.
/// Sora  → headings, labels, nav, tags (characterful geometric sans)
/// DM Sans → body copy, messages, previews (warm, readable)
abstract class AppTextStyles {
  // ── Display / Headings (Sora) ─────────────────────────────────
  static TextStyle get appName => GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      );

  static TextStyle get screenTitle => GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      );

  // ── Chat list tile ────────────────────────────────────────────
  static TextStyle get chatName => GoogleFonts.sora(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get chatPreview => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  static TextStyle get chatTime => GoogleFonts.sora(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ── Section labels ────────────────────────────────────────────
  static TextStyle get sectionLabel => GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.9,
      );

  // ── Badge ─────────────────────────────────────────────────────
  static TextStyle get badge => GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ── Search placeholder ────────────────────────────────────────
  static TextStyle get searchHint => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get searchText => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // ── Nav bar labels ────────────────────────────────────────────
  static TextStyle get navLabel => GoogleFonts.sora(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  // ── Avatar initials ───────────────────────────────────────────
  static TextStyle get avatarInitial => GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.9),
      );

  static TextStyle get avatarInitialSm => GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.9),
      );
}