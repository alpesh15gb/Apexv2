import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class ApexDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool required;
  final bool enabled;
  final String? Function(T?)? validator;

  const ApexDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = enabled
        ? (isDark ? ApexColors.darkSurface : ApexColors.neutral0)
        : (isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50);

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      dropdownColor: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
      style: ApexTypography.body.copyWith(color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900),
      validator: validator ?? (required ? (v) => v == null ? '$label is required' : null : null),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: ApexTypography.body.copyWith(color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500),
        floatingLabelStyle: ApexTypography.caption.copyWith(color: isDark ? ApexColors.primary400 : ApexColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? ApexColors.neutral600 : ApexColors.neutral300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? ApexColors.neutral600 : ApexColors.neutral300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? ApexColors.primary400 : ApexColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApexColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class ApexDropdownItem<T> extends DropdownMenuItem<T> {
  ApexDropdownItem({
    super.key,
    required T value,
    required String text,
  }) : super(
    value: value,
    child: Text(text, style: ApexTypography.body),
  );
}
