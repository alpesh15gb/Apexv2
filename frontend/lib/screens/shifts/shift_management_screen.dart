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

final shiftListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100});
  return res.data['items'] ?? [];
});

class ShiftManagementScreen extends ConsumerWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Shift Management', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.push('/shifts/create'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Shift'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => context.push('/shifts/groups'),
            icon: const Icon(Icons.group_work, size: 16),
            label: const Text('Groups'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/shifts/rosters'),
            icon: const Icon(Icons.calendar_month, size: 16),
            label: const Text('Rosters'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, i) => _ShiftCard(shift: shifts[i]),
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
          Icon(Icons.schedule, size: 64, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Shifts Configured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          const Text('Create shifts to manage employee work schedules', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/shifts/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create First Shift'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final name = shift['name'] ?? '';
    final startTime = shift['start_time'] ?? '09:00';
    final endTime = shift['end_time'] ?? '18:00';
    final grace = shift['grace_period_minutes'] ?? 10;
    final isNight = shift['is_night_shift'] == true;
    final isActive = shift['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isNight ? const Color(0xFF6366F1) : _primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isNight ? Icons.nights_stay : Icons.wb_sunny, color: isNight ? const Color(0xFF6366F1) : _primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(width: 8),
                  if (isNight) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('NIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: (isActive ? _success : _muted).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? _success : _muted)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _infoChip(Icons.access_time, '$startTime - $endTime'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.timer, 'Grace: ${grace}min'),
                  if (shift['overtime_threshold_minutes'] != null) ...[
                    const SizedBox(width: 12),
                    _infoChip(Icons.schedule, 'OT: ${shift['overtime_threshold_minutes']}min'),
                  ],
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: _muted),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'assign', child: Text('Assign Employees')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
            ],
            onSelected: (v) {
              if (v == 'edit') context.push('/shifts/${shift['id']}/edit');
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
