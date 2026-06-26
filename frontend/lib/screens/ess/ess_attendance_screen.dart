import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final essAttendanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/attendance');
  return res.data is List ? res.data : [];
});

class EssAttendanceScreen extends ConsumerWidget {
  const EssAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(essAttendanceProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => _clockIn(context, ref),
            icon: const Icon(Icons.login, size: 16, color: _success),
            label: const Text('Clock In', style: TextStyle(color: _success)),
          ),
          TextButton.icon(
            onPressed: () => _clockOut(context, ref),
            icon: const Icon(Icons.logout, size: 16, color: _danger),
            label: const Text('Clock Out', style: TextStyle(color: _danger)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: attAsync.when(
        data: (records) {
          if (records.isEmpty) return const Center(child: Text('No attendance records', style: TextStyle(color: _muted)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final r = records[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _statusColor(r['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text((r['date'] ?? '').substring(8, 10), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _statusColor(r['status'])))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['date'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    Text('${r['check_in'] ?? '—'} → ${r['check_out'] ?? '—'}', style: const TextStyle(fontSize: 12, color: _muted)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor(r['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text((r['status'] ?? '').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(r['status']))),
                    ),
                    if (r['working_hours'] != null) ...[
                      const SizedBox(height: 4),
                      Text('${r['working_hours']}h', style: const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ]),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return _success;
      case 'absent': return _danger;
      case 'late': return const Color(0xFFF59E0B);
      default: return _muted;
    }
  }

  void _clockIn(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-in');
      ref.invalidate(essAttendanceProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in!'), backgroundColor: _success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
    }
  }

  void _clockOut(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-out');
      ref.invalidate(essAttendanceProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out!'), backgroundColor: _success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
    }
  }
}
