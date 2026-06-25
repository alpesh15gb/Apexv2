import 'package:flutter/material.dart';

/// Enterprise Spacing — Tighter defaults for information density
class ApexSpacing {
  ApexSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Page padding — 24px desktop, 16px mobile
  static const EdgeInsets pagePadding = EdgeInsets.all(24);
  static const EdgeInsets pagePaddingMobile = EdgeInsets.all(16);

  // Card padding — 12px for compact
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(8);

  // Section gap — 8px related, 16px between sections
  static const double sectionGap = 16;
  static const double relatedGap = 8;

  // Table row padding
  static const EdgeInsets tableRowPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 12);
  static const EdgeInsets tableHeaderPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 12);

  // Common gaps
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapBase = SizedBox(height: base, width: base);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalBase = SizedBox(width: base);
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalBase = SizedBox(height: base);
}
