import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/visitor_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/visitor_service.dart';

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
          const SnackBar(content: Text('Please select a host employee'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final service = ref.read(visitorServiceProvider);
        
        // 1. Register visitor profile
        final visitor = await service.registerVisitor({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'id_proof_type': _idTypeController.text.trim(),
          'id_proof_number': _idNumberController.text.trim(),
          'company': _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        });

        // 2. Create visitor pass
        await ref.read(visitorPassesProvider.notifier).createPass({
          'visitor_id': visitor.id,
          'host_employee_id': _selectedHostId,
          'purpose': _purposeController.text.trim(),
          'expected_date': _expectedDate.toIso8601String().substring(0, 10),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visitor Pass created successfully'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Visitor'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Visitor Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Visitor Name *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idTypeController,
                      decoration: const InputDecoration(labelText: 'ID Proof Type'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Proof Number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company / Organization'),
              ),
              const SizedBox(height: 24),
              Text('Visit Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(),
              employeesAsync.employees.maybeWhen(
                data: (list) => DropdownButtonFormField<String>(
                  value: _selectedHostId,
                  decoration: const InputDecoration(labelText: 'Host Employee *'),
                  items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                  onChanged: (v) => setState(() => _selectedHostId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose of Visit *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _expectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Expected Date'),
                  child: Text(DateFormat('MMM dd, yyyy').format(_expectedDate)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Register & Create Pass'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
