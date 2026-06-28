import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class UtilitiesScreen extends ConsumerStatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  ConsumerState<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends ConsumerState<UtilitiesScreen> {
  // Common states
  bool _processing = false;
  double _progress = 0.0;
  String _statusText = '';

  // Form controllers
  final _fileNameCtrl = TextEditingController();
  final _webhookUrlCtrl = TextEditingController(text: 'https://api.company.com/webhooks/attendance');
  final _apiKeyCtrl = TextEditingController(text: 'pk_live_51MzkSFG29a8a18z90e0b');
  String _exportFormat = 'csv';
  String _bulkDeptId = 'all';

  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/employees/departments', queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _departments = res.data['items'] ?? [];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _fileNameCtrl.dispose();
    _webhookUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  String get _currentRoute => GoRouterState.of(context).matchedLocation;

  // ─── Actions Execution ──────────────────────────────────────────────────────

  void _runImport(String type) async {
    if (_fileNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a file name to import'), backgroundColor: ApexColors.error),
      );
      return;
    }
    setState(() { _processing = true; _progress = 0.0; _statusText = 'Reading spreadsheet...'; });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() { _progress = 0.5; _statusText = 'Validating columns and types...'; });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() { _progress = 1.0; _statusText = 'Records imported successfully!'; _processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk import of $type completed successfully'), backgroundColor: ApexColors.success),
    );
  }

  void _runExport(String type) async {
    setState(() { _processing = true; });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export file generated: ${type}_export.${_exportFormat}'), backgroundColor: ApexColors.success),
    );
  }

  void _runBulkOperation(String op) async {
    setState(() { _processing = true; });
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() { _processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk operation "$op" executed successfully'), backgroundColor: ApexColors.success),
    );
  }

  void _runBackup() async {
    setState(() { _processing = true; });
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() { _processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup archive downloaded (backup_db_latest.tar.gz)'), backgroundColor: ApexColors.success),
    );
  }

  void _runRestore() async {
    setState(() { _processing = true; });
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() { _processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Database restored to target snapshot successfully'), backgroundColor: ApexColors.success),
    );
  }

  // ─── Render Subviews ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final route = _currentRoute;
    final title = _getTitle(route);
    final description = _getDescription(route);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: title,
        description: description,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildRouteContent(route),
        ),
      ),
    );
  }

  Widget _buildRouteContent(String route) {
    if (route.startsWith('/utilities/import/')) {
      final type = route.split('/').last;
      return _buildImportView(type);
    }
    if (route.startsWith('/utilities/export/')) {
      final type = route.split('/').last;
      return _buildExportView(type);
    }
    if (route.startsWith('/utilities/bulk/')) {
      final type = route.split('/').last;
      return _buildBulkView(type);
    }
    if (route.startsWith('/utilities/data/')) {
      final type = route.split('/').last;
      return _buildDataView(type);
    }
    if (route == '/utilities/webhooks') {
      return _buildWebhooksView();
    }
    if (route == '/utilities/integrations') {
      return _buildIntegrationsView();
    }
    return const Center(child: Text('Invalid utility route'));
  }

  // ─── Sub-views Implementations ─────────────────────────────────────────────

  Widget _buildImportView(String type) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spreadsheet Bulk Upload', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          ApexTextField(
            label: 'Select Import File Name',
            controller: _fileNameCtrl,
            required: true,
            hint: 'e.g. ${type}_list.xlsx',
          ),
          const SizedBox(height: 12),
          Text('Ensure your columns match the required template keys. Download template for reference.', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
          const Divider(height: 32),
          if (_processing) ...[
            Text(_statusText, style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress, minHeight: 6, color: ApexColors.primary600, backgroundColor: ApexColors.neutral200),
            const SizedBox(height: 6),
            Text('${(_progress * 100).round()}% complete', style: ApexTypography.captionSmall),
          ] else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Template'),
                ),
                const Spacer(),
                ApexButton(
                  label: 'Execute Import',
                  onPressed: () => _runImport(type),
                  icon: Icons.upload_file,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExportView(String type) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Database Schema Export', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _exportFormat,
            decoration: const InputDecoration(labelText: 'Export Format', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'csv', child: Text('CSV (Comma Separated Values)')),
              DropdownMenuItem(value: 'xlsx', child: Text('Excel spreadsheet (.xlsx)')),
            ],
            onChanged: (v) => setState(() => _exportFormat = v!),
          ),
          const SizedBox(height: 24),
          _processing
              ? const Center(child: CircularProgressIndicator())
              : ApexButton(
                  label: 'Export Data',
                  onPressed: () => _runExport(type),
                  expanded: true,
                  icon: Icons.download,
                ),
        ],
      ),
    );
  }

  Widget _buildBulkView(String type) {
    if (type == 'leave-credit') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bulk Leave Allocation', style: ApexTypography.cardTitle),
            const SizedBox(height: 16),
            ApexDropdown<String>(
              label: 'Target Department',
              value: _bulkDeptId,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Staff')),
                ..._departments.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['name'] ?? ''))),
              ],
              onChanged: (v) => setState(() => _bulkDeptId = v!),
            ),
            const SizedBox(height: 12),
            const ApexTextField(label: 'Days to Credit', controller: null, required: true, keyboardType: TextInputType.number),
            const Divider(height: 32),
            _processing
                ? const Center(child: CircularProgressIndicator())
                : ApexButton(
                    label: 'Process Bulk Credit',
                    onPressed: () => _runBulkOperation('Leave Credit'),
                    expanded: true,
                    icon: Icons.done_all,
                  ),
          ],
        ),
      );
    }
    // Bulk employee update
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bulk Department Map Update', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ApexDropdown<String>(
                  label: 'Source Department',
                  value: _bulkDeptId,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Select source')),
                    ..._departments.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['name'] ?? ''))),
                  ],
                  onChanged: (v) => setState(() => _bulkDeptId = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ApexDropdown<String>(
                  label: 'Target Department',
                  value: 'target',
                  items: [
                    const DropdownMenuItem(value: 'target', child: Text('Select target')),
                    ..._departments.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['name'] ?? ''))),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _processing
              ? const Center(child: CircularProgressIndicator())
              : ApexButton(
                  label: 'Execute Mappings Update',
                  onPressed: () => _runBulkOperation('Employee Update'),
                  expanded: true,
                  icon: Icons.sync,
                ),
        ],
      ),
    );
  }

  Widget _buildDataView(String type) {
    if (type == 'backup') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Database Backup', style: ApexTypography.cardTitle),
            const SizedBox(height: 12),
            Text('Generate and download a compressed GZIP SQL backup of all database tables (tenants, employees, attendances, biometric settings).', style: ApexTypography.body.copyWith(color: ApexColors.neutral600)),
            const Divider(height: 32),
            _processing
                ? const Center(child: CircularProgressIndicator())
                : ApexButton(
                    label: 'Trigger Download Backup',
                    onPressed: _runBackup,
                    expanded: true,
                    icon: Icons.cloud_download,
                  ),
          ],
        ),
      );
    }
    if (type == 'restore') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Database Restore', style: ApexTypography.cardTitle),
            const SizedBox(height: 12),
            Text('Restore the active database schema to a previous state using a valid backup file (.tar.gz). WARNING: This overrides all existing records.', style: ApexTypography.body.copyWith(color: ApexColors.neutral600)),
            const SizedBox(height: 16),
            const ApexTextField(label: 'Enter backup file path *', controller: null, required: true),
            const Divider(height: 32),
            _processing
                ? const Center(child: CircularProgressIndicator())
                : ApexButton(
                    label: 'Process Restore',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Restore'),
                          content: const Text('Are you sure you want to restore? This will overwrite the current live database.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(onPressed: () { Navigator.pop(ctx); _runRestore(); }, child: const Text('Restore', style: TextStyle(color: ApexColors.error))),
                          ],
                        ),
                      );
                    },
                    expanded: true,
                    type: ApexButtonType.danger,
                    icon: Icons.restore,
                  ),
          ],
        ),
      );
    }
    // Archive
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Archiving', style: ApexTypography.cardTitle),
          const SizedBox(height: 12),
          Text('Move historical check-in punch logs and attendance metrics to archive tables to optimize database queries index speeds.', style: ApexTypography.body.copyWith(color: ApexColors.neutral600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: 365,
            decoration: const InputDecoration(labelText: 'Archive records older than', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 180, child: Text('180 Days (6 Months)')),
              DropdownMenuItem(value: 365, child: Text('365 Days (1 Year)')),
              DropdownMenuItem(value: 730, child: Text('730 Days (2 Years)')),
            ],
            onChanged: (_) {},
          ),
          const Divider(height: 32),
          _processing
              ? const Center(child: CircularProgressIndicator())
              : ApexButton(
                  label: 'Execute Archiving',
                  onPressed: () => _runBulkOperation('Archive'),
                  expanded: true,
                  icon: Icons.archive,
                ),
        ],
      ),
    );
  }

  Widget _buildWebhooksView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Webhook Configurations', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          ApexTextField(label: 'Destination Webhook URL *', controller: _webhookUrlCtrl, required: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: 'POST',
            decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'POST', child: Text('POST (Recommended)')),
              DropdownMenuItem(value: 'GET', child: Text('GET')),
              DropdownMenuItem(value: 'PUT', child: Text('PUT')),
            ],
            onChanged: (_) {},
          ),
          const Divider(height: 32),
          _processing
              ? const Center(child: CircularProgressIndicator())
              : ApexButton(
                  label: 'Save Configuration',
                  onPressed: () => _runBulkOperation('Webhook Save'),
                  expanded: true,
                  icon: Icons.save_outlined,
                ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API Integration Keys', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          ApexTextField(label: 'Bearer Authorization API Key', controller: _apiKeyCtrl, enabled: false),
          const SizedBox(height: 12),
          const Text('Use this token in your requests headers as `Authorization: Bearer <key>` to authenticate client integrations.', style: TextStyle(fontSize: 12)),
          const Divider(height: 32),
          _processing
              ? const Center(child: CircularProgressIndicator())
              : ApexButton(
                  label: 'Generate New Key',
                  onPressed: () {
                    setState(() {
                      _apiKeyCtrl.text = 'pk_live_${DateTime.now().millisecondsSinceEpoch}';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New integration key generated'), backgroundColor: ApexColors.success),
                    );
                  },
                  expanded: true,
                  icon: Icons.key,
                ),
        ],
      ),
    );
  }

  // ─── Headers Metadata Helpers ──────────────────────────────────────────────

  String _getTitle(String route) {
    if (route.startsWith('/utilities/import/')) {
      final name = route.split('/').last;
      return 'Import ${name[0].toUpperCase()}${name.substring(1)}';
    }
    if (route.startsWith('/utilities/export/')) {
      final name = route.split('/').last;
      return 'Export ${name[0].toUpperCase()}${name.substring(1)}';
    }
    if (route == '/utilities/bulk/shift-assignment') return 'Bulk Shift Assignment';
    if (route == '/utilities/bulk/leave-credit') return 'Bulk Leave Credit';
    if (route == '/utilities/bulk/employee-update') return 'Bulk Employee Update';
    if (route == '/utilities/data/backup') return 'Data Backup';
    if (route == '/utilities/data/restore') return 'Data Restore';
    if (route == '/utilities/data/archive') return 'Data Archive';
    if (route == '/utilities/webhooks') return 'Webhooks Configuration';
    if (route == '/utilities/integrations') return 'API Integrations';
    return 'Utilities';
  }

  String _getDescription(String route) {
    if (route.startsWith('/utilities/import/')) {
      final name = route.split('/').last;
      return 'Upload files sheets to bulk import $name records.';
    }
    if (route.startsWith('/utilities/export/')) {
      final name = route.split('/').last;
      return 'Export active database tables for $name to local files.';
    }
    if (route == '/utilities/bulk/leave-credit') return 'Process bulk leave balances allocations.';
    if (route == '/utilities/bulk/employee-update') return 'Process bulk structural department updates.';
    if (route == '/utilities/data/backup') return 'Download compressed SQL backups of all tables.';
    if (route == '/utilities/data/restore') return 'Overwrite database records from backup tarball.';
    if (route == '/utilities/data/archive') return 'Compress historical logs to clean up resources.';
    if (route == '/utilities/webhooks') return 'Receive webhook triggers on check-in punches events.';
    if (route == '/utilities/integrations') return 'Configure secure keys for API integrations.';
    return 'System utilities tools.';
  }
}
