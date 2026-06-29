import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/page_wrapper.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();

  String? _selectedEmployeeId;
  String _selectedStatus = 'present';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _punchInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _punchOutTime;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEmployeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an employee'), backgroundColor: ApexColors.error),
        );
        return;
      }

      final punchIn = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _punchInTime.hour, _punchInTime.minute,
      );
      DateTime? punchOut;
      if (_punchOutTime != null) {
        punchOut = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          _punchOutTime!.hour, _punchOutTime!.minute,
        );
      }

      final data = {
        'employee_id': _selectedEmployeeId,
        'date': _selectedDate.toIso8601String().substring(0, 10),
        'punch_in': punchIn.toIso8601String(),
        'punch_out': punchOut?.toIso8601String(),
        'status': _selectedStatus,
        'is_manual': true,
        'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      };

      try {
        await ref.read(attendanceListProvider.notifier).manualMark(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance marked'), backgroundColor: ApexColors.success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: ApexColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Manual Attendance',
        description: 'Mark attendance or override daily check-in logs manually.',
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee & Date
                ApexSection(
                  title: 'EMPLOYEE & DATE',
                  children: [
                    employeesAsync.employees.when(
                      data: (employees) => ApexDropdown<String>(
                        label: 'Employee',
                        value: _selectedEmployeeId,
                        required: true,
                        items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.fullName} (${e.employeeCode})'))).toList(),
                        onChanged: (v) => setState(() => _selectedEmployeeId = v),
                      ),
                      loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox(),
                    ),
                    ApexDatePicker(
                      label: 'Date',
                      value: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      onChanged: (v) { if (v != null) setState(() => _selectedDate = v); },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Attendance Details
                ApexSection(
                  title: 'ATTENDANCE DETAILS',
                  children: [
                    ApexDropdown<String>(
                      label: 'Status',
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'present', child: Text('Present')),
                        DropdownMenuItem(value: 'absent', child: Text('Absent')),
                        DropdownMenuItem(value: 'late', child: Text('Late')),
                        DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v ?? 'present'),
                    ),
                    _timeField('Punch In', _punchInTime, (v) => setState(() => _punchInTime = v)),
                    _timeField('Punch Out', _punchOutTime, (v) => setState(() => _punchOutTime = v)),
                    ApexTextField(
                      label: 'Remarks',
                      controller: _remarksController,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit
                ApexButton(
                  label: 'Mark Attendance',
                  expanded: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay? time, ValueChanged<TimeOfDay> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: time ?? const TimeOfDay(hour: 9, minute: 0));
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: ApexTypography.body.copyWith(color: ApexColors.neutral500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ApexColors.neutral300, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ApexColors.neutral300, width: 1.5),
                ),
                filled: true,
                fillColor: ApexColors.neutral0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                suffixIcon: const Icon(Icons.access_time, size: 18, color: ApexColors.neutral400),
              ),
              child: Text(
                time != null ? time.format(context) : 'Select time',
                style: ApexTypography.body.copyWith(
                  color: time != null ? ApexColors.neutral900 : ApexColors.neutral400,
                  fontWeight: time != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
