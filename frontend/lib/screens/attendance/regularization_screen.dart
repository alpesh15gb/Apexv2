import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/page_wrapper.dart';

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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Regularization',
        description: 'Correct punch errors, apply for outdoor duty, or work from home.',
        actions: [
          ApexButton(
            label: 'Apply Regularization',
            icon: Icons.add,
            type: ApexButtonType.primary,
            onPressed: () => _showApplyDialog(context),
          ),
        ],
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: ApexColors.primary,
                unselectedLabelColor: ApexColors.neutral500,
                indicatorColor: ApexColors.primary,
                tabs: const [
                  Tab(text: 'My Requests'),
                  Tab(text: 'Pending Approvals'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _MyRequestsTab(),
                  _PendingApprovalsTab(),
                ],
              ),
            ),
          ],
        ),
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
                ApexDropdown<String>(
                  label: 'Request Type',
                  value: requestType,
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
                ApexDatePicker(
                  label: 'Date',
                  value: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedDate = v); },
                ),
                if (requestType == 'missed_check_in' || requestType == 'wrong_punch') ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Check-In Time', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    subtitle: Text(checkInTime != null ? checkInTime!.format(ctx) : 'Select time', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
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
                    title: Text('Check-Out Time', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    subtitle: Text(checkOutTime != null ? checkOutTime!.format(ctx) : 'Select time', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                    trailing: const Icon(Icons.access_time, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: checkOutTime ?? const TimeOfDay(hour: 18, minute: 0));
                      if (picked != null) setDialogState(() => checkOutTime = picked);
                    },
                  ),
                ],
                const SizedBox(height: 8),
                ApexTextField(
                  label: 'Reason',
                  controller: reasonCtrl,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            ApexButton(
              label: 'Cancel',
              type: ApexButtonType.ghost,
              onPressed: () => Navigator.pop(ctx),
            ),
            ApexButton(
              label: 'Submit',
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/attendance/regularization', data: {
                    'request_type': requestType,
                    'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    'reason': reasonCtrl.text.trim(),
                    if (checkInTime != null) 'check_in': '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}',
                    if (checkOutTime != null) 'check_out': '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}',
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regularization request submitted'), backgroundColor: ApexColors.success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
                }
              },
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
          Icon(Icons.edit_note, size: 48, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('No regularization requests', style: ApexTypography.bodyLarge.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 8),
          Text('Apply for missed punches or work from home', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
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
          Icon(Icons.approval, size: 48, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('No pending approvals', style: ApexTypography.bodyLarge.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 8),
          Text('Regularization requests from your team will appear here', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}
