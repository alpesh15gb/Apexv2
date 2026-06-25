import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apex Design System — Typography Scale
///
/// Uses Inter font family via Google Fonts.
class ApexTypography {
  ApexTypography._();

  static TextStyle _base = GoogleFonts.inter();

  // ── Display (Hero sections, splash) ──────────────────────────
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.5,
  );

  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
  );

  // ── Headings ─────────────────────────────────────────────────
  static TextStyle get headingLarge => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle get headingMedium => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get headingSmall => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ── Titles ───────────────────────────────────────────────────
  static TextStyle get titleLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get titleMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static TextStyle get titleSmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.5,
  );

  // ── Body ─────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Caption / Label ──────────────────────────────────────────
  static TextStyle get captionLarge => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle get captionMedium => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle get captionSmall => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
  );

  // ── Button ───────────────────────────────────────────────────
  static TextStyle get buttonLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle get buttonMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle get buttonSmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
}
