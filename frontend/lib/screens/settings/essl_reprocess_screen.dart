import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reprocess Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.refresh, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Attendance Reprocessing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reprocess existing raw punch logs into attendance records without re-downloading from eSSL. '
                      'This resets processed logs and re-runs the attendance calculator.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Reprocessing Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'date_range', label: Text('Date Range'), icon: Icon(Icons.date_range)),
                ButtonSegment(value: 'employee', label: Text('Employee'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'department', label: Text('Department'), icon: Icon(Icons.group)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM dd, yyyy').format(_toDate)),
                      onPressed: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
            ] else if (_mode == 'employee') ...[
              TextField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'Employee ID',
                  hintText: 'Enter the employee UUID',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              TextField(
                controller: _departmentIdController,
                decoration: const InputDecoration(
                  labelText: 'Department ID',
                  hintText: 'Enter the department UUID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_result != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Reprocessing Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildResultRow('Raw Logs Reset', '${_result!['reset'] ?? 0}'),
                      _buildResultRow('Records Processed', '${_result!['processed'] ?? 0}'),
                      _buildResultRow('Created', '${_result!['created'] ?? 0}'),
                      _buildResultRow('Updated', '${_result!['updated'] ?? 0}'),
                      _buildResultRow('Errors', '${_result!['errors'] ?? 0}',
                          _result!['errors'] != null && _result!['errors'] > 0 ? Colors.red : null),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: Text(_isProcessing ? 'Processing...' : 'Start Reprocessing'),
                onPressed: _isProcessing ? null : _startReprocessing,
              ),
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
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
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
