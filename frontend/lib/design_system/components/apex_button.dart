import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';

/// Apex Design System — Button Variants
enum ApexButtonVariant { primary, secondary, ghost, danger, success }

enum ApexButtonSize { sm, md, lg }

class ApexButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ApexButtonVariant variant;
  final ApexButtonSize size;
  final bool loading;
  final bool fullWidth;

  const ApexButton({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ApexButtonVariant.primary,
    this.size = ApexButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  }) : super(key: key);

  const ApexButton.primary({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = ApexButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  }) : variant = ApexButtonVariant.primary, super(key: key);

  const ApexButton.secondary({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = ApexButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  }) : variant = ApexButtonVariant.secondary, super(key: key);

  const ApexButton.ghost({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = ApexButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  }) : variant = ApexButtonVariant.ghost, super(key: key);

  const ApexButton.danger({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = ApexButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  }) : variant = ApexButtonVariant.danger, super(key: key);

  @override
  State<ApexButton> createState() => _ApexButtonState();
}

class _ApexButtonState extends State<ApexButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: _hovered ? colors.hoverBackground : colors.background,
          borderRadius: ApexRadius.mdAll,
          border: Border.all(color: colors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.loading ? null : widget.onPressed,
            borderRadius: ApexRadius.mdAll,
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.loading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.foreground),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: colors.foreground),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label, style: textStyle.copyWith(color: colors.foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonColors _getColors() {
    switch (widget.variant) {
      case ApexButtonVariant.primary:
        return _ButtonColors(
          background: ApexColors.primary,
          hoverBackground: ApexColors.primary700,
          foreground: Colors.white,
          border: ApexColors.primary,
        );
      case ApexButtonVariant.secondary:
        return _ButtonColors(
          background: ApexColors.neutral0,
          hoverBackground: ApexColors.neutral50,
          foreground: ApexColors.neutral700,
          border: ApexColors.neutral300,
        );
      case ApexButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          hoverBackground: ApexColors.neutral100,
          foreground: ApexColors.neutral700,
          border: Colors.transparent,
        );
      case ApexButtonVariant.danger:
        return _ButtonColors(
          background: ApexColors.error,
          hoverBackground: ApexColors.errorDark,
          foreground: Colors.white,
          border: ApexColors.error,
        );
      case ApexButtonVariant.success:
        return _ButtonColors(
          background: ApexColors.success,
          hoverBackground: ApexColors.successDark,
          foreground: Colors.white,
          border: ApexColors.success,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ApexButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ApexButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ApexButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ApexButtonSize.sm:
        return ApexTypography.buttonSmall;
      case ApexButtonSize.md:
        return ApexTypography.buttonMedium;
      case ApexButtonSize.lg:
        return ApexTypography.buttonLarge;
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color hoverBackground;
  final Color foreground;
  final Color border;

  _ButtonColors({
    required this.background,
    required this.hoverBackground,
    required this.foreground,
    required this.border,
  });
}
