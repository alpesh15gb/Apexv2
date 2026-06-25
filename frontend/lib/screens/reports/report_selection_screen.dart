import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_card.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../services/report_service.dart';

class ReportSelectionScreen extends ConsumerStatefulWidget {
  const ReportSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportSelectionScreen> createState() => _ReportSelectionScreenState();
}

class _ReportSelectionScreenState extends ConsumerState<ReportSelectionScreen> {
  String _selectedReportType = 'daily';
  String _selectedFormat = 'pdf';
  DateTime _selectedDate = DateTime.now();
  bool _isDownloading = false;
  final List<_DownloadItem> _downloadHistory = [];

  final _reports = [
    _ReportDef('daily', 'Daily Attendance', 'Present/absent/late for a specific date', Icons.calendar_today, ApexColors.primary),
    _ReportDef('absent', 'Absent Report', 'Employees absent on a specific date', Icons.person_off, ApexColors.error),
    _ReportDef('late', 'Late Arrivals', 'Employees who arrived late', Icons.access_time, ApexColors.warning),
    _ReportDef('devices', 'Device Status', 'Status of all biometric devices', Icons.biotech, ApexColors.info),
  ];

  void _download() async {
    setState(() => _isDownloading = true);
    try {
      final service = ref.read(reportServiceProvider);
      final dateStr = _selectedDate.toIso8601String().substring(0, 10);
      late final Uint8List bytes;

      if (_selectedReportType == 'daily') {
        bytes = await service.downloadDailyReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedReportType == 'absent') {
        bytes = await service.downloadAbsentReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedReportType == 'devices') {
        bytes = await service.downloadDeviceReport(format: _selectedFormat);
      } else {
        bytes = await service.downloadLateReport(
          fromDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10),
          toDate: dateStr,
          format: _selectedFormat,
        );
      }

      final filename = _getFilename();
      _saveFile(bytes, filename);

      setState(() {
        _downloadHistory.insert(0, _DownloadItem(
          filename: filename,
          timestamp: DateTime.now(),
          size: bytes.length,
        ));
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

  void _saveFile(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  String _getFilename() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final ext = _selectedFormat == 'pdf' ? 'pdf' : _selectedFormat == 'excel' ? 'xlsx' : 'csv';
    return '${_selectedReportType}_report_$dateStr.$ext';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Center')),
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        // Left: Categories
        SizedBox(
          width: 240,
          child: _buildCategories(isDark),
        ),
        const VerticalDivider(width: 1),
        // Center: Configuration
        Expanded(
          child: _buildConfiguration(isDark),
        ),
        const VerticalDivider(width: 1),
        // Right: Recent exports
        SizedBox(
          width: 280,
          child: _buildRecentExports(isDark),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCategories(isDark),
          const Divider(height: 1),
          _buildConfiguration(isDark),
          const Divider(height: 1),
          _buildRecentExports(isDark),
        ],
      ),
    );
  }

  Widget _buildCategories(bool isDark) {
    return Container(
      color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('REPORT TYPES', style: ApexTypography.sectionHeader),
          ),
          ..._reports.map((r) {
            final isSelected = _selectedReportType == r.id;
            return ListTile(
              selected: isSelected,
              leading: Icon(r.icon, size: 20, color: isSelected ? r.color : ApexColors.neutral500),
              title: Text(r.name, style: ApexTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? r.color : null,
              )),
              subtitle: Text(r.description, style: ApexTypography.captionSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => setState(() => _selectedReportType = r.id),
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfiguration(bool isDark) {
    final report = _reports.firstWhere((r) => r.id == _selectedReportType, orElse: () => _reports.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: ApexRadius.mdAll,
                ),
                child: Icon(report.icon, color: report.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.name, style: ApexTypography.headingMedium),
                    Text(report.description, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date picker
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
            borderRadius: ApexRadius.smAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: ApexColors.neutral300),
                borderRadius: ApexRadius.smAll,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: ApexColors.neutral500),
                  const SizedBox(width: 10),
                  Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: ApexTypography.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Format
          Text('FORMAT', style: ApexTypography.sectionHeader),
          const SizedBox(height: 8),
          Row(
            children: ['pdf', 'excel', 'csv'].map((f) {
              final isSelected = _selectedFormat == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.toUpperCase()),
                  selected: isSelected,
                  onSelected: (v) => setState(() => _selectedFormat = f),
                  selectedColor: ApexColors.primary100,
                  checkmarkColor: ApexColors.primary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Download button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _download,
              icon: _isDownloading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, size: 18),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExports(bool isDark) {
    return Container(
      color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('RECENT EXPORTS', style: ApexTypography.sectionHeader),
          ),
          if (_downloadHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No downloads yet', style: TextStyle(color: ApexColors.neutral500)),
            )
          else
            ..._downloadHistory.take(10).map((item) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.description, size: 20, color: ApexColors.neutral500),
                title: Text(item.filename, style: ApexTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${DateFormat('MMM dd, HH:mm').format(item.timestamp)} • ${_formatSize(item.size)}',
                  style: ApexTypography.captionSmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download, size: 16),
                  onPressed: () {},
                ),
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
