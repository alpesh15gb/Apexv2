import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '4370');
  String _deviceType = 'biometric';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device added successfully'), backgroundColor: ApexColors.success),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Add Device',
        description: 'Register and pair a new biometric device terminal with the server.',
        actions: [
          ApexButton(
            label: 'Save Device',
            onPressed: _save,
            type: ApexButtonType.primary,
            icon: Icons.save_outlined,
          ),
        ],
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hardware Profile', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    ApexTextField(label: 'Device Name *', controller: _nameCtrl, required: true),
                    const SizedBox(height: 12),
                    ApexTextField(label: 'Serial Number *', controller: _serialCtrl, required: true),
                    const SizedBox(height: 12),
                    ApexDropdown<String>(
                      label: 'Device Type',
                      value: _deviceType,
                      items: const [
                        DropdownMenuItem(value: 'biometric', child: Text('Biometric Fingerprint/Face')),
                        DropdownMenuItem(value: 'rfid', child: Text('RFID Card Reader')),
                        DropdownMenuItem(value: 'turnstile', child: Text('Access Control Turnstile')),
                      ],
                      onChanged: (v) => setState(() => _deviceType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Network Settings', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: ApexTextField(label: 'IP Address *', controller: _ipCtrl, required: true, hint: 'e.g. 192.168.1.100')),
                        const SizedBox(width: 16),
                        Expanded(child: ApexTextField(label: 'Port *', controller: _portCtrl, required: true, keyboardType: TextInputType.number)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
