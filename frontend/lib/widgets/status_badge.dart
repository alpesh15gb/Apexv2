import 'package:flutter/material.dart';
import '../design_system/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    Color badgeColor;
    Color textColor;
    String label = status;

    switch (statusLower) {
      case 'online':
      case 'present':
      case 'active':
      case 'approved':
      case 'paid':
      case 'granted':
      case 'completed':
        badgeColor = ApexColors.success100;
        textColor = ApexColors.success800;
        break;
      case 'offline':
      case 'absent':
      case 'inactive':
      case 'rejected':
      case 'unpaid':
      case 'denied':
      case 'failed':
        badgeColor = ApexColors.error100;
        textColor = ApexColors.error800;
        break;
      case 'pending':
      case 'scheduled':
      case 'requested':
      case 'sent':
        badgeColor = ApexColors.warning100;
        textColor = ApexColors.warning900;
        break;
      case 'cancelled':
      case 'half_day':
      case 'half-day':
      case 'on_leave':
      case 'leave':
        badgeColor = ApexColors.info100;
        textColor = ApexColors.info800;
        if (statusLower == 'half_day') label = 'Half Day';
        if (statusLower == 'on_leave') label = 'On Leave';
        break;
      default:
        badgeColor = ApexColors.gray200;
        textColor = ApexColors.gray700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
