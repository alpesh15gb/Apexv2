import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';

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
      };

      try {
        await ref.read(employeeListProvider.notifier).addEmployee(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee created'), backgroundColor: ApexColors.success),
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
    final departmentsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final designationsAsync = ref.watch(designationsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexSection(
                title: 'BASIC INFORMATION',
                children: [
                  ApexTextField(label: 'Employee Code', controller: _codeController, required: true),
                  const SizedBox(height: 12),
                  ApexTextField(label: 'First Name', controller: _firstNameController, required: true),
                  const SizedBox(height: 12),
                  ApexTextField(label: 'Last Name', controller: _lastNameController, required: true),
                  const SizedBox(height: 12),
                  ApexTextField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  ApexTextField(label: 'Phone', controller: _phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  ApexDropdown<String>(
                    label: 'Gender',
                    value: _selectedGender,
                    items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ApexSection(
                title: 'EMPLOYMENT DETAILS',
                children: [
                  departmentsAsync.when(
                    data: (deps) => ApexDropdown<String>(
                      label: 'Department',
                      value: _selectedDepartmentId,
                      items: deps.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (v) => setState(() => _selectedDepartmentId = v),
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  designationsAsync.when(
                    data: (desgs) => ApexDropdown<String>(
                      label: 'Designation',
                      value: _selectedDesignationId,
                      items: desgs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (v) => setState(() => _selectedDesignationId = v),
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  branchesAsync.when(
                    data: (branches) => ApexDropdown<String>(
                      label: 'Branch',
                      value: _selectedBranchId,
                      items: branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      onChanged: (v) => setState(() => _selectedBranchId = v),
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  ApexDatePicker(
                    label: 'Joining Date',
                    value: _joiningDate,
                    onChanged: (v) => setState(() => _joiningDate = v),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ApexButton(
                label: 'Create Employee',
                onPressed: _save,
                type: ApexButtonType.primary,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
