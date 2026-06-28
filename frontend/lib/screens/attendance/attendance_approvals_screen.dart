import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class AttendanceApprovalsScreen extends ConsumerStatefulWidget {
  const AttendanceApprovalsScreen({super.key});

  @override
  ConsumerState<AttendanceApprovalsScreen> createState() => _AttendanceApprovalsScreenState();
}

class _AttendanceApprovalsScreenState extends ConsumerState<AttendanceApprovalsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _requests = [
        {
          'id': 'REQ001',
          'name': 'Rahul Sharma',
          'code': 'EMP001',
          'type': 'Missed Check-In',
          'date': '2026-06-25',
          'reason': 'Device ping failed at HO main entrance',
          'time': '09:05 AM',
        },
        {
          'id': 'REQ002',
          'name': 'Priya Patel',
          'code': 'EMP002',
          'type': 'Missed Check-Out',
          'date': '2026-06-24',
          'reason': 'Left early for client meeting',
          'time': '06:15 PM',
        },
        {
          'id': 'REQ003',
          'name': 'Amit Verma',
          'code': 'EMP003',
          'type': 'Wrong Punch Override',
          'date': '2026-06-23',
          'reason': 'Punched twice incorrectly on device eBioServer HO',
          'time': '01:00 PM',
        },
      ];
      _loading = false;
    });
  }

  void _approve(String id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request Approved successfully'), backgroundColor: ApexColors.success),
    );
  }

  void _reject(String id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request Rejected'), backgroundColor: ApexColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Approvals',
        description: 'Review and act on pending attendance regularization and correction requests.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _requests.isEmpty && !_loading,
        emptyIcon: Icons.how_to_reg_outlined,
        emptyTitle: 'No Pending Approvals',
        emptySubtitle: 'All regularization requests have been processed.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _requests.length,
          itemBuilder: (context, i) {
            final r = _requests[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ApexColors.primary600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_calendar, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r['name']} (${r['code']})', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ApexBadge.neutral((r['type'] as String).toUpperCase()),
                            const SizedBox(width: 8),
                            Text('Date: ${r['date']} • Time: ${r['time']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Reason: "${r['reason']}"', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral600, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ApexButton(
                        label: 'Reject',
                        onPressed: () => _reject(r['id']),
                        type: ApexButtonType.outline,
                      ),
                      const SizedBox(width: 8),
                      ApexButton(
                        label: 'Approve',
                        onPressed: () => _approve(r['id']),
                        type: ApexButtonType.success,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
