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
      backgroundColor: _bg,
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
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: _primary, size: 24),
          const SizedBox(width: 12),
          const Text('Setup Wizard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
          const Spacer(),
          Text('Step ${_currentStep + 1} of ${_steps.length}', style: const TextStyle(fontSize: 13, color: _muted)),
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
            color: _surface,
            border: Border(right: BorderSide(color: _border)),
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
              color: isActive ? _primary.withOpacity(0.05) : null,
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: isActive ? _primary : isCompleted ? _success : _border,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? _success : isActive ? _primary : _border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text('${i + 1}', style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : _muted,
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
                      color: isActive ? _primary : _text,
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
      case 0: return _CompanyStep(data: _data, onNext: _nextStep);
      case 1: return _BranchStep(data: _data, onNext: _nextStep);
      case 2: return _DepartmentStep(data: _data, onNext: _nextStep);
      case 3: return _DesignationStep(data: _data, onNext: _nextStep);
      case 4: return _ShiftStep(data: _data, onNext: _nextStep);
      case 5: return _LeaveStep(data: _data, onNext: _nextStep);
      case 6: return _AttendanceStep(data: _data, onNext: _nextStep);
      case 7: return _CompleteStep(data: _data);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(foregroundColor: _text),
            ),
          const Spacer(),
          if (_currentStep < _steps.length - 1)
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _nextStep(_data),
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward, size: 16),
              label: Text(_loading ? 'Saving...' : 'Continue'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: _danger),
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
  const _CompanyStep({required this.data, required this.onNext});

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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 8),
            const Text('Set up your company profile. This information appears on payslips and official documents.', style: TextStyle(fontSize: 13, color: _muted)),
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
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
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
  const _BranchStep({required this.data, required this.onNext});

  @override
  State<_BranchStep> createState() => _BranchStepState();
}

class _BranchStepState extends State<_BranchStep> {
  final _branches = [
    {'name': 'Head Office', 'code': 'HO', 'isDefault': true},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Branches', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Add your office locations. At least one branch is required.', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ..._branches.asMap().entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
            child: Row(children: [
              const Icon(Icons.location_on, size: 18, color: _primary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.value['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                Text('Code: ${entry.value['code']}', style: const TextStyle(fontSize: 12, color: _muted)),
              ])),
              if (entry.value['isDefault'] == true)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _primary))),
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
  const _DepartmentStep({required this.data, required this.onNext});

  @override
  State<_DepartmentStep> createState() => _DepartmentStepState();
}

class _DepartmentStepState extends State<_DepartmentStep> {
  final _departments = [
    {'name': 'Human Resources', 'code': 'HR'},
    {'name': 'Finance', 'code': 'FIN'},
    {'name': 'Engineering', 'code': 'ENG'},
    {'name': 'Operations', 'code': 'OPS'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Departments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Add your organizational departments.', style: TextStyle(fontSize: 13, color: _muted)),
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
  const _DesignationStep({required this.data, required this.onNext});

  @override
  State<_DesignationStep> createState() => _DesignationStepState();
}

class _DesignationStepState extends State<_DesignationStep> {
  final _designations = [
    {'name': 'CEO', 'code': 'CEO'},
    {'name': 'Manager', 'code': 'MGR'},
    {'name': 'Team Lead', 'code': 'TL'},
    {'name': 'Senior Developer', 'code': 'SDEV'},
    {'name': 'Developer', 'code': 'DEV'},
    {'name': 'HR Executive', 'code': 'HRE'},
    {'name': 'Accountant', 'code': 'ACC'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Designations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Add job titles and designations for your organization.', style: TextStyle(fontSize: 13, color: _muted)),
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
  const _ShiftStep({required this.data, required this.onNext});

  @override
  State<_ShiftStep> createState() => _ShiftStepState();
}

class _ShiftStepState extends State<_ShiftStep> {
  final _shifts = [
    {'name': 'General', 'start': '09:00', 'end': '18:00', 'grace': '10'},
    {'name': 'Morning', 'start': '06:00', 'end': '14:00', 'grace': '10'},
    {'name': 'Evening', 'start': '14:00', 'end': '22:00', 'grace': '10'},
    {'name': 'Night', 'start': '22:00', 'end': '06:00', 'grace': '10'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shifts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Define work shifts for your organization.', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ..._shifts.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
            child: Row(children: [
              const Icon(Icons.schedule, size: 18, color: _primary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                Text('${s['start']} - ${s['end']} • Grace: ${s['grace']} min', style: const TextStyle(fontSize: 12, color: _muted)),
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
  const _LeaveStep({required this.data, required this.onNext});

  @override
  State<_LeaveStep> createState() => _LeaveStepState();
}

class _LeaveStepState extends State<_LeaveStep> {
  final _leaveTypes = [
    {'name': 'Casual Leave', 'code': 'CL', 'days': '12', 'carry': false},
    {'name': 'Sick Leave', 'code': 'SL', 'days': '12', 'carry': false},
    {'name': 'Earned Leave', 'code': 'EL', 'days': '15', 'carry': true},
    {'name': 'Maternity Leave', 'code': 'ML', 'days': '180', 'carry': false},
    {'name': 'Paternity Leave', 'code': 'PL', 'days': '15', 'carry': false},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Configure leave types and annual allocations.', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ..._leaveTypes.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
            child: Row(children: [
              const Icon(Icons.event_busy, size: 18, color: _primary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l['name']} (${l['code']})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                Text('${l['days']} days/year • Carry forward: ${l['carry'] == true ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 12, color: _muted)),
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
  const _AttendanceStep({required this.data, required this.onNext});

  @override
  State<_AttendanceStep> createState() => _AttendanceStepState();
}

class _AttendanceStepState extends State<_AttendanceStep> {
  String _weeklyOff1 = 'Saturday';
  String _weeklyOff2 = 'Sunday';
  bool _autoShift = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 8),
          const Text('Configure attendance rules and weekly offs.', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
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
              decoration: const BoxDecoration(color: _success, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Setup Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 8),
            const Text('Your HRMS is configured and ready to use.', style: TextStyle(fontSize: 15, color: _muted)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard, size: 18),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
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
