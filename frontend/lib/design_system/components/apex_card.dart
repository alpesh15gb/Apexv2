import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';

/// Enterprise Card — Flat, minimal, border-only
class ApexCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? header;
  final Widget? footer;
  final Color? backgroundColor;

  const ApexCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.selected = false,
    this.header,
    this.footer,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<ApexCard> createState() => _ApexCardState();
}

class _ApexCardState extends State<ApexCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: widget.margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? (isDark ? ApexColors.darkSurface : ApexColors.neutral0),
          borderRadius: ApexRadius.mdAll,
          border: Border.all(
            color: widget.selected
                ? ApexColors.primary
                : _hovered
                    ? (isDark ? ApexColors.neutral700 : ApexColors.neutral300)
                    : (isDark ? ApexColors.neutral800 : ApexColors.neutral200),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: ApexRadius.mdAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.header != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: widget.header,
                  ),
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(14),
                  child: widget.child,
                ),
                if (widget.footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: widget.footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
