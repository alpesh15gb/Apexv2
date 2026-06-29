import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class ApexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const ApexAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: ApexTypography.sectionTitle.copyWith(color: ApexColors.gray900)),
      backgroundColor: ApexColors.neutral0,
      foregroundColor: ApexColors.gray900,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: ApexColors.gray200),
      ),
    );
  }
}
