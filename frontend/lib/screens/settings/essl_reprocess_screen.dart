import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';

class EsslReprocessScreen extends ConsumerStatefulWidget {
  final String serverId;

  const EsslReprocessScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  ConsumerState<EsslReprocessScreen> createState() => _EsslReprocessScreenState();
}

class _EsslReprocessScreenState extends ConsumerState<EsslReprocessScreen> {
  String _mode = 'date_range';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  final _employeeIdController = TextEditingController();
  final _departmentIdController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _departmentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Reprocess Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.refresh, color: ApexColors.primary),
                      const SizedBox(width: 8),
                      Text('Attendance Reprocessing', style: ApexTypography.sectionTitle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reprocess existing raw punch logs into attendance records without re-downloading from eSSL. '
                    'This resets processed logs and re-runs the attendance calculator.',
                    style: ApexTypography.body.copyWith(color: ApexColors.neutral600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Reprocessing Mode', style: ApexTypography.cardTitle),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'date_range', label: Text('Date Range'), icon: Icon(Icons.date_range)),
                ButtonSegment(value: 'employee', label: Text('Employee'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'department', label: Text('Department'), icon: Icon(Icons.group)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return ApexColors.primary;
                  return ApexColors.neutral700;
                }),
              ),
            ),
            const SizedBox(height: 24),
            if (_mode == 'date_range') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM dd, yyyy').format(_fromDate)),
                      onPressed: () => _selectDate(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApexColors.primary,
                        side: BorderSide(color: ApexColors.neutral300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM dd, yyyy').format(_toDate)),
                      onPressed: () => _selectDate(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApexColors.primary,
                        side: BorderSide(color: ApexColors.neutral300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_mode == 'employee') ...[
              ApexTextField(
                label: 'Employee ID',
                hint: 'Enter the employee UUID',
                controller: _employeeIdController,
              ),
            ] else ...[
              ApexTextField(
                label: 'Department ID',
                hint: 'Enter the department UUID',
                controller: _departmentIdController,
              ),
            ],
            const SizedBox(height: 24),
            if (_result != null) ...[
              ApexCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: ApexColors.success),
                        const SizedBox(width: 8),
                        Text('Reprocessing Complete', style: ApexTypography.cardTitle.copyWith(color: ApexColors.success)),
                      ],
                    ),
                    Divider(height: 20, color: ApexColors.neutral200),
                    _buildResultRow('Raw Logs Reset', '${_result!['reset'] ?? 0}'),
                    _buildResultRow('Records Processed', '${_result!['processed'] ?? 0}'),
                    _buildResultRow('Created', '${_result!['created'] ?? 0}'),
                    _buildResultRow('Updated', '${_result!['updated'] ?? 0}'),
                    _buildResultRow('Errors', '${_result!['errors'] ?? 0}',
                        _result!['errors'] != null && _result!['errors'] > 0 ? ApexColors.error : null),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              ApexCard(
                child: Row(
                  children: [
                    Icon(Icons.error, color: ApexColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: ApexTypography.body.copyWith(color: ApexColors.error))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ApexButton(
              label: _isProcessing ? 'Processing...' : 'Start Reprocessing',
              onPressed: _isProcessing ? null : _startReprocessing,
              type: ApexButtonType.primary,
              icon: Icons.play_arrow,
              loading: _isProcessing,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.body),
          Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ApexColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ApexColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  Future<void> _startReprocessing() async {
    setState(() {
      _isProcessing = true;
      _result = null;
      _error = null;
    });

    try {
      final service = ref.read(esslServiceProvider);
      final result = await service.reprocessAttendance(
        widget.serverId,
        fromDate: _mode == 'date_range' ? DateFormat('yyyy-MM-dd').format(_fromDate) : null,
        toDate: _mode == 'date_range' ? DateFormat('yyyy-MM-dd').format(_toDate) : null,
        employeeId: _mode == 'employee' && _employeeIdController.text.isNotEmpty
            ? _employeeIdController.text.trim()
            : null,
        departmentId: _mode == 'department' && _departmentIdController.text.isNotEmpty
            ? _departmentIdController.text.trim()
            : null,
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }
}
