import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/shift_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/shift_service.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';

class ShiftAssignScreen extends ConsumerStatefulWidget {
  const ShiftAssignScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShiftAssignScreen> createState() => _ShiftAssignScreenState();
}

class _ShiftAssignScreenState extends ConsumerState<ShiftAssignScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _selectedShiftId;
  DateTime _effectiveFrom = DateTime.now();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEmployeeId == null || _selectedShiftId == null) return;
      
      final data = {
        'employee_id': _selectedEmployeeId,
        'shift_id': _selectedShiftId,
        'effective_from': _effectiveFrom.toIso8601String().substring(0, 10),
      };

      try {
        final service = ref.read(shiftServiceProvider);
        await service.assignShift(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift assigned successfully'), backgroundColor: ApexColors.success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: ApexColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final shiftsAsync = ref.watch(shiftListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Shift'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              employeesAsync.employees.maybeWhen(
                data: (list) => ApexDropdown<String>(
                  label: 'Employee',
                  value: _selectedEmployeeId,
                  required: true,
                  items: list.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.fullName} (${e.employeeCode})'))).toList(),
                  onChanged: (v) => setState(() => _selectedEmployeeId = v),
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),
              shiftsAsync.maybeWhen(
                data: (shifts) => ApexDropdown<String>(
                  label: 'Shift',
                  value: _selectedShiftId,
                  required: true,
                  items: shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => _selectedShiftId = v),
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),
              ApexDatePicker(
                label: 'Effective From',
                value: _effectiveFrom,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onChanged: (v) { if (v != null) setState(() => _effectiveFrom = v); },
              ),
              const SizedBox(height: 32),
              ApexButton(
                label: 'Assign Shift',
                expanded: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

