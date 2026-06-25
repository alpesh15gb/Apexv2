import 'package:flutter/material.dart';

/// Apex Design System — Border Radius
class ApexRadius {
  ApexRadius._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);

  // ── Top Only ─────────────────────────────────────────────────
  static BorderRadius topMd = const BorderRadius.vertical(top: Radius.circular(md));
  static BorderRadius topLg = const BorderRadius.vertical(top: Radius.circular(lg));
  static BorderRadius topXl = const BorderRadius.vertical(top: Radius.circular(xl));

  // ── Bottom Only ──────────────────────────────────────────────
  static BorderRadius bottomMd = const BorderRadius.vertical(bottom: Radius.circular(md));
  static BorderRadius bottomLg = const BorderRadius.vertical(bottom: Radius.circular(lg));
}
