import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';

/// Enterprise KPI Card — Compact 80px height
/// Left colored bar + value + label + optional trend
class ApexStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isTrendPositive;
  final VoidCallback? onTap;
  final String? subtitle;

  const ApexStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isTrendPositive = true,
    this.onTap,
    this.subtitle,
  }) : super(key: key);

  @override
  State<ApexStatCard> createState() => _ApexStatCardState();
}

class _ApexStatCardState extends State<ApexStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
          borderRadius: ApexRadius.mdAll,
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.3)
                : isDark ? ApexColors.neutral800 : ApexColors.neutral200,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: ApexRadius.mdAll,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Left color bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: ApexRadius.xsAll,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Value + trend
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.value,
                              style: ApexTypography.kpiValue.copyWith(
                                color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                              ),
                            ),
                            if (widget.trend != null) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.isTrendPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 12,
                                      color: widget.isTrendPositive ? ApexColors.success : ApexColors.error,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.trend!,
                                      style: ApexTypography.captionSmall.copyWith(
                                        color: widget.isTrendPositive ? ApexColors.success : ApexColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Label
                        Text(
                          widget.title,
                          style: ApexTypography.kpiLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.color.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
