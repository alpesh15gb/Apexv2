import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class ApexSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const ApexSection({super.key, required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: ApexTypography.sectionHeader),
              Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
