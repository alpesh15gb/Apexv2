import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class IllegalLogsScreen extends ConsumerStatefulWidget {
  const IllegalLogsScreen({super.key});

  @override
  ConsumerState<IllegalLogsScreen> createState() => _IllegalLogsScreenState();
}

class _IllegalLogsScreenState extends ConsumerState<IllegalLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
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
      _logs = [
        {
          'id': 'ILL001',
          'time': '2026-06-25 10:14 PM',
          'device': 'Factory Gate 1 Turnstile',
          'reason': 'Unregistered RFID Card Swiped',
          'card_no': 'CARD_29013A',
          'severity': 'high',
        },
        {
          'id': 'ILL002',
          'time': '2026-06-25 08:33 PM',
          'device': 'HO Main Entrance Face Terminal',
          'reason': 'Face Matching Quality Below 40%',
          'card_no': 'Unknown User Face Scan',
          'severity': 'medium',
        },
        {
          'id': 'ILL003',
          'time': '2026-06-25 04:12 PM',
          'device': 'Server Room Door Controller',
          'reason': 'Access Denied - Insufficient Permissions',
          'card_no': 'EMP003 Card Swipe',
          'severity': 'critical',
        },
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Illegal Access Logs',
        description: 'Review security alerts, failed pin trials, card reading mismatches, and access violations.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _logs.isEmpty && !_loading,
        emptyIcon: Icons.warning_outlined,
        emptyTitle: 'No Violations Detected',
        emptySubtitle: 'All device locks and card swipes checks have passed.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _logs.length,
          itemBuilder: (context, i) {
            final l = _logs[i];
            final badge = l['severity'] == 'critical'
                ? ApexBadge.danger('CRITICAL')
                : l['severity'] == 'high'
                    ? ApexBadge.danger('HIGH')
                    : ApexBadge.warning('MEDIUM');
            final iconColor = l['severity'] == 'critical' ? ApexColors.error : ApexColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_outlined, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['reason'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Terminal: ${l['device']} • Target: ${l['card_no']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                        const SizedBox(height: 6),
                        Text('Logged: ${l['time']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400)),
                      ],
                    ),
                  ),
                  badge,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
