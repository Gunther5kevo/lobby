import 'package:flutter/material.dart';

/// GuildChat color palette — dark, slate/charcoal, muted blue accent.
/// No neon, no gradients on text, no cyberpunk. Clean and commercial.
abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────
  static const bgBase     = Color(0xFF0F1117); // deepest background
  static const bgSurface  = Color(0xFF181C27); // cards, nav bar
  static const bgElevated = Color(0xFF1F2436); // elevated surfaces
  static const bgCard     = Color(0xFF242840); // input fills, chips
  static const bgInput    = Color(0xFF1A1E2E); // text field bg

  // ── Borders ───────────────────────────────────────────────────
  static const border      = Color(0x12FFFFFF); // 7% white
  static const borderStrong= Color(0x1FFFFFFF); // 12% white

  // ── Accent ────────────────────────────────────────────────────
  static const accent      = Color(0xFF4F80FF);
  static const accentSoft  = Color(0x264F80FF); // 15% accent
  static const accentHover = Color(0xFF6B94FF);

  // ── Semantic ──────────────────────────────────────────────────
  static const success = Color(0xFF3DB88A); // online
  static const warning = Color(0xFFF0A844); // idle
  static const danger  = Color(0xFFE05C5C); // error / offline action

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFE8EAF2);
  static const textSecondary = Color(0xFF8B92A8);
  static const textMuted     = Color(0xFF555E7A);

  // ── Message bubbles ───────────────────────────────────────────
  static const bubbleSent     = Color(0xFF2D3A6E);
  static const bubbleReceived = Color(0xFF1F2436);

  // ── Avatar palette — used for generated avatars ───────────────
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF2D4A8A), Color(0xFF3D5EAA)], // blue
    [Color(0xFF1F5C40), Color(0xFF2A7A55)], // green
    [Color(0xFF4A2D7A), Color(0xFF6040A0)], // purple
    [Color(0xFF7A3D1F), Color(0xFFA05230)], // orange
    [Color(0xFF1F5A5C), Color(0xFF2A7A7C)], // teal
    [Color(0xFF7A2D4A), Color(0xFFA03A60)], // rose
    [Color(0xFF3A4060), Color(0xFF4A5280)], // slate
    [Color(0xFF2D3A6E), Color(0xFF3D4E8E)], // indigo
  ];
}