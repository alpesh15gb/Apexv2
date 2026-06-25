import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';
import '../status_colors.dart';

/// Enterprise Badge — Compact status indicator
class ApexBadge extends StatelessWidget {
  final String status;
  final String category;
  final bool dot;
  final bool outlined;

  const ApexBadge({
    Key? key,
    required this.status,
    this.category = 'attendance',
    this.dot = false,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = ApexStatusColors.getColor(category, status);
    final lightColor = ApexStatusColors.getLightColor(category, status);
    final label = _getLabel();

    if (dot) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: ApexTypography.captionSmall.copyWith(color: color)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : lightColor,
        borderRadius: ApexRadius.smAll,
        border: outlined ? Border.all(color: color, width: 1) : null,
      ),
      child: Text(
        label,
        style: ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _getLabel() {
    switch (category) {
      case 'attendance':
        return ApexStatusColors.attendanceLabels[status] ?? status;
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
