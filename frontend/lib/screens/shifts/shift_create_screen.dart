import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/shift_provider.dart';

class ShiftCreateScreen extends ConsumerStatefulWidget {
  const ShiftCreateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShiftCreateScreen> createState() => _ShiftCreateScreenState();
}

class _ShiftCreateScreenState extends ConsumerState<ShiftCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _graceController = TextEditingController(text: '10');
  final _lateRuleController = TextEditingController(text: '15');
  final _earlyOutController = TextEditingController(text: '15');
  final _overtimeThresholdController = TextEditingController(text: '30');

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isNightShift = false;

  @override
  void dispose() {
    _nameController.dispose();
    _graceController.dispose();
    _lateRuleController.dispose();
    _earlyOutController.dispose();
    _overtimeThresholdController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final hr = t.hour.toString().padLeft(2, '0');
    final mn = t.minute.toString().padLeft(2, '0');
    return '$hr:$mn:00';
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'start_time': _formatTime(_startTime),
        'end_time': _formatTime(_endTime),
        'grace_period_minutes': int.parse(_graceController.text),
        'late_rule_minutes': int.parse(_lateRuleController.text),
        'early_rule_minutes': int.parse(_earlyOutController.text),
        'overtime_threshold_minutes': int.parse(_overtimeThresholdController.text),
        'is_night_shift': _isNightShift,
        'is_active': true,
      };

      try {
        await ref.read(shiftListProvider.notifier).addShift(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift created successfully'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shift'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shift Name *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Time'),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _graceController,
                decoration: const InputDecoration(labelText: 'Grace Period (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lateRuleController,
                decoration: const InputDecoration(labelText: 'Late Rule Threshold (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _earlyOutController,
                decoration: const InputDecoration(labelText: 'Early Out Threshold (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _overtimeThresholdController,
                decoration: const InputDecoration(labelText: 'Overtime Threshold (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Night Shift?'),
                value: _isNightShift,
                onChanged: (v) => setState(() => _isNightShift = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Create Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
