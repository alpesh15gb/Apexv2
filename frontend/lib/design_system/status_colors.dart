import 'package:flutter/material.dart';
import 'colors.dart';

/// Apex Design System — Status Colors
///
/// Provides consistent colors for status badges, tags, and indicators.
class ApexStatusColors {
  ApexStatusColors._();

  // ── Attendance Status ────────────────────────────────────────
  static const Map<String, Color> attendance = {
    'present': ApexColors.success,
    'late': ApexColors.warning,
    'absent': ApexColors.error,
    'half_day': ApexColors.accent,
    'on_leave': ApexColors.info,
    'holiday': ApexColors.neutral400,
    'week_off': ApexColors.neutral400,
  };

  static const Map<String, Color> attendanceLight = {
    'present': ApexColors.successLight,
    'late': ApexColors.warningLight,
    'absent': ApexColors.errorLight,
    'half_day': ApexColors.accent50,
    'on_leave': ApexColors.infoLight,
    'holiday': ApexColors.neutral100,
    'week_off': ApexColors.neutral100,
  };

  static const Map<String, String> attendanceLabels = {
    'present': 'Present',
    'late': 'Late',
    'absent': 'Absent',
    'half_day': 'Half Day',
    'on_leave': 'On Leave',
    'holiday': 'Holiday',
    'week_off': 'Week Off',
  };

  // ── Device Status ────────────────────────────────────────────
  static const Map<String, Color> device = {
    'online': ApexColors.success,
    'offline': ApexColors.error,
    'error': ApexColors.error,
    'testing': ApexColors.warning,
    'inactive': ApexColors.neutral400,
  };

  static const Map<String, Color> deviceLight = {
    'online': ApexColors.successLight,
    'offline': ApexColors.errorLight,
    'error': ApexColors.errorLight,
    'testing': ApexColors.warningLight,
    'inactive': ApexColors.neutral100,
  };

  // ── Sync Status ──────────────────────────────────────────────
  static const Map<String, Color> syncStatus = {
    'running': ApexColors.info,
    'completed': ApexColors.success,
    'partial': ApexColors.warning,
    'failed': ApexColors.error,
    'cancelled': ApexColors.neutral400,
    'paused': ApexColors.accent,
  };

  // ── Leave Status ─────────────────────────────────────────────
  static const Map<String, Color> leave = {
    'pending': ApexColors.warning,
    'approved': ApexColors.success,
    'rejected': ApexColors.error,
    'cancelled': ApexColors.neutral400,
  };

  // ── Employee Status ──────────────────────────────────────────
  static const Map<String, Color> employee = {
    'active': ApexColors.success,
    'inactive': ApexColors.neutral400,
    'terminated': ApexColors.error,
    'on_notice': ApexColors.warning,
  };

  // ── Connection Status ────────────────────────────────────────
  static const Map<String, Color> connection = {
    'connected': ApexColors.success,
    'disconnected': ApexColors.error,
    'testing': ApexColors.warning,
    'error': ApexColors.error,
  };

  // ── Helper ───────────────────────────────────────────────────
  static Color getColor(String category, String status) {
    switch (category) {
      case 'attendance':
        return attendance[status] ?? ApexColors.neutral400;
      case 'device':
        return device[status] ?? ApexColors.neutral400;
      case 'sync':
        return syncStatus[status] ?? ApexColors.neutral400;
      case 'leave':
        return leave[status] ?? ApexColors.neutral400;
      case 'employee':
        return employee[status] ?? ApexColors.neutral400;
      case 'connection':
        return connection[status] ?? ApexColors.neutral400;
      default:
        return ApexColors.neutral400;
    }
  }

  static Color getLightColor(String category, String status) {
    switch (category) {
      case 'attendance':
        return attendanceLight[status] ?? ApexColors.neutral100;
      case 'device':
        return deviceLight[status] ?? ApexColors.neutral100;
      default:
        return ApexColors.neutral100;
    }
  }
}
