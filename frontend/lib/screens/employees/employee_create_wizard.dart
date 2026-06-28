import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_text_field.dart';

class EmployeeCreateWizard extends ConsumerStatefulWidget {
  const EmployeeCreateWizard({super.key});

  @override
  ConsumerState<EmployeeCreateWizard> createState() => _EmployeeCreateWizardState();
}

class _EmployeeCreateWizardState extends ConsumerState<EmployeeCreateWizard> {
  int _currentStep = 0;
  bool _loading = false;
  final _formData = <String, dynamic>{};

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;
  DateTime? _dob;

  final _codeCtrl = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  String _employmentType = 'permanent';
  String _status = 'active';

  String? _departmentId;
  String? _designationId;
  String? _branchId;
  String? _shiftId;
  String? _managerId;

  final _basicCtrl = TextEditingController(text: '0');
  final _hraCtrl = TextEditingController(text: '0');
  final _daCtrl = TextEditingController(text: '0');

  final _bankNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  List<dynamic> _departments = [];
  List<dynamic> _designations = [];
  List<dynamic> _branches = [];
  List<dynamic> _shifts = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/employees/departments', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/employees/designations', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/employees/branches', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/employees/', queryParameters: {'page': 1, 'page_size': 100}),
      ]);
      setState(() {
        _departments = results[0].data['items'] ?? [];
        _designations = results[1].data['items'] ?? [];
        _branches = results[2].data['items'] ?? [];
        _shifts = results[3].data['items'] ?? [];
        _employees = results[4].data['items'] ?? [];
      });
    } catch (e) {
      // Silently handle - dropdowns will be empty
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('Add Employee', style: ApexTypography.sectionTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: isMobile ? _buildStepContent() : Row(
              children: [
                Container(
                  width: 220,
                  decoration: BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: ApexColors.neutral200))),
                  child: _buildStepList(),
                ),
                Expanded(child: _buildStepContent()),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Basic Info', 'Employment', 'Organization', 'Salary', 'Bank', 'Emergency', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: ApexColors.neutral200))),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final isActive = i == _currentStep;
          final isCompleted = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? ApexColors.success : isActive ? ApexColors.primary : ApexColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : ApexColors.neutral500)),
                  ),
                ),
                const SizedBox(width: 6),
                if (!Responsive.isMobile(context))
                  Flexible(child: Text(entry.value, style: TextStyle(fontSize: 11, color: isActive ? ApexColors.primary : ApexColors.neutral500, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
                if (i < steps.length - 1) Expanded(child: Container(height: 1, color: isCompleted ? ApexColors.success : ApexColors.neutral200, margin: const EdgeInsets.symmetric(horizontal: 8))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepList() {
    final steps = ['Basic Info', 'Employment', 'Organization', 'Salary', 'Bank', 'Emergency', 'Review'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: steps.length,
      itemBuilder: (context, i) {
        final isActive = i == _currentStep;
        final isCompleted = i < _currentStep;
        return ListTile(
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? ApexColors.success : isActive ? ApexColors.primary : ApexColors.neutral200,
            child: isCompleted ? Icon(Icons.check, size: 14, color: Colors.white) : Text('${i + 1}', style: TextStyle(fontSize: 11, color: isActive ? Colors.white : ApexColors.neutral500)),
          ),
          title: Text(steps[i], style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? ApexColors.primary : ApexColors.neutral900)),
          dense: true,
          onTap: () => setState(() => _currentStep = i),
        );
      },
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildBasicInfo();
      case 1: return _buildEmployment();
      case 2: return _buildOrganization();
      case 3: return _buildSalary();
      case 4: return _buildBank();
      case 5: return _buildEmergency();
      case 6: return _buildReview();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ApexTextField(label: 'First Name', controller: _firstNameCtrl, required: true, prefixIcon: Icons.person)),
              const SizedBox(width: 16),
              Expanded(child: ApexTextField(label: 'Last Name', controller: _lastNameCtrl, required: true, prefixIcon: Icons.person)),
            ]),
            Row(children: [
              Expanded(child: ApexTextField(label: 'Email', controller: _emailCtrl, prefixIcon: Icons.email)),
              const SizedBox(width: 16),
              Expanded(child: ApexTextField(label: 'Phone', controller: _phoneCtrl, prefixIcon: Icons.phone)),
            ]),
            Row(children: [
              Expanded(child: ApexDropdown<String>(
                label: 'Gender',
                value: _gender,
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g.toLowerCase(), child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
              )),
              const SizedBox(width: 16),
              Expanded(child: ApexDatePicker(
                label: 'Date of Birth',
                value: _dob,
                onChanged: (v) => setState(() => _dob = v),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employment Information', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            ApexTextField(label: 'Employee Code', controller: _codeCtrl, required: true, prefixIcon: Icons.badge),
            ApexDatePicker(
              label: 'Joining Date',
              value: _joiningDate,
              onChanged: (v) => setState(() => _joiningDate = v ?? _joiningDate),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            ),
            ApexDropdown<String>(
              label: 'Employment Type',
              value: _employmentType,
              items: ['permanent', 'contract', 'intern', 'consultant', 'trainee'].map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
              onChanged: (v) => setState(() => _employmentType = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganization() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organization Mapping', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            _dropdown('Department', _departmentId, _departments, (v) => setState(() => _departmentId = v)),
            _dropdown('Designation', _designationId, _designations, (v) => setState(() => _designationId = v)),
            _dropdown('Branch', _branchId, _branches, (v) => setState(() => _branchId = v)),
            _dropdown('Shift', _shiftId, _shifts, (v) => setState(() => _shiftId = v)),
            _dropdown('Reporting Manager', _managerId, _employees, (v) => setState(() => _managerId = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salary Structure', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ApexTextField(label: 'Basic Salary', controller: _basicCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.money)),
              const SizedBox(width: 16),
              Expanded(child: ApexTextField(label: 'HRA', controller: _hraCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.money)),
              const SizedBox(width: 16),
              Expanded(child: ApexTextField(label: 'DA', controller: _daCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.money)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBank() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank Details', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            ApexTextField(label: 'Bank Name', controller: _bankNameCtrl, prefixIcon: Icons.account_balance),
            ApexTextField(label: 'Account Number', controller: _accountNoCtrl, prefixIcon: Icons.numbers),
            ApexTextField(label: 'IFSC Code', controller: _ifscCtrl, prefixIcon: Icons.code),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergency() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Contact', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            ApexTextField(label: 'Contact Name', controller: _emergencyNameCtrl, prefixIcon: Icons.person),
            ApexTextField(label: 'Contact Phone', controller: _emergencyPhoneCtrl, prefixIcon: Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review & Submit', style: ApexTypography.cardTitle),
            const SizedBox(height: 20),
            _reviewSection('Basic Information', [
              'Name: ${_firstNameCtrl.text} ${_lastNameCtrl.text}',
              'Email: ${_emailCtrl.text}',
              'Phone: ${_phoneCtrl.text}',
              'Gender: ${_gender ?? "—"}',
            ]),
            _reviewSection('Employment', [
              'Code: ${_codeCtrl.text}',
              'Joining Date: ${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}',
              'Type: $_employmentType',
            ]),
            _reviewSection('Organization', [
              'Department: ${_departments.where((d) => d['id'] == _departmentId).isNotEmpty ? _departments.firstWhere((d) => d['id'] == _departmentId)['name'] : '—'}',
              'Designation: ${_designations.where((d) => d['id'] == _designationId).isNotEmpty ? _designations.firstWhere((d) => d['id'] == _designationId)['name'] : '—'}',
              'Branch: ${_branches.where((b) => b['id'] == _branchId).isNotEmpty ? _branches.firstWhere((b) => b['id'] == _branchId)['name'] : '—'}',
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ApexColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.primary.withValues(alpha: 0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto-Generated Credentials', style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
                  const SizedBox(height: 8),
                  Text('Username: ${_codeCtrl.text}', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                  Text('Temporary Password: ${_codeCtrl.text}', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(height: 8),
                  Text('Employee will be forced to change password on first login.', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: ApexColors.neutral200))),
      child: Row(
        children: [
          if (_currentStep > 0)
            ApexButton(
              label: 'Back',
              onPressed: () => setState(() => _currentStep--),
              type: ApexButtonType.outline,
              icon: Icons.arrow_back,
            ),
          const Spacer(),
          if (_currentStep < 6)
            ApexButton(
              label: 'Continue',
              onPressed: () => setState(() => _currentStep++),
              type: ApexButtonType.primary,
              icon: Icons.arrow_forward,
            )
          else
            ApexButton(
              label: _loading ? 'Creating...' : 'Create Employee',
              onPressed: _loading ? null : _submit,
              type: ApexButtonType.success,
              icon: _loading ? null : Icons.check,
              loading: _loading,
            ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<dynamic> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ApexDropdown<String>(
        label: label,
        value: value,
        items: items.map((item) => DropdownMenuItem(
          value: item['id'] as String,
          child: Text(item['name'] ?? item['code'] ?? ''),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _submit() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'employee_code': _codeCtrl.text.trim(),
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'gender': _gender,
        'date_of_birth': _dob?.toIso8601String().substring(0, 10),
        'joining_date': _joiningDate.toIso8601String().substring(0, 10),
        'employment_type': _employmentType,
        'department_id': _departmentId,
        'designation_id': _designationId,
        'branch_id': _branchId,
        'shift_id': _shiftId,
        'reporting_manager_id': _managerId,
        'status': _status,
      };

      await dio.post('/employees/', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee created successfully! Login credentials generated.'), backgroundColor: ApexColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _basicCtrl.dispose();
    _hraCtrl.dispose();
    _daCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }
}

