import 'dart:io' show File, Directory;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/report_service.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/page_wrapper.dart';

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

  final List<_ReportDef> _reports = const [
    // ── Attendance Reports ──
    _ReportDef('daily', 'Daily Attendance', 'Present/absent/late counts for a specific date.', Icons.today, ApexColors.primary600, 'Attendance'),
    _ReportDef('monthly', 'Monthly Attendance', 'Full calendar month attendance grid for employees.', Icons.calendar_month, ApexColors.primary600, 'Attendance'),
    _ReportDef('register', 'Attendance Register', 'Standard statutory check-in/out registers list.', Icons.table_chart, ApexColors.primary600, 'Attendance'),
    _ReportDef('punch', 'Punch Report', 'Detailed biometric raw punch timestamps logs.', Icons.fingerprint, ApexColors.primary600, 'Attendance'),
    _ReportDef('late', 'Late Coming', 'List of staff arriving past grace period parameters.', Icons.watch_later_outlined, ApexColors.warning, 'Attendance'),
    _ReportDef('early_going', 'Early Going', 'List of staff departing before scheduled shift end.', Icons.exit_to_app_outlined, ApexColors.warning, 'Attendance'),
    _ReportDef('absent', 'Absent Report', 'Employees absent on a specific date.', Icons.person_off_outlined, ApexColors.error, 'Attendance'),
    _ReportDef('overtime', 'Overtime Report', 'Verified overtime hours and calculations.', Icons.more_time, ApexColors.success, 'Attendance'),

    // ── Leave Reports ──
    _ReportDef('leave_summary', 'Leave Summary', 'Consolidated leave balances and totals.', Icons.summarize_outlined, ApexColors.primary600, 'Leave'),
    _ReportDef('leave_register', 'Leave Register', 'Roster of leave request logs.', Icons.app_registration_outlined, ApexColors.primary600, 'Leave'),
    _ReportDef('leave_balance', 'Leave Balance', 'Current leave quotas and remaining counts.', Icons.account_balance_outlined, ApexColors.primary600, 'Leave'),
    _ReportDef('leave_history', 'Leave History', 'Audit trail of previously requested leaves.', Icons.history, ApexColors.primary600, 'Leave'),

    // ── Duty Reports ──
    _ReportDef('duty_out', 'Out Duty', 'Logs of client site or out-office duties.', Icons.directions_walk_outlined, ApexColors.primary600, 'Duty'),
    _ReportDef('duty_comp', 'Comp Off', 'Compensatory off balances and credit logs.', Icons.swap_horiz_outlined, ApexColors.primary600, 'Duty'),
    _ReportDef('duty_missed', 'Missed Punch', 'Logs of singular check-in or checkout overrides.', Icons.fingerprint, ApexColors.error, 'Duty'),

    // ── Payroll Reports ──
    _ReportDef('pay_sal', 'Salary Register', 'Consolidated monthly salary payouts register.', Icons.receipt_long_outlined, ApexColors.success, 'Payroll'),
    _ReportDef('pay_bank', 'Bank Transfer', 'Salary bank payment advice structures.', Icons.account_balance, ApexColors.success, 'Payroll'),
    _ReportDef('pay_slip', 'Payslip Report', 'PDF slips download index.', Icons.description_outlined, ApexColors.success, 'Payroll'),
    _ReportDef('pay_pf', 'PF Report', 'Provident Fund statutory deduction challan.', Icons.savings_outlined, ApexColors.success, 'Payroll'),
    _ReportDef('pay_esi', 'ESI Report', 'Employee State Insurance statutory ledger.', Icons.health_and_safety_outlined, ApexColors.success, 'Payroll'),
    _ReportDef('pay_tds', 'TDS Report', 'Monthly tax deduction brackets registry.', Icons.percent_outlined, ApexColors.success, 'Payroll'),

    // ── Device Reports ──
    _ReportDef('dev_logs', 'Device Logs', 'Audit trail of terminal network connections.', Icons.list_alt_outlined, ApexColors.primary600, 'Device'),
    _ReportDef('dev_health', 'Device Health', 'Terminal online uptime status logs.', Icons.monitor_heart_outlined, ApexColors.primary600, 'Device'),
    _ReportDef('dev_sync', 'Sync Status', 'eSSL database synchronization success history.', Icons.sync, ApexColors.primary600, 'Device'),

    // ── Analytics ──
    _ReportDef('ana_emp', 'Employee Analytics', 'Staff demographic changes and lifecycle trends.', Icons.people_outlined, ApexColors.primary600, 'Analytics'),
    _ReportDef('ana_att', 'Attendance Trends', 'Historical check-in timeline trends charts.', Icons.trending_up, ApexColors.primary600, 'Analytics'),
    _ReportDef('ana_dept', 'Department Summary', 'Attendance percentages per department unit.', Icons.business, ApexColors.primary600, 'Analytics'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteToSelection();
  }

  void _syncRouteToSelection() {
    final route = GoRouterState.of(context).matchedLocation;
    // Map specific sub-routes to pre-selected report types
    for (final r in _reports) {
      if (route.endsWith(r.id) || route.contains('/${r.id}')) {
        setState(() {
          _selectedType = r.id;
        });
        break;
      }
    }
  }

  void _download() async {
    setState(() => _isDownloading = true);
    try {
      final service = ref.read(reportServiceProvider);
      final dateStr = _selectedDate.toIso8601String().substring(0, 10);
      final fromDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
      late final Uint8List bytes;

      // Map selection to service call
      if (_selectedType == 'daily') {
        bytes = await service.downloadDailyReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'absent') {
        bytes = await service.downloadAbsentReport(date: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'late') {
        bytes = await service.downloadLateReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'early_going') {
        bytes = await service.downloadEarlyGoingReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'missed_punch' || _selectedType == 'duty_missed') {
        bytes = await service.downloadMissedPunchReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else if (_selectedType == 'monthly') {
        bytes = await service.downloadMonthlyReport(month: _selectedDate.month, year: _selectedDate.year, format: _selectedFormat);
      } else if (_selectedType == 'ana_dept') {
        bytes = await service.downloadDeptSummaryReport(fromDate: fromDate, toDate: dateStr, format: _selectedFormat);
      } else {
        // Fallback default download
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
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
      } catch (e) {
        // ignore
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
      body: ApexPageWrapper(
        title: 'Report Center',
        description: 'Generate statutory Muster Roll, leaves registry, daily check-in logs, and payslips.',
        body: isMobile ? _buildMobile() : _buildDesktop(),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 260, child: _buildCategories()),
        VerticalDivider(width: 1, color: ApexColors.neutral200),
        Expanded(child: _buildConfig()),
        VerticalDivider(width: 1, color: ApexColors.neutral200),
        SizedBox(width: 280, child: _buildHistory()),
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
    final categories = ['Attendance', 'Leave', 'Duty', 'Payroll', 'Device', 'Analytics'];

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final cat in categories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('${cat.toUpperCase()} REPORTS', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
            ..._reports.where((r) => r.category == cat).map((r) {
              final isSelected = _selectedType == r.id;
              return ListTile(
                selected: isSelected,
                leading: Icon(r.icon, size: 16, color: isSelected ? r.color : ApexColors.neutral500),
                title: Text(
                  r.name,
                  style: ApexTypography.captionMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? r.color : null,
                  ),
                ),
                onTap: () => setState(() => _selectedType = r.id),
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            }),
            const Divider(height: 12),
          ],
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
          Text('REPORT PARAMETERS', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ApexDatePicker(
            label: 'Selected Date',
            value: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onChanged: (picked) { if (picked != null) setState(() => _selectedDate = picked); },
          ),
          const SizedBox(height: 24),
          Text('EXPORT FORMAT', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
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
            label: _isDownloading ? 'Downloading...' : 'Generate & Download',
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('RECENT EXPORTS', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No downloads yet', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _history.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final item = _history[idx];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.description, size: 18, color: ApexColors.neutral500),
                    title: Text(item.filename, style: ApexTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${DateFormat('MMM dd, HH:mm').format(item.timestamp)} • ${_formatSize(item.size)}',
                      style: ApexTypography.captionSmall,
                    ),
                  );
                },
              ),
            ),
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
  final String category;

  const _ReportDef(this.id, this.name, this.description, this.icon, this.color, this.category);
}

class _DownloadItem {
  final String filename;
  final DateTime timestamp;
  final int size;

  const _DownloadItem({required this.filename, required this.timestamp, required this.size});
}
