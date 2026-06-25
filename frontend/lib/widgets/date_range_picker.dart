import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePickerWidget extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onRangeSelected;

  const DateRangePickerWidget({
    Key? key,
    required this.selectedRange,
    required this.onRangeSelected,
  }) : super(key: key);

  String get _displayText {
    if (selectedRange == null) {
      return 'Select Date Range';
    }
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(selectedRange!.start)} - ${format.format(selectedRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: selectedRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                appBarTheme: theme.appBarTheme.copyWith(
                  backgroundColor: theme.colorScheme.primary,
                  iconTheme: const IconThemeData(color: Colors.white),
                  titleTextStyle: const TextStyle(color: Colors.white),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onRangeSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _displayText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selectedRange != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  onRangeSelected(null);
                },
              )
            else
              const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
