import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class ApexDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ApexDatePicker({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.required = false,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1950),
          lastDate: lastDate ?? DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: ApexColors.primary,
                  onPrimary: ApexColors.neutral0,
                  surface: ApexColors.neutral0,
                  onSurface: ApexColors.neutral900,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged?.call(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: ApexTypography.body.copyWith(color: ApexColors.neutral500),
          floatingLabelStyle: ApexTypography.caption.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ApexColors.neutral300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ApexColors.neutral300, width: 1.5),
          ),
          filled: true,
          fillColor: ApexColors.neutral0,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: Icon(Icons.calendar_today, size: 18, color: ApexColors.neutral400),
        ),
        child: Text(
          value != null ? DateFormat('MMM dd, yyyy').format(value!) : 'Select date',
          style: ApexTypography.body.copyWith(
            color: value != null ? ApexColors.neutral900 : ApexColors.neutral400,
            fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
