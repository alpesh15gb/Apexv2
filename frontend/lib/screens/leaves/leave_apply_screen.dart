import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_text_field.dart';

class LeaveApplyScreen extends ConsumerStatefulWidget {
  const LeaveApplyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends ConsumerState<LeaveApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedLeaveTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLeaveTypeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a leave category'), backgroundColor: ApexColors.error),
        );
        return;
      }

      final data = {
        'leave_type_id': _selectedLeaveTypeId,
        'start_date': _startDate.toIso8601String().substring(0, 10),
        'end_date': _endDate.toIso8601String().substring(0, 10),
        'reason': _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      };

      try {
        await ref.read(leaveRequestsProvider.notifier).applyLeave(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Leave application submitted'), backgroundColor: ApexColors.success),
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
    final typesAsync = ref.watch(leaveTypesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('Apply for Leave', style: ApexTypography.sectionTitle),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ApexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Leave Details', style: ApexTypography.cardTitle),
                const SizedBox(height: 24),
                typesAsync.maybeWhen(
                  data: (types) => ApexDropdown<String>(
                    label: 'Leave Category',
                    value: _selectedLeaveTypeId,
                    required: true,
                    items: types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _selectedLeaveTypeId = v),
                  ),
                  loading: () => SizedBox(
                    height: 56,
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  orElse: () => const SizedBox(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ApexTextField(
                        label: 'Start Date',
                        controller: TextEditingController(text: DateFormat('MMM dd, yyyy').format(_startDate)),
                        readOnly: true,
                        prefixIcon: Icons.calendar_today,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate.add(const Duration(days: 1));
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ApexTextField(
                        label: 'End Date',
                        controller: TextEditingController(text: DateFormat('MMM dd, yyyy').format(_endDate)),
                        readOnly: true,
                        prefixIcon: Icons.calendar_today,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ApexTextField(
                  label: 'Reason for Leave',
                  controller: _reasonController,
                  maxLines: 3,
                  hint: 'Describe your reason for leave...',
                  required: true,
                ),
                const SizedBox(height: 32),
                ApexButton(
                  label: 'Submit Application',
                  icon: Icons.send,
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
