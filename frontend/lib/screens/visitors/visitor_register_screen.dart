import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/visitor_service.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/page_wrapper.dart';

class VisitorRegisterScreen extends ConsumerStatefulWidget {
  const VisitorRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VisitorRegisterScreen> createState() => _VisitorRegisterScreenState();
}

class _VisitorRegisterScreenState extends ConsumerState<VisitorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idTypeController = TextEditingController(text: 'Passport');
  final _idNumberController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _purposeController = TextEditingController();

  String? _selectedHostId;
  DateTime _expectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHostId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a host employee'), backgroundColor: ApexColors.error),
        );
        return;
      }

      try {
        final service = ref.read(visitorServiceProvider);
        
        final visitor = await service.registerVisitor({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'id_proof_type': _idTypeController.text.trim(),
          'id_proof_number': _idNumberController.text.trim(),
          'company': _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        });

        await ref.read(visitorPassesProvider.notifier).createPass({
          'visitor_id': visitor.id,
          'host_employee_id': _selectedHostId,
          'purpose': _purposeController.text.trim(),
          'expected_date': _expectedDate.toIso8601String().substring(0, 10),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visitor Pass created successfully'), backgroundColor: ApexColors.success),
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
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Register Visitor',
        description: 'Record guest identification details and generate check-in access passes.',
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ApexSection(
                  title: 'VISITOR INFORMATION',
                  children: [
                    ApexTextField(label: 'Visitor Name', controller: _nameController, required: true),
                    const SizedBox(height: 16),
                    ApexTextField(label: 'Phone Number', controller: _phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    ApexTextField(label: 'Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: ApexTextField(label: 'ID Proof Type', controller: _idTypeController)),
                        const SizedBox(width: 16),
                        Expanded(child: ApexTextField(label: 'ID Proof Number', controller: _idNumberController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ApexTextField(label: 'Company / Organization', controller: _companyController),
                  ],
                ),
                const SizedBox(height: 24),
                ApexSection(
                  title: 'VISIT DETAILS',
                  children: [
                    employeesAsync.employees.maybeWhen(
                      data: (list) => ApexDropdown<String>(
                        label: 'Host Employee',
                        value: _selectedHostId,
                        required: true,
                        items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                        onChanged: (v) => setState(() => _selectedHostId = v),
                      ),
                      orElse: () => const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    ApexTextField(label: 'Purpose of Visit', controller: _purposeController, required: true),
                    const SizedBox(height: 16),
                    ApexDatePicker(
                      label: 'Expected Date',
                      value: _expectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      onChanged: (picked) { if (picked != null) setState(() => _expectedDate = picked); },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ApexButton(
                  label: 'Register & Create Pass',
                  icon: Icons.person_add,
                  expanded: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
