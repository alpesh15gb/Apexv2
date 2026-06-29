import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

enum ApexButtonType { primary, secondary, outline, danger, success, ghost }

class ApexButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ApexButtonType type;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  const ApexButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ApexButtonType.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: type == ApexButtonType.primary || type == ApexButtonType.danger || type == ApexButtonType.success
                  ? ApexColors.neutral0
                  : ApexColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    switch (type) {
      case ApexButtonType.primary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ApexColors.primary,
              foregroundColor: ApexColors.neutral0,
              disabledBackgroundColor: ApexColors.neutral300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
      case ApexButtonType.secondary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ApexColors.neutral100,
              foregroundColor: ApexColors.neutral700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
      case ApexButtonType.outline:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ApexColors.primary,
              side: BorderSide(color: ApexColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
      case ApexButtonType.danger:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ApexColors.error,
              foregroundColor: ApexColors.neutral0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
      case ApexButtonType.success:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ApexColors.success,
              foregroundColor: ApexColors.neutral0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
      case ApexButtonType.ghost:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 44,
          child: TextButton(
            onPressed: loading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: ApexColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: ApexTypography.button,
            ),
            child: child,
          ),
        );
    }
  }
}
