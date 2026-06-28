import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';

class StudentEditScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentEditScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends ConsumerState<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _admissionNumberCtrl = TextEditingController();
  final _rollNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _medicalCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  String _selectedStatus = 'active';
  DateTime? _dateOfBirth;
  DateTime? _admissionDate;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/school/students/${widget.studentId}');
      final s = res.data;
      setState(() {
        _firstNameCtrl.text = s['first_name'] ?? '';
        _lastNameCtrl.text = s['last_name'] ?? '';
        _admissionNumberCtrl.text = s['admission_number'] ?? '';
        _rollNumberCtrl.text = s['roll_number'] ?? '';
        _emailCtrl.text = s['email'] ?? '';
        _phoneCtrl.text = s['phone'] ?? '';
        _addressCtrl.text = s['address'] ?? '';
        _medicalCtrl.text = s['medical_conditions'] ?? '';
        _allergiesCtrl.text = s['allergies'] ?? '';
        _emergencyNameCtrl.text = s['emergency_contact_name'] ?? '';
        _emergencyPhoneCtrl.text = s['emergency_contact_phone'] ?? '';
        _selectedGender = s['gender'];
        _selectedBloodGroup = s['blood_group'];
        _selectedStatus = s['status'] ?? 'active';
        if (s['date_of_birth'] != null) {
          _dateOfBirth = DateTime.tryParse(s['date_of_birth']);
        }
        if (s['admission_date'] != null) {
          _admissionDate = DateTime.tryParse(s['admission_date']);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: ApexColors.error),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/school/students/${widget.studentId}', data: {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'gender': _selectedGender,
        'blood_group': _selectedBloodGroup,
        'status': _selectedStatus,
        'date_of_birth': _dateOfBirth?.toIso8601String().substring(0, 10),
        'admission_date': _admissionDate?.toIso8601String().substring(0, 10),
        'roll_number': _rollNumberCtrl.text.trim().isNotEmpty ? _rollNumberCtrl.text.trim() : null,
        'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        'medical_conditions': _medicalCtrl.text.trim().isNotEmpty ? _medicalCtrl.text.trim() : null,
        'allergies': _allergiesCtrl.text.trim().isNotEmpty ? _allergiesCtrl.text.trim() : null,
        'emergency_contact_name': _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : null,
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated'), backgroundColor: ApexColors.success),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _admissionNumberCtrl.dispose();
    _rollNumberCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _medicalCtrl.dispose();
    _allergiesCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: ApexColors.neutral50,
        appBar: const ApexAppBar(title: 'Edit Student'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(
        title: 'Edit ${_firstNameCtrl.text} ${_lastNameCtrl.text}',
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
              ApexSection(title: 'PERSONAL INFORMATION', children: [
                Row(
                  children: [
                    Expanded(child: ApexTextField(label: 'Admission Number', controller: _admissionNumberCtrl, enabled: false)),
                    const SizedBox(width: 16),
                    Expanded(child: ApexTextField(label: 'Roll Number', controller: _rollNumberCtrl)),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                ApexTextField(label: 'Address', controller: _addressCtrl, maxLines: 2),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'ACADEMIC', children: [
                Row(
                  children: [
                    Expanded(
                      child: ApexDropdown<String>(
                        label: 'Status',
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
                          DropdownMenuItem(value: 'transferred', child: Text('Transferred')),
                          DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: ApexDatePicker(label: 'Admission Date', value: _admissionDate, onChanged: (v) => setState(() => _admissionDate = v))),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              ApexSection(title: 'MEDICAL', children: [
                ApexTextField(label: 'Medical Conditions', controller: _medicalCtrl, maxLines: 2),
                const SizedBox(height: 16),
                ApexTextField(label: 'Allergies', controller: _allergiesCtrl, maxLines: 2),
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
