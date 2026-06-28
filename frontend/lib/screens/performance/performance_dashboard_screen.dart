import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

final performanceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/performance/stats');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final cyclesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/performance/cycles');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

final goalsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/performance/goals');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class PerformanceDashboardScreen extends ConsumerWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(performanceStatsProvider);
    final cyclesAsync = ref.watch(cyclesProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: const Text('Performance', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/performance/goals'),
            icon: const Icon(Icons.flag, size: 16),
            label: const Text('Goals'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/performance/reviews'),
            icon: const Icon(Icons.rate_review, size: 16),
            label: const Text('Reviews'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/performance/competencies'),
            icon: const Icon(Icons.psychology, size: 16),
            label: const Text('Competencies'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _StatsRow(stats: stats, isMobile: isMobile),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Review Cycles', action: 'New Cycle', onTap: () => _showCreateCycleDialog(context, ref)),
            const SizedBox(height: 8),
            cyclesAsync.when(
              data: (cycles) {
                if (cycles.isEmpty) return _emptyCard('No Review Cycles', 'Create a review cycle to start performance evaluations');
                return Column(children: cycles.map((c) => _CycleCard(cycle: c)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'My Goals', action: 'View All', onTap: () => context.push('/performance/goals')),
            const SizedBox(height: 8),
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) return _emptyCard('No Goals', 'Goals will appear here when assigned');
                return Column(children: goals.take(5).map((g) => _GoalCard(goal: g)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
      child: Center(
        child: Column(children: [
          Icon(Icons.assessment, size: 40, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(title, style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
          Text(subtitle, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ]),
      ),
    );
  }

  void _showCreateCycleDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String cycleType = 'quarterly';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Review Cycle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Cycle Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cycleType,
                  decoration: const InputDecoration(labelText: 'Cycle Type', border: OutlineInputBorder()),
                  items: ['monthly', 'quarterly', 'half_yearly', 'annual'].map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => cycleType = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
                  subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
                  subtitle: Text('${endDate.day}/${endDate.month}/${endDate.year}', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/performance/cycles', data: {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'cycle_type': cycleType,
                    'start_date': startDate.toIso8601String().substring(0, 10),
                    'end_date': endDate.toIso8601String().substring(0, 10),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(cyclesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review cycle created'), backgroundColor: ApexColors.successDark));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isMobile;

  const _StatsRow({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(title: 'Active Cycles', value: '${stats['active_cycles'] ?? 0}', icon: Icons.loop, color: ApexColors.primary600),
      _StatCard(title: 'Goals', value: '${stats['total_goals'] ?? 0}', icon: Icons.flag, color: ApexColors.successDark),
      _StatCard(title: 'Goals Completed', value: '${stats['completed_goals'] ?? 0}', icon: Icons.check_circle, color: ApexColors.successDark),
      _StatCard(title: 'Pending Reviews', value: '${stats['pending_reviews'] ?? 0}', icon: Icons.pending, color: ApexColors.warning),
      _StatCard(title: 'Completed Reviews', value: '${stats['completed_reviews'] ?? 0}', icon: Icons.done_all, color: ApexColors.primary600),
      _StatCard(title: 'Avg Rating', value: '${stats['average_rating'] ?? 0}', icon: Icons.star, color: ApexColors.warning),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 3,
        child: c,
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
        const Spacer(),
        TextButton(onPressed: onTap, child: Text(action, style: ApexTypography.caption)),
      ],
    );
  }
}

class _CycleCard extends ConsumerWidget {
  final Map<String, dynamic> cycle;
  const _CycleCard({required this.cycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = cycle['name'] ?? '';
    final type = cycle['cycle_type'] ?? '';
    final status = cycle['status'] ?? 'draft';
    final startDate = cycle['start_date'] ?? '';
    final endDate = cycle['end_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.loop, size: 22, color: ApexColors.primary600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('$startDate → $endDate • ${type.replaceAll('_', ' ')}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
          if (status == 'draft')
            ElevatedButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                await dio.post('/performance/cycles/${cycle['id']}/publish');
              },
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              child: const Text('Publish', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'published': return ApexColors.primary600;
      case 'completed': return ApexColors.successDark;
      case 'draft': return ApexColors.neutral500;
      default: return ApexColors.neutral500;
    }
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final title = goal['title'] ?? '';
    final progress = (goal['progress'] as num?)?.toDouble() ?? 0;
    final status = goal['status'] ?? 'draft';
    final dueDate = goal['due_date'] ?? '';
    final weightage = goal['weightage'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('Weightage: ${weightage}%', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            const SizedBox(width: 16),
            if (dueDate.isNotEmpty) Text('Due: $dueDate', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: ApexColors.neutral200,
                  color: progress >= 100 ? ApexColors.successDark : ApexColors.primary600,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${progress.toStringAsFixed(0)}%', style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
          ]),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return ApexColors.primary600;
      case 'completed': return ApexColors.successDark;
      case 'draft': return ApexColors.neutral500;
      default: return ApexColors.neutral500;
    }
  }
}

