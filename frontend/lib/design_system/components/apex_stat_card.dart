import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';
import '../elevation.dart';

/// Apex Design System — Stat Card
///
/// Enhanced stat card with trend, icon, and optional tap handler.
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
          borderRadius: ApexRadius.lgAll,
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.3)
                : isDark
                    ? ApexColors.darkSurfaceVariant
                    : ApexColors.neutral200,
          ),
          boxShadow: _hovered ? ApexElevation.shadowMd : ApexElevation.shadowXs,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: ApexRadius.lgAll,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: ApexTypography.bodyMedium.copyWith(
                            color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: ApexRadius.mdAll,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.value,
                    style: ApexTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: ApexTypography.captionMedium.copyWith(
                        color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500,
                      ),
                    ),
                  ],
                  if (widget.trend != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widget.isTrendPositive ? Icons.trending_up : Icons.trending_down,
                          color: widget.isTrendPositive ? ApexColors.success : ApexColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.trend!,
                          style: ApexTypography.captionLarge.copyWith(
                            color: widget.isTrendPositive ? ApexColors.success : ApexColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
