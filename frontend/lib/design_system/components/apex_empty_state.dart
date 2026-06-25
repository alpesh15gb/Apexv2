import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';

/// Apex Design System — Empty State
///
/// Consistent empty state with illustration, title, description, and action.
class ApexEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  const ApexEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.illustration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: ApexSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isDark ? ApexColors.neutral500 : ApexColors.neutral400,
                ),
              ),
            ApexSpacing.gapLg,
            Text(
              title,
              style: ApexTypography.headingMedium.copyWith(
                color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral800,
              ),
              textAlign: TextAlign.center,
            ),
            ApexSpacing.gapSm,
            Text(
              description,
              style: ApexTypography.bodyMedium.copyWith(
                color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              ApexSpacing.gapLg,
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
