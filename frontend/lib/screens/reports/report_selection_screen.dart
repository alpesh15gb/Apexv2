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
import '../../design_system/components/apex_button.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
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
          status: 'completed',
        ));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $filename'),
            backgroundColor: ApexColors.success,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // File already downloaded
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}'), backgroundColor: ApexColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.contentPadding(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Center')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Templates
            Text('Report Templates', style: ApexTypography.headingSmall),
            const SizedBox(height: 16),
            _buildReportTemplates(isMobile),
            const SizedBox(height: 24),

            // Configuration
            if (isMobile) ...[
              _buildConfigurationCard(),
              const SizedBox(height: 16),
              _buildDownloadButton(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildConfigurationCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDownloadButton()),
                ],
              ),
            const SizedBox(height: 24),

            // Download History
            Text('Download History', style: ApexTypography.headingSmall),
            const SizedBox(height: 16),
            _buildDownloadHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTemplates(bool isMobile) {
    final templates = [
      _ReportTemplate(
        id: 'daily',
        title: 'Daily Attendance',
        description: 'Daily attendance summary for all employees',
        icon: Icons.calendar_today,
        color: ApexColors.primary,
        category: 'Attendance',
      ),
      _ReportTemplate(
        id: 'absent',
        title: 'Absent Report',
        description: 'Employees who were absent on a specific date',
        icon: Icons.person_off,
        color: ApexColors.error,
        category: 'Attendance',
      ),
      _ReportTemplate(
        id: 'late',
        title: 'Late Arrivals',
        description: 'Employees who arrived late',
        icon: Icons.access_time,
        color: ApexColors.warning,
        category: 'Attendance',
      ),
      _ReportTemplate(
        id: 'devices',
        title: 'Device Status',
        description: 'Status report of all biometric devices',
        icon: Icons.biotech,
        color: ApexColors.info,
        category: 'Devices',
      ),
    ];

    // Group by category
    final categories = <String, List<_ReportTemplate>>{};
    for (final template in templates) {
      categories.putIfAbsent(template.category, () => []).add(template);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral500)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: isMobile ? 1 : (entry.value.length > 4 ? 4 : entry.value.length),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 3 : 1.5,
              children: entry.value.map((template) {
                final isSelected = _selectedReportType == template.id;
                return InkWell(
                  onTap: () => setState(() => _selectedReportType = template.id),
                  borderRadius: ApexRadius.lgAll,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? template.color : ApexColors.neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: ApexRadius.lgAll,
                      color: isSelected ? template.color.withOpacity(0.05) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: template.color.withOpacity(0.1),
                            borderRadius: ApexRadius.mdAll,
                          ),
                          child: Icon(template.icon, color: template.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                template.title,
                                style: ApexTypography.titleMedium.copyWith(
                                  color: isSelected ? template.color : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: ApexTypography.captionMedium.copyWith(
                                  color: ApexColors.neutral500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: template.color, size: 24),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConfigurationCard() {
    return ApexCard(
      header: Text('Configuration', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          // Date picker
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
            borderRadius: ApexRadius.mdAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: ApexColors.neutral200),
                borderRadius: ApexRadius.mdAll,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: ApexColors.neutral500),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Date', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        style: ApexTypography.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Format selection
          Row(
            children: [
              Text('Format:', style: ApexTypography.titleSmall),
              const SizedBox(width: 16),
              ...['pdf', 'excel', 'csv'].map((format) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(format.toUpperCase()),
                    selected: _selectedFormat == format,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFormat = format);
                    },
                    selectedColor: ApexColors.primary100,
                    checkmarkColor: ApexColors.primary,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ApexButton.primary(
            label: _isDownloading ? 'Downloading...' : 'Download Report',
            icon: _isDownloading ? null : Icons.download,
            loading: _isDownloading,
            onPressed: _isDownloading ? null : _download,
            fullWidth: true,
            size: ApexButtonSize.lg,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Report will be downloaded as ${_selectedFormat.toUpperCase()}',
          style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
        ),
      ],
    );
  }

  Widget _buildDownloadHistory() {
    if (_downloadHistory.isEmpty) {
      return const ApexEmptyState(
        icon: Icons.download_done_outlined,
        title: 'No Downloads Yet',
        description: 'Your downloaded reports will appear here.',
      );
    }

    return ApexCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _downloadHistory.length,
        separatorBuilder: (context, idx) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final item = _downloadHistory[idx];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ApexColors.success.withOpacity(0.1),
                borderRadius: ApexRadius.mdAll,
              ),
              child: const Icon(Icons.check_circle, color: ApexColors.success, size: 20),
            ),
            title: Text(item.filename, style: ApexTypography.bodyMedium),
            subtitle: Text(
              '${DateFormat('MMM dd, HH:mm').format(item.timestamp)} • ${_formatSize(item.size)}',
              style: ApexTypography.captionMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, size: 18),
              onPressed: () {
                // Re-download
              },
            ),
          );
        },
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ReportTemplate {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;

  const _ReportTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
}

class _DownloadItem {
  final String filename;
  final DateTime timestamp;
  final int size;
  final String status;

  const _DownloadItem({
    required this.filename,
    required this.timestamp,
    required this.size,
    required this.status,
  });
}
