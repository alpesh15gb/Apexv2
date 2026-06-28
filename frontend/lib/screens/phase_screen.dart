import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../widgets/page_wrapper.dart';

/// Rendered at routes whose full implementation is planned for a later phase.
/// Uses [ApexPageWrapper] — has the correct title, breadcrumbs, and chrome.
/// Shows an informative empty state rather than a crash or a blank screen.
class ApexPhaseScreen extends StatelessWidget {
  const ApexPhaseScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.features = const [],
  });

  final String title;
  final String description;
  final IconData icon;

  /// Bullet list of capabilities this screen will provide.
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return ApexPageWrapper(
      title: title,
      description: description,
      body: const SizedBox.shrink(),
      isEmpty: true,
      emptyIcon: icon,
      emptyTitle: 'No data yet',
      emptySubtitle: description,
      emptyAction: features.isEmpty
          ? null
          : _FeatureList(features: features),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features});
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ApexColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This screen will include:',
              style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: ApexColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: ApexTypography.captionMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
