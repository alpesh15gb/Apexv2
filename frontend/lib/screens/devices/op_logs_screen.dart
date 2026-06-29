import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';

class OpLogsScreen extends ConsumerStatefulWidget {
  const OpLogsScreen({super.key});

  @override
  ConsumerState<OpLogsScreen> createState() => _OpLogsScreenState();
}

class _OpLogsScreenState extends ConsumerState<OpLogsScreen> {
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
          'id': 'OPL001',
          'operator': 'HR Admin (admin@company.com)',
          'command': 'Device Reboot Triggered',
          'device': 'Factory Gate 1 Turnstile',
          'timestamp': '2026-06-25 10:45 AM',
          'ip': '192.168.12.44',
        },
        {
          'id': 'OPL002',
          'operator': 'HR Admin (admin@company.com)',
          'command': 'Sync Users Commanded',
          'device': 'HO Main Entrance Face Terminal',
          'timestamp': '2026-06-25 09:30 AM',
          'ip': '192.168.12.44',
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
        title: 'OP Logs',
        description: 'Audit logs of commands sent to devices by operators and HR managers.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _logs.isEmpty && !_loading,
        emptyIcon: Icons.manage_search_outlined,
        emptyTitle: 'No Command Logs',
        emptySubtitle: 'Biometric terminals controls audit trail is empty.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _logs.length,
          itemBuilder: (context, i) {
            final l = _logs[i];
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
                      color: ApexColors.primary600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_search, color: ApexColors.primary600, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['command'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Operator: ${l['operator']} • IP: ${l['ip']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                        const SizedBox(height: 6),
                        Text('Device: ${l['device']} • Time: ${l['timestamp']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400)),
                      ],
                    ),
                  ),
                  ApexBadge.info('COMMAND'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
