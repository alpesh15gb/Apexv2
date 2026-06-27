import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../screens/employees/employee_detail_screen.dart';
import '../../screens/employees/employee_directory_screen.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';

class EmployeeEditScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeEditScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends ConsumerState<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  Employee? _employee;

  final _codeCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _deviceUserIdCtrl = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedDesignationId;
  String? _selectedBranchId;
  String? _selectedShiftId;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String _selectedStatus = 'active';
  DateTime? _joiningDate;
  DateTime? _dateOfBirth;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _designations = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _shifts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/employees/${widget.employeeId}'),
        dio.get('/employees/departments', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/employees/designations', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/employees/branches', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100}),
      ]);

      final emp = Employee.fromJson(results[0].data);
      _departments = List<Map<String, dynamic>>.from(results[1].data['items'] ?? []);
      _designations = List<Map<String, dynamic>>.from(results[2].data['items'] ?? []);
      _branches = List<Map<String, dynamic>>.from(results[3].data['items'] ?? []);
      _shifts = List<Map<String, dynamic>>.from(results[4].data['items'] ?? []);

      setState(() {
        _employee = emp;
        _codeCtrl.text = emp.employeeCode;
        _firstNameCtrl.text = emp.firstName;
        _lastNameCtrl.text = emp.lastName;
        _emailCtrl.text = emp.email ?? '';
        _phoneCtrl.text = emp.phone ?? '';
        _addressCtrl.text = emp.address ?? '';
        _cityCtrl.text = emp.city ?? '';
        _stateCtrl.text = emp.state ?? '';
        _pincodeCtrl.text = emp.pincode ?? '';
        _emergencyNameCtrl.text = emp.emergencyContactName ?? '';
        _emergencyPhoneCtrl.text = emp.emergencyContactPhone ?? '';
        _deviceUserIdCtrl.text = emp.deviceUserId ?? '';
        _selectedDepartmentId = emp.departmentId;
        _selectedDesignationId = emp.designationId;
        _selectedBranchId = emp.branchId;
        _selectedShiftId = emp.shiftId;
        _selectedGender = emp.gender;
        _selectedBloodGroup = emp.bloodGroup;
        _selectedStatus = emp.status;
        _joiningDate = emp.joiningDate;
        _dateOfBirth = emp.dateOfBirth;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/employees/${widget.employeeId}', data: {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'department_id': _selectedDepartmentId,
        'designation_id': _selectedDesignationId,
        'branch_id': _selectedBranchId,
        'shift_id': _selectedShiftId,
        'gender': _selectedGender,
        'blood_group': _selectedBloodGroup,
        'status': _selectedStatus,
        'joining_date': _joiningDate?.toIso8601String().substring(0, 10),
        'date_of_birth': _dateOfBirth?.toIso8601String().substring(0, 10),
        'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        'city': _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        'state': _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
        'pincode': _pincodeCtrl.text.trim().isNotEmpty ? _pincodeCtrl.text.trim() : null,
        'emergency_contact_name': _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : null,
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : null,
        'device_user_id': _deviceUserIdCtrl.text.trim().isNotEmpty ? _deviceUserIdCtrl.text.trim() : null,
      });

      ref.invalidate(employeeDetailProvider(widget.employeeId));
      ref.invalidate(employeeDirectoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee updated'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _deviceUserIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const ApexAppBar(title: 'Edit Employee'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_employee == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const ApexAppBar(title: 'Edit Employee'),
        body: const Center(child: Text('Employee not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ApexAppBar(
        title: 'Edit ${_employee!.fullName}',
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexSection(title: 'BASIC INFORMATION', children: [
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'Employee Code', controller: _codeCtrl, enabled: false)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ApexDropdown<String>(
                        label: 'Status',
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(value: 'terminated', child: Text('Terminated')),
                          DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'First Name', controller: _firstNameCtrl, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'Last Name', controller: _lastNameCtrl, required: true)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'CONTACT', children: [
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'EMPLOYMENT', children: [
                Row(
                  children: [
                    Expanded(child: ApexDropdown<String>(
                      label: 'Department',
                      value: _selectedDepartmentId,
                      items: _departments.map((d) => DropdownMenuItem(
                        value: d['id'] as String,
                        child: Text(d['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedDepartmentId = v),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: ApexDropdown<String>(
                      label: 'Designation',
                      value: _selectedDesignationId,
                      items: _designations.map((d) => DropdownMenuItem(
                        value: d['id'] as String,
                        child: Text(d['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedDesignationId = v),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ApexDropdown<String>(
                      label: 'Branch',
                      value: _selectedBranchId,
                      items: _branches.map((b) => DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text(b['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedBranchId = v),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: ApexDropdown<String>(
                      label: 'Shift',
                      value: _selectedShiftId,
                      items: _shifts.map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedShiftId = v),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                ApexDatePicker(label: 'Joining Date', value: _joiningDate, onChanged: (v) => setState(() => _joiningDate = v)),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'PERSONAL', children: [
                Row(
                  children: [
                    Expanded(
                      child: ApexDropdown<String>(
                        label: 'Gender',
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: ApexDatePicker(label: 'Date of Birth', value: _dateOfBirth, onChanged: (v) => setState(() => _dateOfBirth = v))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ApexDropdown<String>(
                        label: 'Blood Group',
                        value: _selectedBloodGroup,
                        items: const [
                          DropdownMenuItem(value: 'A+', child: Text('A+')),
                          DropdownMenuItem(value: 'A-', child: Text('A-')),
                          DropdownMenuItem(value: 'B+', child: Text('B+')),
                          DropdownMenuItem(value: 'B-', child: Text('B-')),
                          DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                          DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                          DropdownMenuItem(value: 'O+', child: Text('O+')),
                          DropdownMenuItem(value: 'O-', child: Text('O-')),
                        ],
                        onChanged: (v) => setState(() => _selectedBloodGroup = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ApexTextField(label: 'Address', controller: _addressCtrl, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'City', controller: _cityCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'State', controller: _stateCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'Pincode', controller: _pincodeCtrl)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'EMERGENCY CONTACT', children: [
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'Contact Name', controller: _emergencyNameCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'Contact Phone', controller: _emergencyPhoneCtrl, keyboardType: TextInputType.phone)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'DEVICE', children: [
                ApexTextField(label: 'Device User ID', controller: _deviceUserIdCtrl),
              ]),
              const SizedBox(height: 32),
              ApexButton(
                label: 'Save Changes',
                icon: Icons.save,
                loading: _saving,
                expanded: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
