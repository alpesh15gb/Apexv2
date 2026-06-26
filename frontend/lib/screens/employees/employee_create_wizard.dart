import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class EmployeeCreateWizard extends ConsumerStatefulWidget {
  const EmployeeCreateWizard({super.key});

  @override
  ConsumerState<EmployeeCreateWizard> createState() => _EmployeeCreateWizardState();
}

class _EmployeeCreateWizardState extends ConsumerState<EmployeeCreateWizard> {
  int _currentStep = 0;
  bool _loading = false;
  final _formData = <String, dynamic>{};

  // Controllers for Step 1 - Basic Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;
  DateTime? _dob;

  // Controllers for Step 2 - Employment
  final _codeCtrl = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  String _employmentType = 'permanent';
  String _status = 'active';

  // Step 3 - Organization
  String? _departmentId;
  String? _designationId;
  String? _branchId;
  String? _shiftId;
  String? _managerId;

  // Step 4 - Salary
  final _basicCtrl = TextEditingController(text: '0');
  final _hraCtrl = TextEditingController(text: '0');
  final _daCtrl = TextEditingController(text: '0');

  // Step 5 - Bank
  final _bankNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // Step 6 - Emergency
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Add Employee', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: isMobile ? _buildStepContent() : Row(
              children: [
                Container(
                  width: 220,
                  decoration: const BoxDecoration(color: _surface, border: Border(right: BorderSide(color: _border))),
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
      decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
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
                    color: isCompleted ? _success : isActive ? _primary : _border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _muted)),
                  ),
                ),
                const SizedBox(width: 6),
                if (!Responsive.isMobile(context))
                  Flexible(child: Text(entry.value, style: TextStyle(fontSize: 11, color: isActive ? _primary : _muted, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
                if (i < steps.length - 1) Expanded(child: Container(height: 1, color: isCompleted ? _success : _border, margin: const EdgeInsets.symmetric(horizontal: 8))),
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
            backgroundColor: isCompleted ? _success : isActive ? _primary : _border,
            child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : Text('${i + 1}', style: TextStyle(fontSize: 11, color: isActive ? Colors.white : _muted)),
          ),
          title: Text(steps[i], style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? _primary : _text)),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_firstNameCtrl, 'First Name *', Icons.person)),
              const SizedBox(width: 16),
              Expanded(child: _field(_lastNameCtrl, 'Last Name *', Icons.person)),
            ]),
            Row(children: [
              Expanded(child: _field(_emailCtrl, 'Email', Icons.email)),
              const SizedBox(width: 16),
              Expanded(child: _field(_phoneCtrl, 'Phone', Icons.phone)),
            ]),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g.toLowerCase(), child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
              )),
              const SizedBox(width: 16),
              Expanded(child: ListTile(
                title: const Text('Date of Birth', style: TextStyle(fontSize: 13, color: _muted)),
                subtitle: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select date', style: const TextStyle(fontSize: 14, color: _text)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _dob ?? DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
                  if (picked != null) setState(() => _dob = picked);
                },
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Employment Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 20),
            _field(_codeCtrl, 'Employee Code *', Icons.badge),
            ListTile(
              title: const Text('Joining Date', style: TextStyle(fontSize: 13, color: _muted)),
              subtitle: Text('${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}', style: const TextStyle(fontSize: 14, color: _text)),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _joiningDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) setState(() => _joiningDate = picked);
              },
            ),
            DropdownButtonFormField<String>(
              value: _employmentType,
              decoration: const InputDecoration(labelText: 'Employment Type', border: OutlineInputBorder()),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Organization Mapping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Salary Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_basicCtrl, 'Basic Salary', Icons.money, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _field(_hraCtrl, 'HRA', Icons.money, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _field(_daCtrl, 'DA', Icons.money, keyboardType: TextInputType.number)),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 20),
            _field(_bankNameCtrl, 'Bank Name', Icons.account_balance),
            _field(_accountNoCtrl, 'Account Number', Icons.numbers),
            _field(_ifscCtrl, 'IFSC Code', Icons.code),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 20),
            _field(_emergencyNameCtrl, 'Contact Name', Icons.person),
            _field(_emergencyPhoneCtrl, 'Contact Phone', Icons.phone),
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
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
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
              decoration: BoxDecoration(color: _primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: _primary.withOpacity(0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Auto-Generated Credentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                  const SizedBox(height: 8),
                  Text('Username: ${_codeCtrl.text}', style: const TextStyle(fontSize: 13, color: _text)),
                  Text('Temporary Password: ${_codeCtrl.text}', style: const TextStyle(fontSize: 13, color: _text)),
                  const SizedBox(height: 8),
                  const Text('Employee will be forced to change password on first login.', style: TextStyle(fontSize: 12, color: _muted)),
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
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: const TextStyle(fontSize: 13, color: _text)),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _border))),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
          const Spacer(),
          if (_currentStep < 6)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep++),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            )
          else
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
              label: Text(_loading ? 'Creating...' : 'Create Employee'),
              style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<dynamic> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
          const SnackBar(content: Text('Employee created successfully! Login credentials generated.'), backgroundColor: _success),
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
