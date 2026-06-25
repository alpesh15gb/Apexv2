import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';

/// Apex Design System — Filter Bar
///
/// Horizontal scrollable filter chips with clear all.
class ApexFilterBar extends StatelessWidget {
  final List<ApexFilter> filters;
  final VoidCallback? onClearAll;

  const ApexFilterBar({
    Key? key,
    required this.filters,
    this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeFilters = filters.where((f) => f.isSelected).toList();

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: filter.isSelected,
                    onSelected: filter.onToggle,
                    selectedColor: ApexColors.primary100,
                    checkmarkColor: ApexColors.primary,
                    labelStyle: ApexTypography.captionLarge.copyWith(
                      color: filter.isSelected ? ApexColors.primary : ApexColors.neutral600,
                      fontWeight: filter.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: ApexRadius.mdAll,
                      side: BorderSide(
                        color: filter.isSelected ? ApexColors.primary : ApexColors.neutral300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (activeFilters.isNotEmpty && onClearAll != null)
          TextButton(
            onPressed: onClearAll,
            child: Text(
              'Clear all',
              style: ApexTypography.captionLarge.copyWith(color: ApexColors.error),
            ),
          ),
      ],
    );
  }
}

class ApexFilter {
  final String label;
  final bool isSelected;
  final void Function(bool) onToggle;

  const ApexFilter({
    required this.label,
    required this.isSelected,
    required this.onToggle,
  });
}
