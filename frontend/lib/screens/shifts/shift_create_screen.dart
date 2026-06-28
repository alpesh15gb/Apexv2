import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/shift_provider.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_text_field.dart';

class ShiftCreateScreen extends ConsumerStatefulWidget {
  final String? shiftId;
  const ShiftCreateScreen({Key? key, this.shiftId}) : super(key: key);

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

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.shiftId != null) {
      _isLoading = true;
      _loadShift();
    }
  }

  Future<void> _loadShift() async {
    try {
      final asyncShifts = ref.read(shiftListProvider);
      final shifts = asyncShifts.value ?? [];
      final shift = shifts.firstWhere((s) => s.id == widget.shiftId);
      setState(() {
        _nameController.text = shift.name;
        final startParts = shift.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
        final endParts = shift.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
        _graceController.text = shift.gracePeriodMinutes.toString();
        _lateRuleController.text = shift.lateRuleMinutes.toString();
        _earlyOutController.text = shift.earlyRuleMinutes.toString();
        _overtimeThresholdController.text = shift.overtimeThresholdMinutes.toString();
        _isNightShift = shift.isNightShift;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shift: $e'), backgroundColor: ApexColors.error),
        );
        context.pop();
      }
    }
  }

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
      setState(() => _isSaving = true);
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
        if (widget.shiftId != null) {
          await ref.read(shiftListProvider.notifier).updateShift(widget.shiftId!, data);
        } else {
          await ref.read(shiftListProvider.notifier).addShift(data);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.shiftId != null ? 'Shift updated successfully' : 'Shift created successfully'), backgroundColor: ApexColors.success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: ApexColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(title: widget.shiftId != null ? 'Edit Shift' : 'Create Shift'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ApexCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Shift Details', style: ApexTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                const SizedBox(height: 20),
                ApexTextField(
                  label: 'Shift Name',
                  controller: _nameController,
                  required: true,
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
                            labelStyle: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                          ),
                          child: Text(_startTime.format(context), style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
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
                            labelStyle: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                          ),
                          child: Text(_endTime.format(context), style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
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
                  title: Text('Night Shift', style: ApexTypography.body.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w500)),
                  value: _isNightShift,
                  activeColor: ApexColors.primary,
                  onChanged: (v) => setState(() => _isNightShift = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                ApexButton(
                  label: _isSaving
                      ? (widget.shiftId != null ? 'Updating...' : 'Creating...')
                      : (widget.shiftId != null ? 'Update Shift' : 'Create Shift'),
                  expanded: true,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return ApexTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
    );
  }
}

