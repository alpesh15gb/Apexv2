import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import 'apex_button.dart';

/// Enterprise-grade filter toolbar for data tables
/// Provides consistent styling for date, dropdown, and search filters
class ApexFilterToolbar extends StatelessWidget {
  final List<ApexFilter> filters;
  final VoidCallback? onReset;
  final VoidCallback? onApply;
  final bool showApplyButton;
  final EdgeInsetsGeometry? padding;

  const ApexFilterToolbar({
    super.key,
    required this.filters,
    this.onReset,
    this.onApply,
    this.showApplyButton = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ApexColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              ...filters.map(
                (filter) => _FilterWrapper(
                  width: filter.width ?? fullWidth,
                  child: filter.builder(),
                ),
              ),
              if (onReset != null)
                ApexButton(
                  label: 'Reset',
                  type: ApexButtonType.ghost,
                  onPressed: onReset,
                  icon: Icons.refresh,
                ),
              if (showApplyButton && onApply != null)
                ApexButton(
                  label: 'Apply',
                  type: ApexButtonType.primary,
                  onPressed: onApply,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterWrapper extends StatelessWidget {
  final Widget child;
  final double? width;

  const _FilterWrapper({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    if (width == null) {
      return child;
    }
    return SizedBox(
      width: width,
      child: child,
    );
  }
}

/// Filter configuration
class ApexFilter {
  final String label;
  final double? width;
  final Widget Function() builder;

  const ApexFilter({
    required this.label,
    this.width,
    required this.builder,
  });

  /// Date filter
  factory ApexFilter.date({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    double? width = 180,
  }) {
    return ApexFilter(
      label: label,
      width: width,
      builder: () => ApexDateFilter(
        label: label,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Dropdown filter
  factory ApexFilter.dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    double? width = 200,
  }) {
    return ApexFilter(
      label: label,
      width: width,
      builder: () => ApexDropdownFilter(
        label: label,
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  /// Search filter
  factory ApexFilter.search({
    required String label,
    required String hintText,
    required ValueChanged<String> onChanged,
    TextEditingController? controller,
    double? width = 240,
  }) {
    return ApexFilter(
      label: label,
      width: width,
      builder: () => ApexSearchFilter(
        label: label,
        hintText: hintText,
        onChanged: onChanged,
        controller: controller,
      ),
    );
  }
}

/// Date filter widget
class ApexDateFilter extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const ApexDateFilter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ApexTypography.captionMedium.copyWith(
            color: ApexColors.gray600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: ApexColors.primary,
                      ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ApexColors.neutral0,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ApexColors.neutral300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(value),
                    style: ApexTypography.body,
                  ),
                ),
                Icon(Icons.calendar_today, size: 18, color: ApexColors.gray500),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown filter widget
class ApexDropdownFilter extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const ApexDropdownFilter({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ApexTypography.captionMedium.copyWith(
            color: ApexColors.gray600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: ApexColors.neutral0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ApexColors.neutral300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.expand_more, color: ApexColors.gray500, size: 20),
              style: ApexTypography.body,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Search filter widget
class ApexSearchFilter extends StatefulWidget {
  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const ApexSearchFilter({
    super.key,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  @override
  State<ApexSearchFilter> createState() => _ApexSearchFilterState();
}

class _ApexSearchFilterState extends State<ApexSearchFilter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: ApexTypography.captionMedium.copyWith(
            color: ApexColors.gray600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: ApexTypography.body.copyWith(color: ApexColors.gray400),
            prefixIcon: Icon(Icons.search, size: 20, color: ApexColors.gray500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ApexColors.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ApexColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ApexColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: ApexColors.neutral0,
          ),
          style: ApexTypography.body,
        ),
      ],
    );
  }
}