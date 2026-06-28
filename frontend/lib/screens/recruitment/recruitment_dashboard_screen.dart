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

final recruitmentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/recruitment/stats');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final openingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/recruitment/openings');
    return res.data['items'] ?? [];
  } catch (e) {
    return [];
  }
});

final pipelineProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/recruitment/pipeline');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class RecruitmentDashboardScreen extends ConsumerWidget {
  const RecruitmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(recruitmentStatsProvider);
    final openingsAsync = ref.watch(openingsProvider);
    final pipelineAsync = ref.watch(pipelineProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: const Text('Recruitment', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/recruitment/candidates'),
            icon: const Icon(Icons.people, size: 16),
            label: const Text('Candidates'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/recruitment/interviews'),
            icon: const Icon(Icons.event, size: 16),
            label: const Text('Interviews'),
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
            const SizedBox(height: 16),
            _SectionHeader(title: 'Recruitment Pipeline', action: 'View All', onTap: () => context.push('/recruitment/candidates')),
            const SizedBox(height: 8),
            pipelineAsync.when(
              data: (pipeline) => _PipelineView(stages: pipeline),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Open Positions', action: 'New Opening', onTap: () => _showCreateOpeningDialog(context, ref)),
            const SizedBox(height: 8),
            openingsAsync.when(
              data: (openings) {
                if (openings.isEmpty) return _emptyCard('No open positions', 'Create a job opening to start recruiting');
                return Column(
                  children: openings.map((o) => _OpeningCard(opening: o)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOpeningDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String empType = 'permanent';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Job Opening'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: empType,
                  decoration: const InputDecoration(labelText: 'Employment Type', border: OutlineInputBorder()),
                  items: ['permanent', 'contract', 'intern', 'consultant'].map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                  onChanged: (v) => setDialogState(() => empType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/recruitment/openings', data: {
                    'title': titleCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'employment_type': empType,
                    'description': descCtrl.text.trim(),
                    'openings': 1,
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(openingsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening created'), backgroundColor: ApexColors.successDark));
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

  Widget _emptyCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
      child: Center(
        child: Column(children: [
          Icon(Icons.work_off, size: 40, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(title, style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
          Text(subtitle, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ]),
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
      _StatCard(title: 'Open Positions', value: '${stats['open_positions'] ?? 0}', icon: Icons.work, color: ApexColors.primary600),
      _StatCard(title: 'Active Candidates', value: '${stats['active_candidates'] ?? 0}', icon: Icons.people, color: ApexColors.successDark),
      _StatCard(title: 'Interviews', value: '${stats['interviews_scheduled'] ?? 0}', icon: Icons.event, color: ApexColors.warning),
      _StatCard(title: 'Offers', value: '${stats['offers_released'] ?? 0}', icon: Icons.description, color: ApexColors.primary600),
      _StatCard(title: 'Hired', value: '${stats['hired_this_month'] ?? 0}', icon: Icons.check_circle, color: ApexColors.successDark),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 5,
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

class _PipelineView extends StatelessWidget {
  final List<dynamic> stages;
  const _PipelineView({required this.stages});

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stages.map((s) {
          final count = s['count'] ?? 0;
          final stage = s['stage'] ?? '';
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ApexColors.neutral0,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ApexColors.neutral200),
            ),
            child: Column(
              children: [
                Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: count > 0 ? ApexColors.primary600 : ApexColors.neutral500)),
                const SizedBox(height: 4),
                Text(_stageName(stage), style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _stageName(String stage) {
    return stage.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

class _OpeningCard extends ConsumerWidget {
  final Map<String, dynamic> opening;
  const _OpeningCard({required this.opening});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = opening['title'] ?? '';
    final status = opening['status'] ?? 'draft';
    final candidates = opening['candidates'] ?? 0;
    final openings = opening['openings'] ?? 1;
    final location = opening['location'] ?? '';

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
            child: Icon(Icons.work, size: 22, color: ApexColors.primary600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (location.isNotEmpty) _infoChip(Icons.location_on, location),
                  const SizedBox(width: 12),
                  _infoChip(Icons.people, '$candidates applicants'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.work, '$openings openings'),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: ApexColors.neutral500),
            itemBuilder: (ctx) => [
              if (status == 'draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
              if (status == 'published') const PopupMenuItem(value: 'close', child: Text('Close')),
              const PopupMenuItem(value: 'candidates', child: Text('View Candidates')),
            ],
            onSelected: (v) async {
              if (v == 'publish') {
                final dio = ref.read(dioProvider);
                await dio.post('/recruitment/openings/${opening['id']}/publish');
              } else if (v == 'close') {
                final dio = ref.read(dioProvider);
                await dio.post('/recruitment/openings/${opening['id']}/close');
              } else if (v == 'candidates') {
                context.push('/recruitment/candidates?opening=${opening['id']}');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ApexColors.neutral500),
        const SizedBox(width: 4),
        Text(label, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'published': return ApexColors.successDark;
      case 'closed': return ApexColors.error;
      case 'draft': return ApexColors.neutral500;
      default: return ApexColors.neutral500;
    }
  }
}

