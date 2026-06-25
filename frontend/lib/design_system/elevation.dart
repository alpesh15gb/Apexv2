import 'package:flutter/material.dart';

/// Apex Design System — Elevation / Shadow
class ApexElevation {
  ApexElevation._();

  static const double none = 0;
  static const double xs = 0.5;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
  static const double xl = 8;
  static const double xxl = 16;

  static List<BoxShadow> get shadowNone => [];

  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
