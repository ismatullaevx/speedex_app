import 'package:flutter/material.dart';

/// Consistent text styles across the Speedex app.
class AppTextStyles {
  AppTextStyles._();

  // ── Speed display ───────────────────────────────────────────────────────
  static const TextStyle speedValue = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
    height: 1.0,
  );

  static const TextStyle speedUnit = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
  );

  // ── Stats ───────────────────────────────────────────────────────────────
  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  // ── App bar ─────────────────────────────────────────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  // ── Session card ────────────────────────────────────────────────────────
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ── Section heading ─────────────────────────────────────────────────────
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  // ── Body ────────────────────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}
