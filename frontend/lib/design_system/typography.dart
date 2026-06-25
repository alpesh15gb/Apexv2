import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enterprise Typography — Tighter, stronger hierarchy
/// Inspired by Keka, Rippling, BambooHR
class ApexTypography {
  ApexTypography._();

  static final TextStyle _base = GoogleFonts.inter();

  // Display — Hero only
  static TextStyle get displayLarge => _base.copyWith(fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1.5);
  static TextStyle get displayMedium => _base.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.5);

  // Page titles — 24px bold
  static TextStyle get pageTitle => _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.3);

  // Section headers — 11px uppercase gray
  static TextStyle get sectionHeader => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 1.2, color: const Color(0xFF64748B));

  // KPI values — 28px bold
  static TextStyle get kpiValue => _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);

  // KPI labels — 11px gray
  static TextStyle get kpiLabel => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.4, color: const Color(0xFF64748B));

  // Headings
  static TextStyle get headingLarge => _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get headingMedium => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);
  static TextStyle get headingSmall => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  // Titles
  static TextStyle get titleLarge => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get titleMedium => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.45);
  static TextStyle get titleSmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.5);

  // Body — 13px for data density
  static TextStyle get bodyLarge => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // Table cells — 13px
  static TextStyle get tableCell => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);
  static TextStyle get tableHeader => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.5, color: const Color(0xFF64748B));

  // Caption
  static TextStyle get captionLarge => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle get captionMedium => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle get captionSmall => _base.copyWith(fontSize: 10, fontWeight: FontWeight.w500, height: 1.5);

  // Button
  static TextStyle get buttonLarge => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get buttonMedium => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get buttonSmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3);

  // Legacy aliases for compatibility
  static TextStyle get headingSmall_ => headingSmall;
}
