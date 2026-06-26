import 'package:flutter/material.dart';
import '../design_system/typography.dart';

const _text = Color(0xFF111827);
const _border = Color(0xFFE5E7EB);

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
      title: Text(title, style: ApexTypography.sectionTitle.copyWith(color: _text)),
      backgroundColor: Colors.white,
      foregroundColor: _text,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _border),
      ),
    );
  }
}
