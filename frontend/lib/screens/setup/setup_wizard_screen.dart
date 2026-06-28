import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_button.dart';

final setupProgressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/setup/progress');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {'completed_steps': [], 'current_step': 0};
  }
});

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  int _currentStep = 0;
  bool _loading = false;
  final Map<String, dynamic> _data = {};
  final _companyKey = GlobalKey<_CompanyStepState>();
  final _branchKey = GlobalKey<_BranchStepState>();
  final _departmentKey = GlobalKey<_DepartmentStepState>();
  final _designationKey = GlobalKey<_DesignationStepState>();
  final _shiftKey = GlobalKey<_ShiftStepState>();
  final _leaveKey = GlobalKey<_LeaveStepState>();
  final _attendanceKey = GlobalKey<_AttendanceStepState>();

  static const _steps = [
    {'title': 'Company Info', 'icon': Icons.business, 'key': 'company'},
    {'title': 'Branches', 'icon': Icons.location_on, 'key': 'branches'},
    {'title': 'Departments', 'icon': Icons.groups, 'key': 'departments'},
    {'title': 'Designations', 'icon': Icons.badge, 'key': 'designations'},
    {'title': 'Shifts', 'icon': Icons.schedule, 'key': 'shifts'},
    {'title': 'Leave Policy', 'icon': Icons.event_busy, 'key': 'leaves'},
    {'title': 'Attendance', 'icon': Icons.fingerprint, 'key': 'attendance'},
    {'title': 'Complete', 'icon': Icons.check_circle, 'key': 'complete'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isMobile
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: ApexColors.neutral0,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Icon(Icons.rocket_launch, color: ApexColors.primary600, size: 24),
          const SizedBox(width: 12),
          const Text('Setup Wizard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const Spacer(),
          Text('Step ${_currentStep + 1} of ${_steps.length}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 240,
          decoration: const BoxDecoration(
            color: ApexColors.neutral0,
            border: Border(right: BorderSide(color: ApexColors.neutral200)),
          ),
          child: _buildStepper(),
        ),
        Expanded(child: _buildStepContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildStepContent();
  }

  Widget _buildStepper() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _steps.length,
      itemBuilder: (context, i) {
        final step = _steps[i];
        final isActive = i == _currentStep;
        final isCompleted = i < _currentStep;

        return InkWell(
          onTap: () => setState(() => _currentStep = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? ApexColors.primary600.withOpacity(0.05) : null,
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: isActive ? ApexColors.primary600 : isCompleted ? ApexColors.successDark : ApexColors.neutral200,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? ApexColors.successDark : isActive ? ApexColors.primary600 : ApexColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text('${i + 1}', style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : ApexColors.neutral500,
                          )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? ApexColors.primary600 : ApexColors.neutral900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _CompanyStep(key: _companyKey, data: _data, onNext: _nextStep);
      case 1: return _BranchStep(key: _branchKey, data: _data, onNext: _nextStep);
      case 2: return _DepartmentStep(key: _departmentKey, data: _data, onNext: _nextStep);
      case 3: return _DesignationStep(key: _designationKey, data: _data, onNext: _nextStep);
      case 4: return _ShiftStep(key: _shiftKey, data: _data, onNext: _nextStep);
      case 5: return _LeaveStep(key: _leaveKey, data: _data, onNext: _nextStep);
      case 6: return _AttendanceStep(key: _attendanceKey, data: _data, onNext: _nextStep);
      case 7: return _CompleteStep(data: _data);
      default: return const SizedBox.shrink();
    }
  }

  void _harvestCurrentStep() {
    switch (_currentStep) {
      case 0:
        final s = _companyKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 1:
        final s = _branchKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 2:
        final s = _departmentKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 3:
        final s = _designationKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 4:
        final s = _shiftKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 5:
        final s = _leaveKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
      case 6:
        final s = _attendanceKey.currentState;
        if (s != null) _data.addAll(s.harvestData());
        break;
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: ApexColors.neutral0,
        border: Border(top: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () {
                _harvestCurrentStep();
                setState(() => _currentStep--);
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(foregroundColor: ApexColors.neutral900),
            ),
          const Spacer(),
          if (_currentStep < _steps.length - 1)
            ElevatedButton.icon(
              onPressed: _loading ? null : () {
                _harvestCurrentStep();
                _nextStep(_data);
              },
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward, size: 16),
              label: Text(_loading ? 'Saving...' : 'Continue'),
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }

  void _nextStep(Map<String, dynamic> data) async {
    _data.addAll(data);
    setState(() => _loading = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/setup/${_steps[_currentStep]['key']}', data: data);
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
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
}

class _CompanyStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _CompanyStep({super.key, required this.data, required this.onNext});

  @override
  State<_CompanyStep> createState() => _CompanyStepState();
}

class _CompanyStepState extends State<_CompanyStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _timezone = 'Asia/Kolkata';
  String _currency = 'INR';
  String _fyStart = '04-01';

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nameCtrl.text = d['company_name'] ?? '';
    _addressCtrl.text = d['address'] ?? '';
    _gstCtrl.text = d['gst_number'] ?? '';
    _panCtrl.text = d['pan_number'] ?? '';
    _emailCtrl.text = d['company_email'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    _timezone = d['timezone'] ?? 'Asia/Kolkata';
    _currency = d['currency'] ?? 'INR';
    _fyStart = d['financial_year_start'] ?? '04-01';
  }

  Map<String, dynamic> harvestData() => {
    'company_name': _nameCtrl.text,
    'address': _addressCtrl.text,
    'gst_number': _gstCtrl.text,
    'pan_number': _panCtrl.text,
    'company_email': _emailCtrl.text,
    'phone': _phoneCtrl.text,
    'timezone': _timezone,
    'currency': _currency,
    'financial_year_start': _fyStart,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            const Text('Set up your company profile. This information appears on payslips and official documents.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
            const SizedBox(height: 32),
            _card(children: [
              _field(_nameCtrl, 'Company Name *', Icons.business),
              _field(_emailCtrl, 'Company Email', Icons.email),
              _field(_phoneCtrl, 'Phone', Icons.phone),
              _field(_addressCtrl, 'Address', Icons.location_on, maxLines: 2),
            ]),
            const SizedBox(height: 16),
            _card(children: [
              Row(children: [
                Expanded(child: _field(_gstCtrl, 'GST Number', Icons.receipt)),
                const SizedBox(width: 16),
                Expanded(child: _field(_panCtrl, 'PAN Number', Icons.credit_card)),
              ]),
            ]),
            const SizedBox(height: 16),
            _card(children: [
              Row(children: [
                Expanded(child: _dropdown('Timezone', _timezone, ['Asia/Kolkata', 'Asia/Dubai', 'America/New_York', 'Europe/London'], (v) => setState(() => _timezone = v!))),
                const SizedBox(width: 16),
                Expanded(child: _dropdown('Currency', _currency, ['INR', 'USD', 'EUR', 'GBP', 'AED'], (v) => setState(() => _currency = v!))),
                const SizedBox(width: 16),
                Expanded(child: _dropdown('Financial Year Start', _fyStart, ['04-01', '01-01', '07-01'], (v) => setState(() => _fyStart = v!))),
              ]),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
      child: Column(children: children),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: label.contains('*') ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}

class _BranchStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _BranchStep({super.key, required this.data, required this.onNext});

  @override
  State<_BranchStep> createState() => _BranchStepState();
}

class _BranchStepState extends State<_BranchStep> {
  final List<Map<String, dynamic>> _branches = [
    {'name': 'Head Office', 'code': 'HO', 'isDefault': true},
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data['branches'] as List?;
    if (saved != null && saved.isNotEmpty) {
      _branches.clear();
      for (final b in saved) {
        _branches.add(Map<String, dynamic>.from(b as Map));
      }
    }
  }

  Map<String, dynamic> harvestData() => {'branches': _branches};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Branches', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Add your office locations. At least one branch is required.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ..._branches.asMap().entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
            child: Row(children: [
              Icon(Icons.location_on, size: 18, color: ApexColors.primary600),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.value['name'] as String, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                Text('Code: ${entry.value['code']}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
              ])),
              if (entry.value['isDefault'] == true)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ApexColors.primary600))),
            ]),
          )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addBranch,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Branch'),
          ),
        ],
      ),
    );
  }

  void _addBranch() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Branch'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Branch Name')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Branch Code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _branches.add({'name': nameCtrl.text, 'code': codeCtrl.text, 'isDefault': false}));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DepartmentStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _DepartmentStep({super.key, required this.data, required this.onNext});

  @override
  State<_DepartmentStep> createState() => _DepartmentStepState();
}

