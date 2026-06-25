import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
          const SnackBar(content: Text('Please select an employee'), backgroundColor: _danger),
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
            const SnackBar(content: Text('Attendance marked'), backgroundColor: _success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: _danger),
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
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee & Date
              _SectionCard(
                title: 'EMPLOYEE & DATE',
                children: [
                  employeesAsync.employees.when(
                    data: (employees) => _dropdown(
                      'Employee',
                      _selectedEmployeeId,
                      employees.map((e) => {'id': e.id, 'name': '${e.fullName} (${e.employeeCode})'}).toList(),
                      (v) => setState(() => _selectedEmployeeId = v),
                    ),
                    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(),
                  ),
                  _dateField('Date', _selectedDate, (v) => setState(() => _selectedDate = v)),
                ],
              ),
              const SizedBox(height: 16),

              // Attendance Details
              _SectionCard(
                title: 'ATTENDANCE DETAILS',
                children: [
                  _dropdown(
                    'Status',
                    _selectedStatus,
                    [
                      {'id': 'present', 'name': 'Present'},
                      {'id': 'absent', 'name': 'Absent'},
                      {'id': 'late', 'name': 'Late'},
                      {'id': 'half_day', 'name': 'Half Day'},
                    ],
                    (v) => setState(() => _selectedStatus = v ?? 'present'),
                  ),
                  _timeField('Punch In', _punchInTime, (v) => setState(() => _punchInTime = v)),
                  _timeField('Punch Out', _punchOutTime, (v) => setState(() => _punchOutTime = v)),
                  _field('Remarks', _remarksController),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Mark Attendance', style: ApexTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<dynamic> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: items.map<DropdownMenuItem<String>>((item) {
              if (item is String) return DropdownMenuItem<String>(value: item, child: Text(item));
              return DropdownMenuItem<String>(value: item['id'] as String, child: Text(item['name'] as String));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: _muted),
                  const SizedBox(width: 10),
                  Text(DateFormat('MMM dd, yyyy').format(date), style: ApexTypography.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay? time, ValueChanged<TimeOfDay> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: time ?? const TimeOfDay(hour: 9, minute: 0));
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: _muted),
                  const SizedBox(width: 10),
                  Text(time != null ? time.format(context) : 'Select time', style: ApexTypography.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ApexTypography.sectionHeader),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
