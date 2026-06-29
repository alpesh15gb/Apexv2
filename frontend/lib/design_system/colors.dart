import 'package:flutter/material.dart';

/// Apex Design System — Color Tokens
///
/// Usage:
///   ApexColors.primary
///   ApexColors.success
///   ApexColors.neutral50
class ApexColors {
  ApexColors._();

  // ── Primary (Deep Navy) ──────────────────────────────────────
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary100 = Color(0xFFDBEAFE);
  static const Color primary200 = Color(0xFFBFDBFE);
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary500 = Color(0xFF3B82F6);
  static const Color primary600 = Color(0xFF2563EB);
  static const Color primary700 = Color(0xFF1D4ED8);
  static const Color primary800 = Color(0xFF1E3A8A);
  static const Color primary900 = Color(0xFF1E3A5F);

  // ── Secondary (Teal) ─────────────────────────────────────────
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondary50 = Color(0xFFF0FDFA);
  static const Color secondary100 = Color(0xFFCCFBF1);
  static const Color secondary200 = Color(0xFF99F6E4);
  static const Color secondary300 = Color(0xFF5EEAD4);
  static const Color secondary400 = Color(0xFF2DD4BF);
  static const Color secondary500 = Color(0xFF14B8A6);
  static const Color secondary600 = Color(0xFF0D9488);
  static const Color secondary700 = Color(0xFF0F766E);

  // ── Accent (Amber) ───────────────────────────────────────────
  static const Color accent = Color(0xFFF59E0B);
  static const Color accent50 = Color(0xFFFFFBEB);
  static const Color accent100 = Color(0xFFFEF3C7);
  static const Color accent200 = Color(0xFFFDE68A);
  static const Color accent300 = Color(0xFFFCD34D);
  static const Color accent400 = Color(0xFFFBBF24);
  static const Color accent500 = Color(0xFFF59E0B);
  static const Color accent600 = Color(0xFFD97706);

  // ── Neutral ──────────────────────────────────────────────────
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // ── Status ───────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFFBBF7D0);
  static const Color success300 = Color(0xFF86EFAC);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF166534);
  static const Color success900 = Color(0xFF14532D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning200 = Color(0xFFFDE68A);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning400 = Color(0xFFFBBF24);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);
  static const Color warning800 = Color(0xFF92400E);
  static const Color warning900 = Color(0xFF78350F);

  static const Color error = Color(0xFFEF4444);
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error900 = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF3B82F6);
  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info200 = Color(0xFFBFDBFE);
  static const Color info300 = Color(0xFF93C5FD);
  static const Color info400 = Color(0xFF60A5FA);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info600 = Color(0xFF2563EB);
  static const Color info700 = Color(0xFF1D4ED8);
  static const Color info800 = Color(0xFF1E40AF);
  static const Color info900 = Color(0xFF1E3A8A);

  // ── Neutral (Gray) ───────────────────────────────────────────
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Backward-compatible semantic aliases used across existing screens.
  static const Color successLight = success50;
  static const Color successDark = success700;
  static const Color warningLight = warning50;
  static const Color warningDark = warning700;
  static const Color errorLight = error50;
  static const Color errorDark = error700;
  static const Color infoLight = info50;
  static const Color infoDark = info700;

  // ── Dark Mode ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
}