class _DepartmentStepState extends State<_DepartmentStep> {
  final List<Map<String, dynamic>> _departments = [
    {'name': 'Human Resources', 'code': 'HR'},
    {'name': 'Finance', 'code': 'FIN'},
    {'name': 'Engineering', 'code': 'ENG'},
    {'name': 'Operations', 'code': 'OPS'},
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data['departments'] as List?;
    if (saved != null && saved.isNotEmpty) {
      _departments.clear();
      for (final d in saved) {
        _departments.add(Map<String, dynamic>.from(d as Map));
      }
    }
  }

  Map<String, dynamic> harvestData() => {'departments': _departments};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Departments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Add your organizational departments.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _departments.map((d) => Chip(
              label: Text('${d['name']} (${d['code']})'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _departments.remove(d)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addDepartment,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Department'),
          ),
        ],
      ),
    );
  }

  void _addDepartment() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Department Name')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Department Code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _departments.add({'name': nameCtrl.text, 'code': codeCtrl.text}));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DesignationStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _DesignationStep({super.key, required this.data, required this.onNext});

  @override
  State<_DesignationStep> createState() => _DesignationStepState();
}

class _DesignationStepState extends State<_DesignationStep> {
  final List<Map<String, dynamic>> _designations = [
    {'name': 'CEO', 'code': 'CEO'},
    {'name': 'Manager', 'code': 'MGR'},
    {'name': 'Team Lead', 'code': 'TL'},
    {'name': 'Senior Developer', 'code': 'SDEV'},
    {'name': 'Developer', 'code': 'DEV'},
    {'name': 'HR Executive', 'code': 'HRE'},
    {'name': 'Accountant', 'code': 'ACC'},
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data['designations'] as List?;
    if (saved != null && saved.isNotEmpty) {
      _designations.clear();
      for (final d in saved) {
        _designations.add(Map<String, dynamic>.from(d as Map));
      }
    }
  }

