import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apex Typography — Strict hierarchy for readability
/// Font: Inter | Weights: 400, 500, 600, 700
class ApexTypography {
  ApexTypography._();

  static final TextStyle _base = GoogleFonts.inter();

  // ── Page Title: 36px / 700 ──────────────────────────────────
  static TextStyle get pageTitle => _base.copyWith(
    fontSize: 36, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5, color: const Color(0xFF111827),
  );

  // ── Section Title: 18px / 600 ───────────────────────────────
  static TextStyle get sectionTitle => _base.copyWith(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, color: const Color(0xFF111827),
  );

  // ── Card Title: 16px / 600 ──────────────────────────────────
  static TextStyle get cardTitle => _base.copyWith(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: const Color(0xFF111827),
  );

  // ── Body: 14px / 400 ────────────────────────────────────────
  static TextStyle get body => _base.copyWith(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: const Color(0xFF111827),
  );

  // ── Table: 14px / 400 ───────────────────────────────────────
  static TextStyle get table => _base.copyWith(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: const Color(0xFF111827),
  );

  // ── Table Header: 13px / 600 uppercase ──────────────────────
  static TextStyle get tableHeader => _base.copyWith(
    fontSize: 13, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.5, color: const Color(0xFF374151),
  );

  // ── Caption: 13px / 500 ─────────────────────────────────────
  static TextStyle get caption => _base.copyWith(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.5, color: const Color(0xFF4B5563),
  );

  // ── KPI Value: 34px / 700 ───────────────────────────────────
  static TextStyle get kpiValue => _base.copyWith(
    fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, color: const Color(0xFF111827),
  );

  // ── KPI Label: 13px / 500 ───────────────────────────────────
  static TextStyle get kpiLabel => _base.copyWith(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, color: const Color(0xFF4B5563),
  );

  // ── Secondary text: 14px / 400 ──────────────────────────────
  static TextStyle get secondary => _base.copyWith(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: const Color(0xFF374151),
  );

  // ── Disabled text: 14px / 400 ───────────────────────────────
  static TextStyle get disabled => _base.copyWith(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: const Color(0xFF9CA3AF),
  );

  // ── Button: 14px / 600 ──────────────────────────────────────
  static TextStyle get button => _base.copyWith(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: const Color(0xFF111827),
  );

  // ── Badge: 12px / 600 ───────────────────────────────────────
  static TextStyle get badge => _base.copyWith(
    fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, color: const Color(0xFF111827),
  );

  // ── Section Header (uppercase): 12px / 600 ──────────────────
  static TextStyle get sectionHeader => _base.copyWith(
    fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 1.2, color: const Color(0xFF4B5563),
  );

  // ── Legacy aliases for backward compatibility ────────────────
  static TextStyle get headingLarge => sectionTitle;
  static TextStyle get headingMedium => cardTitle;
  static TextStyle get headingSmall => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: const Color(0xFF111827));
  static TextStyle get titleLarge => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: const Color(0xFF111827));
  static TextStyle get titleMedium => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.45, color: const Color(0xFF111827));
  static TextStyle get titleSmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.5, color: const Color(0xFF111827));
  static TextStyle get bodyLarge => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5, color: const Color(0xFF111827));
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => caption;
  static TextStyle get captionLarge => caption;
  static TextStyle get captionMedium => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5, color: const Color(0xFF4B5563));
  static TextStyle get captionSmall => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: const Color(0xFF4B5563));
  static TextStyle get buttonLarge => button;
  static TextStyle get buttonMedium => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: const Color(0xFF111827));
  static TextStyle get buttonSmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, color: const Color(0xFF111827));
  static TextStyle get displayLarge => _base.copyWith(fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1.5, color: const Color(0xFF111827));
  static TextStyle get displayMedium => _base.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.5, color: const Color(0xFF111827));
  static TextStyle get tableCell => table;
}
