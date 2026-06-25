import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/employee_provider.dart';

class EmployeeCreateScreen extends ConsumerStatefulWidget {
  const EmployeeCreateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeCreateScreen> createState() => _EmployeeCreateScreenState();
}

class _EmployeeCreateScreenState extends ConsumerState<EmployeeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedBranchId;
  String? _selectedDesignationId;
  String? _selectedGender;
  DateTime? _joiningDate = DateTime.now();

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'employee_code': _codeController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'department_id': _selectedDepartmentId,
        'branch_id': _selectedBranchId,
        'designation_id': _selectedDesignationId,
        'gender': _selectedGender,
        'joining_date': _joiningDate?.toIso8601String().substring(0, 10),
        'status': 'active',
      };

      try {
        await ref.read(employeeListProvider.notifier).addEmployee(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee created successfully'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final designationsAsync = ref.watch(designationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Employee Code *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              departmentsAsync.maybeWhen(
                data: (deps) => DropdownButtonFormField<String>(
                  value: _selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: deps.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) => setState(() => _selectedDepartmentId = v),
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),

              designationsAsync.maybeWhen(
                data: (desgs) => DropdownButtonFormField<String>(
                  value: _selectedDesignationId,
                  decoration: const InputDecoration(labelText: 'Designation'),
                  items: desgs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) => setState(() => _selectedDesignationId = v),
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),

              branchesAsync.maybeWhen(
                data: (branches) => DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joiningDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _joiningDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Joining Date'),
                  child: Text(_joiningDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_joiningDate!)),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Create Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