  Map<String, dynamic> harvestData() => {'designations': _designations};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Designations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Add job titles and designations for your organization.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _designations.map((d) => Chip(
              label: Text('${d['name']} (${d['code']})'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _designations.remove(d)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addDesignation,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Designation'),
          ),
        ],
      ),
    );
  }

  void _addDesignation() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Designation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Designation Name')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Designation Code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _designations.add({'name': nameCtrl.text, 'code': codeCtrl.text}));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ShiftStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _ShiftStep({super.key, required this.data, required this.onNext});

  @override
  State<_ShiftStep> createState() => _ShiftStepState();
}

class _ShiftStepState extends State<_ShiftStep> {
  final List<Map<String, dynamic>> _shifts = [
    {'name': 'General', 'start': '09:00', 'end': '18:00', 'grace': '10'},
    {'name': 'Morning', 'start': '06:00', 'end': '14:00', 'grace': '10'},
    {'name': 'Evening', 'start': '14:00', 'end': '22:00', 'grace': '10'},
    {'name': 'Night', 'start': '22:00', 'end': '06:00', 'grace': '10'},
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data['shifts'] as List?;
    if (saved != null && saved.isNotEmpty) {
      _shifts.clear();
      for (final s in saved) {
        _shifts.add(Map<String, dynamic>.from(s as Map));
      }
    }
  }

