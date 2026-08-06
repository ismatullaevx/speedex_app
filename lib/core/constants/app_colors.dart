import 'package:flutter/material.dart';

/// Speedex color palette — supports both dark and light themes.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00D4FF);       // Cyan accent
  static const Color primaryDark = Color(0xFF0097B2);
  static const Color secondary = Color(0xFF6C63FF);     // Purple accent

  // ── Dark theme surfaces ─────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF131929);
  static const Color darkCard = Color(0xFF1C2438);
  static const Color darkBorder = Color(0xFF263048);

  // ── Light theme surfaces ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E6F0);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00E676);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD740);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A9BB5);
  static const Color textLight = Color(0xFF1A2340);

  // ── Speedometer arc ─────────────────────────────────────────────────────
  static const Color arcTrack = Color(0xFF263048);
  static const Color arcTrackLight = Color(0xFFD8E0EE);
  static const Color arcGradientStart = Color(0xFF00D4FF);
  static const Color arcGradientEnd = Color(0xFF6C63FF);

  // ── Start/Stop button gradients ─────────────────────────────────────────
  static const List<Color> startGradient = [Color(0xFF00E676), Color(0xFF00B248)];
  static const List<Color> stopGradient = [Color(0xFFFF5252), Color(0xFFB71C1C)];
}
