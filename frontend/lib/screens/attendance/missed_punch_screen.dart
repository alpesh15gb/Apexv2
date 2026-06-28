import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class MissedPunchScreen extends ConsumerStatefulWidget {
  const MissedPunchScreen({super.key});

  @override
  ConsumerState<MissedPunchScreen> createState() => _MissedPunchScreenState();
}

class _MissedPunchScreenState extends ConsumerState<MissedPunchScreen> {
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
          'id': 'MP001',
          'name': 'Rahul Sharma',
          'code': 'EMP001',
          'date': '2026-06-25',
          'type': 'Check-Out Missing',
          'time': '06:00 PM',
          'status': 'pending',
          'reason': 'Power failure in biometric device eBioServer HO',
        },
        {
          'id': 'MP002',
          'name': 'Priya Patel',
          'code': 'EMP002',
          'date': '2026-06-24',
          'type': 'Check-In Missing',
          'time': '09:00 AM',
          'status': 'approved',
          'reason': 'Forgot card, marked presence manually',
        },
      ];
      _loading = false;
    });
  }

  void _approve(String id) {
    setState(() {
      _requests = _requests.map((r) => r['id'] == id ? {...r, 'status': 'approved'} : r).toList();
    });
  }

  void _reject(String id) {
    setState(() {
      _requests = _requests.map((r) => r['id'] == id ? {...r, 'status': 'rejected'} : r).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Missed Punch Queue',
        description: 'Review and approve missed check-in and check-out requests from biometric terminals.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _requests.isEmpty && !_loading,
        emptyIcon: Icons.fingerprint,
        emptyTitle: 'No Missed Punches',
        emptySubtitle: 'All single-punch regularizations are processed.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _requests.length,
          itemBuilder: (context, i) {
            final r = _requests[i];
            final badge = r['status'] == 'approved'
                ? ApexBadge.success('APPROVED')
                : r['status'] == 'rejected'
                    ? ApexBadge.danger('REJECTED')
                    : ApexBadge.warning('PENDING');
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
                    child: const Icon(Icons.fingerprint, color: ApexColors.primary600, size: 20),
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
                            Text('Date: ${r['date']} • Punch: ${r['time']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Reason: "${r['reason']}"', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral600, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  badge,
                  if (r['status'] == 'pending') ...[
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.check, size: 18, color: ApexColors.success), onPressed: () => _approve(r['id'])),
                    IconButton(icon: const Icon(Icons.close, size: 18, color: ApexColors.error), onPressed: () => _reject(r['id'])),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
