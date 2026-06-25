import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
            const SnackBar(content: Text('Employee created'), backgroundColor: Color(0xFF16A34A)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: _danger),
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
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _SectionCard(
                title: 'BASIC INFORMATION',
                children: [
                  _field('Employee Code', _codeController, required: true),
                  _field('First Name', _firstNameController, required: true),
                  _field('Last Name', _lastNameController, required: true),
                  _field('Email', _emailController, keyboardType: TextInputType.emailAddress),
                  _field('Phone', _phoneController, keyboardType: TextInputType.phone),
                  _dropdown('Gender', _selectedGender, ['Male', 'Female', 'Other'], (v) => setState(() => _selectedGender = v)),
                ],
              ),
              const SizedBox(height: 16),

              // Employment Details
              _SectionCard(
                title: 'EMPLOYMENT DETAILS',
                children: [
                  departmentsAsync.when(
                    data: (deps) => _dropdown(
                      'Department',
                      _selectedDepartmentId,
                      deps.map((d) => {'id': d.id, 'name': d.name}).toList(),
                      (v) => setState(() => _selectedDepartmentId = v),
                      isId: true,
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  designationsAsync.when(
                    data: (desgs) => _dropdown(
                      'Designation',
                      _selectedDesignationId,
                      desgs.map((d) => {'id': d.id, 'name': d.name}).toList(),
                      (v) => setState(() => _selectedDesignationId = v),
                      isId: true,
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  branchesAsync.when(
                    data: (branches) => _dropdown(
                      'Branch',
                      _selectedBranchId,
                      branches.map((b) => {'id': b.id, 'name': b.name}).toList(),
                      (v) => setState(() => _selectedBranchId = v),
                      isId: true,
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(),
                  ),
                  _dateField('Joining Date', _joiningDate, (v) => setState(() => _joiningDate = v)),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Create Employee', style: ApexTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<dynamic> items, ValueChanged<String?> onChanged, {bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: items.map((item) {
              if (item is String) return DropdownMenuItem(value: item, child: Text(item));
              return DropdownMenuItem(value: item['id'], child: Text(item['name']));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, ValueChanged<DateTime?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: _muted),
                  const SizedBox(width: 10),
                  Text(
                    date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date',
                    style: ApexTypography.body.copyWith(color: date != null ? _text : _muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ApexTypography.sectionHeader),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
