import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

/// Enterprise-grade KPI stat card for dashboards
/// Used in Attendance Dashboard and other analytics screens
class ApexStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ApexStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = ApexColors.primary,
    this.onTap,
    this.trailing,
  });

  /// Factory constructors for common status types
  factory ApexStatCard.present({required String value, VoidCallback? onTap}) =>
      ApexStatCard(
        title: 'Present',
        value: value,
        icon: Icons.check_circle_outline,
        accentColor: ApexColors.success,
        onTap: onTap,
      );

  factory ApexStatCard.absent({required String value, VoidCallback? onTap}) =>
      ApexStatCard(
        title: 'Absent',
        value: value,
        icon: Icons.cancel_outlined,
        accentColor: ApexColors.error,
        onTap: onTap,
      );

  factory ApexStatCard.late({required String value, VoidCallback? onTap}) =>
      ApexStatCard(
        title: 'Late',
        value: value,
        icon: Icons.access_time,
        accentColor: ApexColors.warning,
        onTap: onTap,
      );

  factory ApexStatCard.onLeave({required String value, VoidCallback? onTap}) =>
      ApexStatCard(
        title: 'On Leave',
        value: value,
        icon: Icons.beach_access,
        accentColor: ApexColors.info,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final iconBgColor = accentColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ApexColors.neutral0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ApexColors.neutral200, width: 1),
          boxShadow: [
            BoxShadow(
              color: ApexColors.neutral900.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Value and label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: ApexTypography.dashboardKpiValue.copyWith(
                      color: accentColor,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: ApexTypography.dashboardKpiLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Optional trailing widget
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact stat card for smaller spaces
class ApexStatCardCompact extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const ApexStatCardCompact({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = ApexColors.primary,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: ApexTypography.dashboardKpiValue.copyWith(
              color: accentColor,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: ApexTypography.captionMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}