import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

class AttendanceRegularizationScreen extends ConsumerStatefulWidget {
  const AttendanceRegularizationScreen({super.key});
  @override
  ConsumerState<AttendanceRegularizationScreen> createState() => _AttendanceRegularizationScreenState();
}

class _AttendanceRegularizationScreenState extends ConsumerState<AttendanceRegularizationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Attendance Regularization', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showApplyDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _primary,
          unselectedLabelColor: _muted,
          indicatorColor: _primary,
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Pending Approvals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MyRequestsTab(),
          _PendingApprovalsTab(),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context) {
    String requestType = 'missed_check_in';
    final reasonCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? checkInTime;
    TimeOfDay? checkOutTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply Regularization'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: requestType,
                  decoration: const InputDecoration(labelText: 'Request Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'missed_check_in', child: Text('Missed Check-In')),
                    DropdownMenuItem(value: 'missed_check_out', child: Text('Missed Check-Out')),
                    DropdownMenuItem(value: 'wrong_punch', child: Text('Wrong Punch')),
                    DropdownMenuItem(value: 'work_from_home', child: Text('Work From Home')),
                    DropdownMenuItem(value: 'outdoor_duty', child: Text('Outdoor Duty')),
                  ],
                  onChanged: (v) => setDialogState(() => requestType = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date', style: TextStyle(fontSize: 13, color: _muted)),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 14, color: _text)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                if (requestType == 'missed_check_in' || requestType == 'wrong_punch') ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Check-In Time', style: TextStyle(fontSize: 13, color: _muted)),
                    subtitle: Text(checkInTime != null ? checkInTime!.format(ctx) : 'Select time', style: const TextStyle(fontSize: 14, color: _text)),
                    trailing: const Icon(Icons.access_time, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: checkInTime ?? const TimeOfDay(hour: 9, minute: 0));
                      if (picked != null) setDialogState(() => checkInTime = picked);
                    },
                  ),
                ],
                if (requestType == 'missed_check_out' || requestType == 'wrong_punch') ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Check-Out Time', style: TextStyle(fontSize: 13, color: _muted)),
                    subtitle: Text(checkOutTime != null ? checkOutTime!.format(ctx) : 'Select time', style: const TextStyle(fontSize: 14, color: _text)),
                    trailing: const Icon(Icons.access_time, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: checkOutTime ?? const TimeOfDay(hour: 18, minute: 0));
                      if (picked != null) setDialogState(() => checkOutTime = picked);
                    },
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = context.read(dioProvider);
                  await dio.post('/attendance/regularization', data: {
                    'request_type': requestType,
                    'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    'reason': reasonCtrl.text.trim(),
                    if (checkInTime != null) 'check_in': '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}',
                    if (checkOutTime != null) 'check_out': '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}',
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regularization request submitted'), backgroundColor: _success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
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

class _MyRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 48, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No regularization requests', style: TextStyle(fontSize: 15, color: _muted)),
          const SizedBox(height: 8),
          const Text('Apply for missed punches or work from home', style: TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }
}

class _PendingApprovalsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.approval, size: 48, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No pending approvals', style: TextStyle(fontSize: 15, color: _muted)),
          const SizedBox(height: 8),
          const Text('Regularization requests from your team will appear here', style: TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }
}