  Map<String, dynamic> harvestData() => {'shifts': _shifts};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shifts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Define work shifts for your organization.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ..._shifts.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
            child: Row(children: [
              Icon(Icons.schedule, size: 18, color: ApexColors.primary600),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] as String, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                Text('${s['start']} - ${s['end']} • Grace: ${s['grace']} min', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
              ])),
            ]),
          )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addShift,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Shift'),
          ),
        ],
      ),
    );
  }

  void _addShift() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Shift'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shift Name')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _shifts.add({'name': nameCtrl.text, 'start': '09:00', 'end': '18:00', 'grace': '10'}));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _LeaveStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _LeaveStep({super.key, required this.data, required this.onNext});

  @override
  State<_LeaveStep> createState() => _LeaveStepState();
}

class _LeaveStepState extends State<_LeaveStep> {
  final List<Map<String, dynamic>> _leaveTypes = [
    {'name': 'Casual Leave', 'code': 'CL', 'days': '12', 'carry': false},
    {'name': 'Sick Leave', 'code': 'SL', 'days': '12', 'carry': false},
    {'name': 'Earned Leave', 'code': 'EL', 'days': '15', 'carry': true},
    {'name': 'Maternity Leave', 'code': 'ML', 'days': '180', 'carry': false},
    {'name': 'Paternity Leave', 'code': 'PL', 'days': '15', 'carry': false},
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.data['leave_types'] as List?;
    if (saved != null && saved.isNotEmpty) {
      _leaveTypes.clear();
      for (final l in saved) {
        _leaveTypes.add(Map<String, dynamic>.from(l as Map));
      }
    }
  }

  Map<String, dynamic> harvestData() => {'leave_types': _leaveTypes};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Configure leave types and annual allocations.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ..._leaveTypes.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
            child: Row(children: [
              Icon(Icons.event_busy, size: 18, color: ApexColors.primary600),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l['name']} (${l['code']})', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                Text('${l['days']} days/year • Carry forward: ${l['carry'] == true ? 'Yes' : 'No'}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
              ])),
            ]),
          )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addLeaveType,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Leave Type'),
          ),
        ],
      ),
    );
  }

  void _addLeaveType() {
    final nameCtrl = TextEditingController();
    final daysCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Leave Type'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Leave Type Name')),
          const SizedBox(height: 8),
          TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Days per Year'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _leaveTypes.add({'name': nameCtrl.text, 'code': nameCtrl.text.substring(0, 2).toUpperCase(), 'days': daysCtrl.text, 'carry': false}));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onNext;
  const _AttendanceStep({super.key, required this.data, required this.onNext});

  @override
  State<_AttendanceStep> createState() => _AttendanceStepState();
}

class _AttendanceStepState extends State<_AttendanceStep> {
  String _weeklyOff1 = 'Saturday';
  String _weeklyOff2 = 'Sunday';
  bool _autoShift = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _weeklyOff1 = d['weekly_off_1'] ?? 'Saturday';
    _weeklyOff2 = d['weekly_off_2'] ?? 'Sunday';
    _autoShift = d['auto_shift'] ?? true;
    _biometricEnabled = d['biometric_enabled'] ?? false;
  }

  Map<String, dynamic> harvestData() => {
    'weekly_off_1': _weeklyOff1,
    'weekly_off_2': _weeklyOff2,
    'auto_shift': _autoShift,
    'biometric_enabled': _biometricEnabled,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          const Text('Configure attendance rules and weekly offs.', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
            child: Column(children: [
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _weeklyOff1,
                  decoration: const InputDecoration(labelText: 'Weekly Off 1'),
                  items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _weeklyOff1 = v!),
                )),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _weeklyOff2,
                  decoration: const InputDecoration(labelText: 'Weekly Off 2'),
                  items: ['None', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _weeklyOff2 = v!),
                )),
              ]),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto Shift Detection'),
                subtitle: const Text('Automatically assign shifts based on punch time'),
                value: _autoShift,
                onChanged: (v) => setState(() => _autoShift = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Biometric Integration'),
                subtitle: const Text('Enable eSSL biometric device sync'),
                value: _biometricEnabled,
                onChanged: (v) => setState(() => _biometricEnabled = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CompleteStep extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CompleteStep({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: ApexColors.successDark, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Setup Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            const Text('Your HRMS is configured and ready to use.', style: TextStyle(fontSize: 15, color: ApexColors.neutral500)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard, size: 18),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ApexColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

