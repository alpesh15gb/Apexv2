import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

enum ApexBadgeType { success, warning, danger, info, neutral }

class ApexBadge extends StatelessWidget {
  final String label;
  final ApexBadgeType type;

  const ApexBadge({super.key, required this.label, this.type = ApexBadgeType.neutral});

  factory ApexBadge.success(String label) => ApexBadge(label: label, type: ApexBadgeType.success);
  factory ApexBadge.warning(String label) => ApexBadge(label: label, type: ApexBadgeType.warning);
  factory ApexBadge.danger(String label) => ApexBadge(label: label, type: ApexBadgeType.danger);
  factory ApexBadge.info(String label) => ApexBadge(label: label, type: ApexBadgeType.info);

  @override
  Widget build(BuildContext context) {
    final colors = {
      ApexBadgeType.success: (bg: ApexColors.success.withValues(alpha: 0.1), fg: ApexColors.success),
      ApexBadgeType.warning: (bg: ApexColors.warning.withValues(alpha: 0.1), fg: ApexColors.warning),
      ApexBadgeType.danger: (bg: ApexColors.error.withValues(alpha: 0.1), fg: ApexColors.error),
      ApexBadgeType.info: (bg: ApexColors.primary.withValues(alpha: 0.1), fg: ApexColors.primary),
      ApexBadgeType.neutral: (bg: ApexColors.neutral100, fg: ApexColors.neutral600),
    };
    final c = colors[type]!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: ApexTypography.captionSmall.copyWith(color: c.fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
