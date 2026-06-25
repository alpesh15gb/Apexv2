import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';

/// Apex Design System — Breadcrumb
///
/// Navigation breadcrumb trail.
class ApexBreadcrumb extends StatelessWidget {
  final List<ApexBreadcrumbItem> items;

  const ApexBreadcrumb({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? ApexColors.neutral600 : ApexColors.neutral400,
              ),
            ),
          if (i == items.length - 1)
            Text(
              items[i].label,
              style: ApexTypography.bodySmall.copyWith(
                color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral800,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: items[i].onTap,
                child: Text(
                  items[i].label,
                  style: ApexTypography.bodySmall.copyWith(
                    color: isDark ? ApexColors.primary400 : ApexColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class ApexBreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const ApexBreadcrumbItem({
    required this.label,
    this.onTap,
  });
}
