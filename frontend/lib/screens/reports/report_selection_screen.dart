import 'dart:io' show File, Directory;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/report_service.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

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
    _ReportDef('daily', 'Daily Attendance', 'Present/absent/late for a specific date', Icons.calendar_today, ApexColors.primary600),
    _ReportDef('absent', 'Absent Report', 'Employees absent on a specific date', Icons.person_off, ApexColors.error),
    _ReportDef('late', 'Late Arrivals', 'Employees who arrived late', Icons.access_time, ApexColors.warning),
    _ReportDef('early_going', 'Early Going', 'Employees who left early', Icons.exit_to_app, ApexColors.warning),
    _ReportDef('missed_punch', 'Missed Punch', 'Incomplete punch pairs', Icons.fingerprint, ApexColors.error),
    _ReportDef('monthly', 'Monthly Report', 'Full month attendance grid', Icons.date_range, ApexColors.primary600),
    _ReportDef('dept_summary', 'Department Summary', 'Attendance by department', Icons.business, ApexColors.primary600),
    _ReportDef('ot_summary', 'OT Summary', 'Overtime hours by employee', Icons.access_time_filled, ApexColors.success),
    _ReportDef('muster_roll', 'Muster Roll', 'Statutory attendance register', Icons.menu_book, ApexColors.primary600),
    _ReportDef('devices', 'Device Status', 'Status of all biometric devices', Icons.biotech, ApexColors.primary600),
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
          SnackBar(content: Text('Downloaded: $filename'), backgroundColor: ApexColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: ApexColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _saveFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute('download', filename)..click();
      html.Url.revokeObjectUrl(url);
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $filePath'), backgroundColor: ApexColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: ApexColors.error),
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
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Report Center'),
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        SizedBox(width: 220, child: _buildCategories()),
        VerticalDivider(width: 1, color: ApexColors.neutral200),
        Expanded(child: _buildConfig()),
        VerticalDivider(width: 1, color: ApexColors.neutral200),
        SizedBox(width: 260, child: _buildHistory()),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCategories(),
          Divider(height: 1, color: ApexColors.neutral200),
          _buildConfig(),
          Divider(height: 1, color: ApexColors.neutral200),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      color: ApexColors.neutral0,
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
              leading: Icon(r.icon, size: 20, color: isSelected ? r.color : ApexColors.neutral500),
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
                    Text(report.name, style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
                    Text(report.description, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('DATE', style: ApexTypography.sectionHeader),
          const SizedBox(height: 8),
          ApexDatePicker(
            label: 'Report Date',
            value: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onChanged: (picked) { if (picked != null) setState(() => _selectedDate = picked); },
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
                  selectedColor: ApexColors.primary100,
                  checkmarkColor: ApexColors.primary600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ApexButton(
            label: _isDownloading ? 'Downloading...' : 'Download Report',
            icon: _isDownloading ? null : Icons.download,
            loading: _isDownloading,
            expanded: true,
            onPressed: _isDownloading ? null : _download,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      color: ApexColors.neutral0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('RECENT EXPORTS', style: ApexTypography.sectionHeader),
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No downloads yet', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
            )
          else
            ..._history.take(10).map((item) {
              return ListTile(
                dense: true,
                leading: Icon(Icons.description, size: 18, color: ApexColors.neutral500),
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
