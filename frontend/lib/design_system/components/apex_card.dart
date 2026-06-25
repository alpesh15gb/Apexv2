import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../elevation.dart';

/// Apex Design System — Card Component
///
/// Consistent card with hover states, padding, and optional header.
class ApexCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool selected;
  final bool elevated;
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
    this.elevated = false,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark ? ApexColors.darkSurface : ApexColors.neutral0);

    final borderColor = widget.selected
        ? ApexColors.primary
        : _hovered
            ? ApexColors.neutral300
            : ApexColors.neutral200;

    final shadows = widget.elevated
        ? ApexElevation.shadowMd
        : _hovered
            ? ApexElevation.shadowSm
            : ApexElevation.shadowXs;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: widget.margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: ApexRadius.lgAll,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: ApexRadius.lgAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.header != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: widget.header,
                  ),
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
                if (widget.footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
