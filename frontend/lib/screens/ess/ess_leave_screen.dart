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

final essLeavesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/leaves');
  return res.data is List ? res.data : [];
});

final essBalanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/leaves/balance');
  return res.data is List ? res.data : [];
});

class EssLeaveScreen extends ConsumerStatefulWidget {
  const EssLeaveScreen({super.key});
  @override
  ConsumerState<EssLeaveScreen> createState() => _EssLeaveScreenState();
}

class _EssLeaveScreenState extends ConsumerState<EssLeaveScreen> {
  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(essLeavesProvider);
    final balanceAsync = ref.watch(essBalanceProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('My Leaves', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showApplyDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Leave Balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          balanceAsync.when(
            data: (balances) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: balances.map((b) => Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b['type'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 4),
                  Text('${(b['available'] ?? 0).toInt()} days left', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                  Text('${(b['used'] ?? 0).toInt()} used of ${(b['total'] ?? 0).toInt()}', style: const TextStyle(fontSize: 11, color: _muted)),
                ]),
              )).toList(),
            ),
            loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: _danger)),
          ),
          const SizedBox(height: 24),
          const Text('Leave History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          leavesAsync.when(
            data: (leaves) {
              if (leaves.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No leave requests', style: TextStyle(color: _muted))));
              return Column(children: leaves.map((l) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${l['start_date']} → ${l['end_date']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    Text(l['reason'] ?? '', style: const TextStyle(fontSize: 12, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _leaveStatusColor(l['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text((l['status'] ?? '').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _leaveStatusColor(l['status']))),
                  ),
                ]),
              )).toList());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ]),
      ),
    );
  }

  Color _leaveStatusColor(String? status) {
    switch (status) {
      case 'approved': return _success;
      case 'rejected': return _danger;
      case 'pending': return _warning;
      default: return _muted;
    }
  }

  void _showApplyDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply Leave'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text('${startDate.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setDialogState(() => startDate = picked);
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text('${endDate.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: endDate, firstDate: startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setDialogState(() => endDate = picked);
              },
            ),
            const SizedBox(height: 8),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/ess/leaves', data: {
                    'start_date': startDate.toIso8601String().substring(0, 10),
                    'end_date': endDate.toIso8601String().substring(0, 10),
                    'reason': reasonCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(essLeavesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave applied!'), backgroundColor: _success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
