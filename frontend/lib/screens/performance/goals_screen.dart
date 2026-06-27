import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final goalsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/performance/goals');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Goals & OKRs', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateGoalDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Goal'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
            child: Row(
              children: ['all', 'draft', 'approved', 'completed', 'overdue'].map((s) {
                final isActive = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1), style: TextStyle(fontSize: 12, color: isActive ? _primary : _muted)),
                    selected: isActive,
                    onSelected: (_) => setState(() => _statusFilter = s),
                    selectedColor: _primary.withOpacity(0.1),
                    side: BorderSide(color: isActive ? _primary : _border),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                final filtered = _statusFilter == 'all' ? goals : goals.where((g) => g['status'] == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag, size: 48, color: _muted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                        const SizedBox(height: 4),
                        const Text('Create goals to track performance', style: TextStyle(fontSize: 13, color: _muted)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _GoalDetailCard(goal: filtered[i], ref: ref),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightageCtrl = TextEditingController(text: '0');
    final targetCtrl = TextEditingController();
    String goalType = 'individual';
    String category = 'performance';
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Goal Title *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: goalType,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: ['individual', 'team', 'department', 'company'].map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                    onChanged: (v) => setDialogState(() => goalType = v!),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: weightageCtrl, decoration: const InputDecoration(labelText: 'Weightage %', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: 'Target Value', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date', style: TextStyle(fontSize: 13, color: _muted)),
                  subtitle: Text(dueDate != null ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}' : 'Select date', style: const TextStyle(fontSize: 14, color: _text)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: dueDate ?? DateTime.now().add(const Duration(days: 90)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/performance/goals', data: {
                    'employee_id': '00000000-0000-0000-0000-000000000000',
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'goal_type': goalType,
                    'category': category,
                    'weightage': double.tryParse(weightageCtrl.text) ?? 0,
                    'target_value': double.tryParse(targetCtrl.text),
                    'due_date': dueDate?.toIso8601String().substring(0, 10),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(goalsListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal created'), backgroundColor: _success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDetailCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final WidgetRef ref;

  const _GoalDetailCard({required this.goal, required this.ref});

  @override
  Widget build(BuildContext context) {
    final title = goal['title'] ?? '';
    final description = goal['description'] ?? '';
    final progress = (goal['progress'] as num?)?.toDouble() ?? 0;
    final status = goal['status'] ?? 'draft';
    final dueDate = goal['due_date'] ?? '';
    final weightage = goal['weightage'] ?? 0;
    final targetValue = goal['target_value'];
    final currentValue = goal['current_value'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(_statusIcon(status), size: 20, color: _statusColor(status)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
                  if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 12, color: _muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _infoChip(Icons.track_changes, 'Weightage: $weightage%'),
            const SizedBox(width: 16),
            if (dueDate.isNotEmpty) _infoChip(Icons.calendar_today, 'Due: $dueDate'),
            if (targetValue != null) ...[
              const SizedBox(width: 16),
              _infoChip(Icons.flag, 'Target: $targetValue'),
            ],
            if (currentValue != null) ...[
              const SizedBox(width: 16),
              _infoChip(Icons.trending_up, 'Current: $currentValue'),
            ],
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: _border,
                  color: progress >= 100 ? _success : _primary,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
          ]),
          if (status != 'completed') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateProgress(context, progress),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Update Progress'),
                    style: OutlinedButton.styleFrom(foregroundColor: _primary),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'draft')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveGoal(context),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'completed': return Icons.emoji_events;
      case 'draft': return Icons.edit_note;
      default: return Icons.flag;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return _primary;
      case 'completed': return _success;
      case 'draft': return _muted;
      case 'overdue': return _danger;
      default: return _muted;
    }
  }

  void _updateProgress(BuildContext context, double currentProgress) {
    final progressCtrl = TextEditingController(text: currentProgress.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: progressCtrl,
          decoration: const InputDecoration(labelText: 'Progress %', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.put('/performance/goals/${goal['id']}/progress', data: {
                  'progress': double.tryParse(progressCtrl.text) ?? 0,
                });
                Navigator.pop(ctx);
                ref.invalidate(goalsListProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress updated'), backgroundColor: _success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _approveGoal(BuildContext context) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/performance/goals/${goal['id']}/approve');
      ref.invalidate(goalsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal approved'), backgroundColor: _success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
    }
  }
}
