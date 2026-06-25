import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';

/// Apex Design System — Search Bar
///
/// Global search with keyboard shortcut hint (Cmd+K / Ctrl+K).
class ApexSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final ValueChanged<String>? onChanged;
  final bool showShortcut;
  final TextEditingController? controller;

  const ApexSearchBar({
    Key? key,
    this.hintText = 'Search...',
    required this.onSearch,
    this.onChanged,
    this.showShortcut = false,
    this.controller,
  }) : super(key: key);

  @override
  State<ApexSearchBar> createState() => _ApexSearchBarState();
}

class _ApexSearchBarState extends State<ApexSearchBar> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral100,
        borderRadius: ApexRadius.mdAll,
        border: Border.all(
          color: isDark ? ApexColors.neutral700 : ApexColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, size: 20, color: ApexColors.neutral400),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSearch,
              style: ApexTypography.bodyMedium.copyWith(
                color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: ApexTypography.bodyMedium.copyWith(
                  color: ApexColors.neutral400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          if (widget.showShortcut)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? ApexColors.neutral700 : ApexColors.neutral200,
                  borderRadius: ApexRadius.xsAll,
                ),
                child: Text(
                  '⌘K',
                  style: ApexTypography.captionSmall.copyWith(
                    color: ApexColors.neutral500,
                  ),
                ),
              ),
            ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
                widget.onSearch('');
              },
            ),
        ],
      ),
    );
  }
}
