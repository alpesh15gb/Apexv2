import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class ApexTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool required;
  final bool enabled;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const ApexTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = enabled
        ? (isDark ? ApexColors.darkSurface : ApexColors.neutral0)
        : (isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50);
    final borderColor = isDark ? ApexColors.neutral600 : ApexColors.neutral300;
    final disabledBorderColor = isDark ? ApexColors.neutral700 : ApexColors.neutral200;
    final labelColor = isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500;
    final hintColor = isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral400;
    final iconColor = isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral400;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: ApexTypography.body.copyWith(fontWeight: FontWeight.w500),
      validator: validator ?? (required ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null : null),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        labelStyle: ApexTypography.body.copyWith(color: labelColor),
        floatingLabelStyle: ApexTypography.caption.copyWith(color: isDark ? ApexColors.primary400 : ApexColors.primary, fontWeight: FontWeight.w600),
        hintStyle: ApexTypography.body.copyWith(color: hintColor),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: iconColor) : null,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? ApexColors.primary400 : ApexColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApexColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApexColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: disabledBorderColor, width: 1),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
