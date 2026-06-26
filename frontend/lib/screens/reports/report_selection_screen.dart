import 'dart:io' show File, Directory;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../services/report_service.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class ReportSelectionScreen extends ConsumerStatefulWidget {
  const ReportSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportSelectionScreen> createState() => _ReportSelectionScreenState();
}

class _ReportSelectionScreenState extends ConsumerState<ReportSelectionScreen> {
  String _selectedType = 'daily';
  String _selectedFormat = 'pdf';
  DateTime _selectedDate = DateTime.now();
  bool _isDownloading = false;
  final List<_DownloadItem> _history = [];

  final _reports = [
    _ReportDef('daily', 'Daily Attendance', 'Present/absent/late for a specific date', Icons.calendar_today, _primary),
    _ReportDef('absent', 'Absent Report', 'Employees absent on a specific date', Icons.person_off, _danger),
    _ReportDef('late', 'Late Arrivals', 'Employees who arrived late', Icons.access_time, const Color(0xFFF59E0B)),
    _ReportDef('early_going', 'Early Going', 'Employees who left early', Icons.exit_to_app, const Color(0xFFF59E0B)),
    _ReportDef('missed_punch', 'Missed Punch', 'Incomplete punch pairs', Icons.fingerprint, _danger),
    _ReportDef('monthly', 'Monthly Report', 'Full month attendance grid', Icons.date_range, _primary),
    _ReportDef('dept_summary', 'Department Summary', 'Attendance by department', Icons.business, _primary),
    _ReportDef('ot_summary', 'OT Summary', 'Overtime hours by employee', Icons.access_time_filled, const Color(0xFF16A34A)),
    _ReportDef('muster_roll', 'Muster Roll', 'Statutory attendance register', Icons.menu_book, _primary),
    _ReportDef('devices', 'Device Status', 'Status of all biometric devices', Icons.biotech, _primary),
  ];

  void _download() async {
    setState(() => _isDownloading = true);
    try {
      final service = ref.read(reportServiceProvider);
      final dateStr = _selectedDate.toIso8601String().substring(0, 10);
      final fromDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
      late final Uint8List bytes;

      if (_selectedType == 'daily') {
        bytes = await service.downloadDailyReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'absent') {
        bytes = await service.downloadAbsentReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'late') {
        bytes = await service.downloadLateReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'early_going') {
        bytes = await service.downloadEarlyGoingReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'missed_punch') {
        bytes = await service.downloadMissedPunchReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'monthly') {
        bytes = await service.downloadMonthlyReport(month: _selectedDate.month, year: _selectedDate.year, format: _selectedFormat);
      } else if (_selectedType == 'dept_summary') {
        bytes = await service.downloadDeptSummaryReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'ot_summary') {
        bytes = await service.downloadOtSummaryReport(month: _selectedDate.month, year: _selectedDate.year, format: _selectedFormat);
      } else if (_selectedType == 'muster_roll') {
        bytes = await service.downloadMusterRollReport(month: _selectedDate.month, year: _selectedDate.year, format: _selectedFormat);
      } else if (_selectedType == 'devices') {
        bytes = await service.downloadDeviceReport(format: _selectedFormat);
      } else {
        bytes = await service.downloadDailyReport(date: dateStr, format: _selectedFormat);
      }

      final filename = _getFilename();
      _saveFile(bytes, filename);

      setState(() {
        _history.insert(0, _DownloadItem(filename: filename, timestamp: DateTime.now(), size: bytes.length));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: $filename'), backgroundColor: _success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: _danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _saveFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // Web download not supported on desktop
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $filePath'), backgroundColor: _success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: _danger),
        );
      }
    }
  }

  String _getFilename() {
    final d = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final ext = _selectedFormat == 'pdf' ? 'pdf' : _selectedFormat == 'excel' ? 'xlsx' : 'csv';
    return '${_selectedType}_report_$d.$ext';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'Report Center'),
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        // Left: Categories
        SizedBox(width: 220, child: _buildCategories()),
        const VerticalDivider(width: 1, color: _border),
        // Center: Config
        Expanded(child: _buildConfig()),
        const VerticalDivider(width: 1, color: _border),
        // Right: History
        SizedBox(width: 260, child: _buildHistory()),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCategories(),
          const Divider(height: 1, color: _border),
          _buildConfig(),
          const Divider(height: 1, color: _border),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('REPORT TYPES', style: ApexTypography.sectionHeader),
          ),
          ..._reports.map((r) {
            final isSelected = _selectedType == r.id;
            return ListTile(
              selected: isSelected,
              leading: Icon(r.icon, size: 20, color: isSelected ? r.color : _muted),
              title: Text(r.name, style: ApexTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? r.color : null,
              )),
              subtitle: Text(r.description, style: ApexTypography.captionSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => setState(() => _selectedType = r.id),
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfig() {
    final report = _reports.firstWhere((r) => r.id == _selectedType, orElse: () => _reports.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(report.icon, color: report.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.name, style: ApexTypography.headingMedium.copyWith(color: _text)),
                    Text(report.description, style: ApexTypography.bodySmall.copyWith(color: _muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('DATE', style: ApexTypography.sectionHeader),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: _muted),
                  const SizedBox(width: 10),
                  Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: ApexTypography.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('FORMAT', style: ApexTypography.sectionHeader),
          const SizedBox(height: 8),
          Row(
            children: ['pdf', 'excel', 'csv'].map((f) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.toUpperCase()),
                  selected: _selectedFormat == f,
                  onSelected: (v) => setState(() => _selectedFormat = f),
                  selectedColor: _primary.withOpacity(0.1),
                  checkmarkColor: _primary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _download,
              icon: _isDownloading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, size: 18),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('RECENT EXPORTS', style: ApexTypography.sectionHeader),
          ),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No downloads yet', style: TextStyle(color: _muted)),
            )
          else
            ..._history.take(10).map((item) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.description, size: 18, color: _muted),
                title: Text(item.filename, style: ApexTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${DateFormat('MMM dd, HH:mm').format(item.timestamp)} • ${_formatSize(item.size)}',
                  style: ApexTypography.captionSmall,
                ),
                trailing: IconButton(icon: const Icon(Icons.download, size: 16), onPressed: () {}),
              );
            }),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ReportDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _ReportDef(this.id, this.name, this.description, this.icon, this.color);
}

class _DownloadItem {
  final String filename;
  final DateTime timestamp;
  final int size;

  const _DownloadItem({required this.filename, required this.timestamp, required this.size});
}
