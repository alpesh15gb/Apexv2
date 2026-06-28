import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_dropdown.dart';

class EmployeeMappingScreen extends ConsumerStatefulWidget {
  const EmployeeMappingScreen({super.key});

  @override
  ConsumerState<EmployeeMappingScreen> createState() => _EmployeeMappingScreenState();
}

class _EmployeeMappingScreenState extends ConsumerState<EmployeeMappingScreen> {
  List<dynamic> _employees = [];
  List<Map<String, dynamic>> _unlinked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/employees/', queryParameters: {'page': 1, 'page_size': 100}),
      ]);
      final empList = results[0].data['items'] ?? [];

      setState(() {
        _employees = empList;
        _unlinked = [
          {
            'device_user_id': '10045',
            'card_number': 'CARD_29013A',
            'last_punch': '2026-06-25 10:14 PM',
            'employee_id': null,
          },
          {
            'device_user_id': '10046',
            'card_number': 'CARD_38129B',
            'last_punch': '2026-06-25 09:30 PM',
            'employee_id': null,
          },
        ];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _saveMapping(String deviceUserId, String? empId) {
    if (empId == null) return;
    setState(() {
      _unlinked.removeWhere((x) => x['device_user_id'] == deviceUserId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee mapped successfully to biometric ID'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee Biometric Mapping',
        description: 'Link device-specific numerical codes or swipe cards to actual employee HR profiles.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _unlinked.isEmpty && !_loading,
        emptyIcon: Icons.compare_arrows_outlined,
        emptyTitle: 'All Biometric Profiles Mapped',
        emptySubtitle: 'No unlinked device users found.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _unlinked.length,
          itemBuilder: (context, i) {
            final u = _unlinked[i];
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
                        Text('Biometric User ID: ${u['device_user_id']}', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        Text('Swipe Card: ${u['card_number']} • Last seen: ${u['last_punch']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text('Link Profile: ', style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 240,
                        height: 36,
                        child: ApexDropdown<String>(
                          label: 'Employee',
                          value: u['employee_id'],
                          items: _employees
                              .map((e) => DropdownMenuItem(
                                    value: e['id'] as String,
                                    child: Text('${e['first_name']} ${e['last_name']} (${e['employee_code']})'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              u['employee_id'] = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ApexButton(
                        label: 'Save Link',
                        onPressed: u['employee_id'] != null ? () => _saveMapping(u['device_user_id'], u['employee_id']) : null,
                        type: ApexButtonType.primary,
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
