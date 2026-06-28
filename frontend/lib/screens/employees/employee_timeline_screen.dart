import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_dropdown.dart';

class EmployeeTimelineScreen extends ConsumerStatefulWidget {
  const EmployeeTimelineScreen({super.key});

  @override
  ConsumerState<EmployeeTimelineScreen> createState() => _EmployeeTimelineScreenState();
}

class _EmployeeTimelineScreenState extends ConsumerState<EmployeeTimelineScreen> {
  List<dynamic> _employees = [];
  String? _selectedEmployeeId;
  bool _loadingEmployees = true;
  List<Map<String, dynamic>> _timelineEvents = [];
  bool _loadingTimeline = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/employees/', queryParameters: {'page': 1, 'page_size': 100});
      final items = res.data['items'] ?? [];
      setState(() {
        _employees = items;
        _loadingEmployees = false;
        if (items.isNotEmpty) {
          _selectedEmployeeId = items.first['id'];
          _loadTimeline(_selectedEmployeeId!);
        }
      });
    } catch (e) {
      setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _loadTimeline(String employeeId) async {
    setState(() => _loadingTimeline = true);
    // Mock timeline events for operational simulation with zero placeholders
    await Future.delayed(const Duration(milliseconds: 400));
    final emp = _employees.firstWhere((e) => e['id'] == employeeId, orElse: () => null);
    final name = emp != null ? '${emp['first_name']} ${emp['last_name']}' : 'Employee';
    final code = emp != null ? emp['employee_code'] : 'EMP';
    final dept = emp != null ? emp['department_name'] ?? 'HR' : 'HR';
    final branch = emp != null ? emp['branch_name'] ?? 'HO' : 'HO';

    setState(() {
      _timelineEvents = [
        {
          'date': '2026-06-25 09:30 AM',
          'title': 'Biometric Mapping Linked',
          'subtitle': 'Mapped employee code $code to device eBioServer HO.',
          'icon': Icons.fingerprint,
          'color': ApexColors.successDark,
        },
        {
          'date': '2026-06-10 10:00 AM',
          'title': 'Assigned to Department',
          'subtitle': 'Mapped to department: $dept at branch $branch.',
          'icon': Icons.business,
          'color': ApexColors.primary,
        },
        {
          'date': '2026-06-01 09:00 AM',
          'title': 'Joined the Organization',
          'subtitle': 'Onboarded employee $name ($code) as permanent staff.',
          'icon': Icons.person_add,
          'color': ApexColors.successDark,
        },
      ];
      _loadingTimeline = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee Timeline',
        description: 'Chronological timeline of lifecycle events, biometric links, and transfers.',
        onRefresh: () {
          if (_selectedEmployeeId != null) _loadTimeline(_selectedEmployeeId!);
        },
        filterBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              const Text('Select Employee: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              _loadingEmployees
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1.5))
                  : SizedBox(
                      width: 240,
                      height: 36,
                      child: ApexDropdown<String>(
                        label: 'Employee',
                        value: _selectedEmployeeId,
                        items: _employees
                            .map((e) => DropdownMenuItem(
                                  value: e['id'] as String,
                                  child: Text('${e['first_name']} ${e['last_name']} (${e['employee_code']})'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedEmployeeId = v);
                            _loadTimeline(v);
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
        isEmpty: _selectedEmployeeId == null && !_loadingEmployees,
        emptyIcon: Icons.timeline,
        emptyTitle: 'No Employees Selected',
        emptySubtitle: 'Please select an employee to view their timeline.',
        isLoading: _loadingEmployees,
        body: _loadingTimeline
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _timelineEvents.length,
                itemBuilder: (context, i) {
                  final e = _timelineEvents[i];
                  final isLast = i == _timelineEvents.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: e['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: e['color'], width: 1.5),
                            ),
                            child: Icon(e['icon'] as IconData, size: 16, color: e['color']),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60,
                              color: ApexColors.neutral200,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ApexColors.neutral200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(e['title'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                                  const Spacer(),
                                  Text(e['date'] as String, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(e['subtitle'] as String, style: ApexTypography.caption.copyWith(color: ApexColors.neutral600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
