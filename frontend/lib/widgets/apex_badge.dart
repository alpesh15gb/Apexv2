import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

enum ApexBadgeType { success, warning, danger, info, neutral }

enum ApexBadgeSize { small, medium, large }

class ApexBadge extends StatelessWidget {
  final String label;
  final ApexBadgeType type;
  final ApexBadgeSize size;
  final bool showIcon;
  final IconData? icon;

  const ApexBadge({
    super.key,
    required this.label,
    this.type = ApexBadgeType.neutral,
    this.size = ApexBadgeSize.medium,
    this.showIcon = false,
    this.icon,
  });

  factory ApexBadge.success(String label, {ApexBadgeSize size = ApexBadgeSize.medium, bool showIcon = false}) =>
      ApexBadge(label: label, type: ApexBadgeType.success, size: size, showIcon: showIcon);

  factory ApexBadge.warning(String label, {ApexBadgeSize size = ApexBadgeSize.medium, bool showIcon = false}) =>
      ApexBadge(label: label, type: ApexBadgeType.warning, size: size, showIcon: showIcon);

  factory ApexBadge.danger(String label, {ApexBadgeSize size = ApexBadgeSize.medium, bool showIcon = false}) =>
      ApexBadge(label: label, type: ApexBadgeType.danger, size: size, showIcon: showIcon);

  factory ApexBadge.info(String label, {ApexBadgeSize size = ApexBadgeSize.medium, bool showIcon = false}) =>
      ApexBadge(label: label, type: ApexBadgeType.info, size: size, showIcon: showIcon);

  factory ApexBadge.neutral(String label, {ApexBadgeSize size = ApexBadgeSize.medium, bool showIcon = false}) =>
      ApexBadge(label: label, type: ApexBadgeType.neutral, size: size, showIcon: showIcon);

  @override
  Widget build(BuildContext context) {
    final config = _BadgeConfig.forType(type);

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: _borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon || icon != null) ...[
            Icon(icon ?? _defaultIcon, size: _iconSize, color: config.fg),
            SizedBox(width: size == ApexBadgeSize.small ? 4 : 6),
          ],
          Text(label.toUpperCase(), style: _textStyle(config.fg)),
        ],
      ),
    );
  }

  EdgeInsets get _padding {
    switch (size) {
      case ApexBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case ApexBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case ApexBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }

  BorderRadius get _borderRadius {
    switch (size) {
      case ApexBadgeSize.small:
        return BorderRadius.circular(4);
      case ApexBadgeSize.medium:
        return BorderRadius.circular(6);
      case ApexBadgeSize.large:
        return BorderRadius.circular(8);
    }
  }

  TextStyle _textStyle(Color color) {
    switch (size) {
      case ApexBadgeSize.small:
        return ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10);
      case ApexBadgeSize.medium:
        return ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11);
      case ApexBadgeSize.large:
        return ApexTypography.captionMedium.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12);
    }
  }

  double get _iconSize {
    switch (size) {
      case ApexBadgeSize.small:
        return 10;
      case ApexBadgeSize.medium:
        return 12;
      case ApexBadgeSize.large:
        return 14;
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case ApexBadgeType.success:
        return Icons.check_circle;
      case ApexBadgeType.warning:
        return Icons.warning_amber;
      case ApexBadgeType.danger:
        return Icons.error;
      case ApexBadgeType.info:
        return Icons.info_outline;
      case ApexBadgeType.neutral:
        return Icons.circle_outlined;
    }
  }
}

class _BadgeConfig {
  final Color bg;
  final Color fg;

  const _BadgeConfig({required this.bg, required this.fg});

  static _BadgeConfig forType(ApexBadgeType type) {
    switch (type) {
      case ApexBadgeType.success:
        return const _BadgeConfig(bg: ApexColors.success50, fg: ApexColors.success700);
      case ApexBadgeType.warning:
        return const _BadgeConfig(bg: ApexColors.warning50, fg: ApexColors.warning700);
      case ApexBadgeType.danger:
        return const _BadgeConfig(bg: ApexColors.error50, fg: ApexColors.error700);
      case ApexBadgeType.info:
        return const _BadgeConfig(bg: ApexColors.info50, fg: ApexColors.info700);
      case ApexBadgeType.neutral:
        return const _BadgeConfig(bg: ApexColors.gray100, fg: ApexColors.gray700);
    }
  }
}

class AttendanceStatusBadge extends StatelessWidget {
  final String status;

  const AttendanceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'present':
        return ApexBadge.success('Present');
      case 'absent':
        return ApexBadge.danger('Absent');
      case 'late':
        return ApexBadge.warning('Late');
      case 'on_leave':
        return ApexBadge.info('On Leave');
      case 'half_day':
        return ApexBadge.neutral('Half Day');
      default:
        return ApexBadge.neutral(status.replaceAll('_', ' '));
    }
  }
}
