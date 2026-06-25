import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/shift_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/shift_service.dart';

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
            const SnackBar(content: Text('Shift assigned successfully'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              shiftsAsync.maybeWhen(
                data: (shifts) => DropdownButtonFormField<String>(
                  value: _selectedShiftId,
                  decoration: const InputDecoration(labelText: 'Shift *'),
                  items: shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => _selectedShiftId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveFrom,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _effectiveFrom = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Effective From'),
                  child: Text(DateFormat('MMM dd, yyyy').format(_effectiveFrom)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Assign Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
