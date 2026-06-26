import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final leaveTypesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/leaves/types');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class LeaveTypesScreen extends ConsumerWidget {
  const LeaveTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Leave Types', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/leaves')),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Type'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            itemBuilder: (context, i) => _LeaveTypeCard(type: types[i], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 64, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Leave Types Configured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          const Text('Create leave types for your organization', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Leave Type'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '12');
    bool carryForward = false;
    bool halfDay = true;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Leave Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Leave Type Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Annual Days *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SwitchListTile(title: const Text('Carry Forward'), value: carryForward, onChanged: (v) => setDialogState(() => carryForward = v), contentPadding: EdgeInsets.zero),
                SwitchListTile(title: const Text('Half Day Allowed'), value: halfDay, onChanged: (v) => setDialogState(() => halfDay = v), contentPadding: EdgeInsets.zero),
                SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setDialogState(() => isActive = v), contentPadding: EdgeInsets.zero),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/leaves/types', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'max_days_per_year': int.tryParse(daysCtrl.text) ?? 12,
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(leaveTypesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave type created'), backgroundColor: _success));
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

class _LeaveTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final WidgetRef ref;

  const _LeaveTypeCard({required this.type, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = type['name'] ?? '';
    final code = type['code'] ?? '';
    final days = type['max_days_per_year'] ?? 0;
    final isActive = type['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(code.isNotEmpty ? code.substring(0, 2) : 'LT', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? _success : _muted).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? _success : _muted)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _infoChip(Icons.calendar_today, '$days days/year'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.repeat, type['carry_forward'] == true ? 'Carry forward' : 'No carry forward'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.access_time, type['half_day_allowed'] == true ? 'Half day OK' : 'Full day only'),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: _muted),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (v) async {
              if (v == 'toggle') {
                final dio = ref.read(dioProvider);
                await dio.put('/leaves/types/${type['id']}', data: {'is_active': !isActive});
                ref.invalidate(leaveTypesProvider);
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
        Icon(icon, size: 12, color: _muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      ],
    );
  }
}
