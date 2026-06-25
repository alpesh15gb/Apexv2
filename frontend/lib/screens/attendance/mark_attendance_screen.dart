import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';

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
          const SnackBar(content: Text('Please select an employee'), backgroundColor: Colors.red),
        );
        return;
      }

      final dateStr = _selectedDate.toIso8601String().substring(0, 10);
      
      // Build full DateTime strings for punch in/out
      final punchInDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _punchInTime.hour,
        _punchInTime.minute,
      ).toIso8601String();

      String? punchOutDateTime;
      if (_punchOutTime != null) {
        punchOutDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _punchOutTime!.hour,
          _punchOutTime!.minute,
        ).toIso8601String();
      }

      final data = {
        'employee_id': _selectedEmployeeId,
        'date': dateStr,
        'punch_in': punchInDateTime,
        'punch_out': punchOutDateTime,
        'status': _selectedStatus,
        'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        'is_manual': true,
      };

      try {
        await ref.read(attendanceListProvider.notifier).manualMark(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance logged successfully'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Attendance Mark'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Dropdown
              employeesAsync.employees.maybeWhen(
                data: (list) => DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  decoration: const InputDecoration(labelText: 'Employee *'),
                  items: list.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.fullName} (${e.employeeCode})'))).toList(),
                  onChanged: (v) => setState(() => _selectedEmployeeId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date *'),
                  child: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Punch In Time
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _punchInTime,
                  );
                  if (picked != null) {
                    setState(() => _punchInTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Punch In Time *'),
                  child: Text(_punchInTime.format(context)),
                ),
              ),
              const SizedBox(height: 16),

              // Punch Out Time (Optional)
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _punchOutTime ?? const TimeOfDay(hour: 17, minute: 0),
                  );
                  setState(() => _punchOutTime = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Punch Out Time (Optional)',
                    suffixIcon: _punchOutTime != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _punchOutTime = null),
                          )
                        : null,
                  ),
                  child: Text(_punchOutTime == null ? 'Not Punched Out' : _punchOutTime!.format(context)),
                ),
              ),
              const SizedBox(height: 16),

              // Status Selector
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks / Reason'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Mark Attendance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
