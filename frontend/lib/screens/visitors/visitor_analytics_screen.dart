import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_card.dart';

class VisitorAnalyticsScreen extends ConsumerWidget {
  const VisitorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Visitor Analytics',
        description: 'Track guest footfalls trends, average durations, and check-in peak hours.',
        body: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _AnalyticsCard(
              title: 'Average Visit Duration',
              value: '1h 45m',
              icon: Icons.timer,
              color: ApexColors.primary600,
            ),
            _AnalyticsCard(
              title: 'Peak Check-In Hours',
              value: '10:00 AM – 11:30 AM',
              icon: Icons.access_time,
              color: ApexColors.warning,
            ),
            _AnalyticsCard(
              title: 'Total Guests (This Month)',
              value: '154',
              icon: Icons.people_outline,
              color: ApexColors.success,
            ),
            _AnalyticsCard(
              title: 'Frequent Purpose of Visit',
              value: 'Client Business Meeting',
              icon: Icons.business,
              color: ApexColors.primary500,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: ApexTypography.sectionTitle.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: ApexColors.neutral900)),
          const SizedBox(height: 4),
          Text(title, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}
