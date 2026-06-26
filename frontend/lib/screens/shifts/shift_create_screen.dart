import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/shift_provider.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
            const SnackBar(content: Text('Shift created successfully'), backgroundColor: _success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: _danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'Create Shift'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Shift Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Shift Name *',
                    labelStyle: const TextStyle(color: _muted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary)),
                    filled: true,
                    fillColor: _surface,
                  ),
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
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            labelStyle: const TextStyle(color: _muted),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                          ),
                          child: Text(_startTime.format(context), style: const TextStyle(color: _text)),
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
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            labelStyle: const TextStyle(color: _muted),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                          ),
                          child: Text(_endTime.format(context), style: const TextStyle(color: _text)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _numberField(_graceController, 'Grace Period (min)')),
                    const SizedBox(width: 16),
                    Expanded(child: _numberField(_lateRuleController, 'Late Rule (min)')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _numberField(_earlyOutController, 'Early Out (min)')),
                    const SizedBox(width: 16),
                    Expanded(child: _numberField(_overtimeThresholdController, 'OT Threshold (min)')),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Night Shift', style: TextStyle(color: _text, fontWeight: FontWeight.w500)),
                  value: _isNightShift,
                  activeColor: _primary,
                  onChanged: (v) => setState(() => _isNightShift = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Shift', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary)),
        filled: true,
        fillColor: _surface,
      ),
      keyboardType: TextInputType.number,
    );
  }
}
