import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../screens/employees/employee_detail_screen.dart';
import '../../screens/employees/employee_directory_screen.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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

  // Controllers
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
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: _danger),
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
          const SnackBar(content: Text('Employee updated'), backgroundColor: _success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _danger),
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
        backgroundColor: _bg,
        appBar: const ApexAppBar(title: 'Edit Employee'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_employee == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: const ApexAppBar(title: 'Edit Employee'),
        body: const Center(child: Text('Employee not found')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(
        title: 'Edit ${_employee!.fullName}',
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save'),
            style: TextButton.styleFrom(foregroundColor: _primary),
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
              _section('BASIC INFORMATION', [
                Row(
                  children: [
                    Expanded(child: _textField('Employee Code', _codeCtrl, enabled: false)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _dropdownField('Status', _selectedStatus, [
                        const DropdownMenuItem(value: 'active', child: Text('Active')),
                        const DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        const DropdownMenuItem(value: 'terminated', child: Text('Terminated')),
                        const DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                      ], (v) => setState(() => _selectedStatus = v!)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _textField('First Name', _firstNameCtrl, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _textField('Last Name', _lastNameCtrl, required: true)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _section('CONTACT', [
                Row(
                  children: [
                    Expanded(child: _textField('Email', _emailCtrl, keyboardType: TextInputType.emailAddress)),
                    const SizedBox(width: 16),
                    Expanded(child: _textField('Phone', _phoneCtrl, keyboardType: TextInputType.phone)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _section('EMPLOYMENT', [
                Row(
                  children: [
                    Expanded(child: _dropdownFromList('Department', _selectedDepartmentId, _departments, (v) => setState(() => _selectedDepartmentId = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _dropdownFromList('Designation', _selectedDesignationId, _designations, (v) => setState(() => _selectedDesignationId = v))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _dropdownFromList('Branch', _selectedBranchId, _branches, (v) => setState(() => _selectedBranchId = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _dropdownFromList('Shift', _selectedShiftId, _shifts, (v) => setState(() => _selectedShiftId = v))),
                  ],
                ),
                const SizedBox(height: 16),
                _dateField('Joining Date', _joiningDate, (v) => setState(() => _joiningDate = v)),
              ]),
              const SizedBox(height: 24),
              _section('PERSONAL', [
                Row(
                  children: [
                    Expanded(
                      child: _dropdownField('Gender', _selectedGender, [
                        const DropdownMenuItem(value: 'male', child: Text('Male')),
                        const DropdownMenuItem(value: 'female', child: Text('Female')),
                        const DropdownMenuItem(value: 'other', child: Text('Other')),
                      ], (v) => setState(() => _selectedGender = v)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _dateField('Date of Birth', _dateOfBirth, (v) => setState(() => _dateOfBirth = v))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _dropdownField('Blood Group', _selectedBloodGroup, [
                        const DropdownMenuItem(value: 'A+', child: Text('A+')),
                        const DropdownMenuItem(value: 'A-', child: Text('A-')),
                        const DropdownMenuItem(value: 'B+', child: Text('B+')),
                        const DropdownMenuItem(value: 'B-', child: Text('B-')),
                        const DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        const DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                        const DropdownMenuItem(value: 'O+', child: Text('O+')),
                        const DropdownMenuItem(value: 'O-', child: Text('O-')),
                      ], (v) => setState(() => _selectedBloodGroup = v)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _textField('Address', _addressCtrl, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _textField('City', _cityCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _textField('State', _stateCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _textField('Pincode', _pincodeCtrl)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _section('EMERGENCY CONTACT', [
                Row(
                  children: [
                    Expanded(child: _textField('Contact Name', _emergencyNameCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _textField('Contact Phone', _emergencyPhoneCtrl, keyboardType: TextInputType.phone)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _section('DEVICE', [
                _textField('Device User ID', _deviceUserIdCtrl),
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: _muted)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        filled: true,
        fillColor: enabled ? _surface : _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _dropdownField(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary)),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _dropdownFromList(String label, String? value, List<Map<String, dynamic>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(
        value: item['id'] as String,
        child: Text(item['name'] ?? '', overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary)),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: _muted),
        ),
        child: Text(
          value != null ? DateFormat('MMM dd, yyyy').format(value) : 'Select date',
          style: TextStyle(fontSize: 14, color: value != null ? _text : _muted),
        ),
      ),
    );
  }
}
