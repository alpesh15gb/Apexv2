import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';

class EsslServerFormScreen extends ConsumerStatefulWidget {
  final String? serverId;
  const EsslServerFormScreen({Key? key, this.serverId}) : super(key: key);

  @override
  ConsumerState<EsslServerFormScreen> createState() => _EsslServerFormScreenState();
}

class _EsslServerFormScreenState extends ConsumerState<EsslServerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _timezone = 'Asia/Kolkata';
  bool _autoSync = true;
  int _attendanceInterval = 5;
  int _deviceInterval = 60;
  int _employeeHour = 2;

  @override
  void initState() {
    super.initState();
    if (widget.serverId != null) {
      _loadServer();
    }
  }

  Future<void> _loadServer() async {
    try {
      final service = ref.read(esslServiceProvider);
      final server = await service.getServer(widget.serverId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = server.name;
        _urlController.text = server.serverUrl;
        _usernameController.text = server.username;
        _timezone = server.timezone;
        _autoSync = server.autoSyncEnabled;
        _attendanceInterval = server.attendanceSyncIntervalMinutes;
        _deviceInterval = server.deviceSyncIntervalMinutes;
        _employeeHour = server.employeeSyncHour;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load server: $e'), backgroundColor: ApexColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'server_url': _urlController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'timezone': _timezone,
        'auto_sync_enabled': _autoSync,
        'attendance_sync_interval_minutes': _attendanceInterval,
        'device_sync_interval_minutes': _deviceInterval,
        'employee_sync_hour': _employeeHour,
      };

      try {
        final service = ref.read(esslServiceProvider);
        if (widget.serverId != null) {
          await service.updateServer(widget.serverId!, data);
        } else {
          await service.createServer(data);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.serverId != null ? 'Server updated' : 'Server created'), backgroundColor: ApexColors.success),
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
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: Text(widget.serverId != null ? 'Edit Server' : 'Add Server'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApexSection(
                title: 'CONNECTION',
                children: [
                  ApexTextField(label: 'Server Name', controller: _nameController, required: true),
                  const SizedBox(height: 14),
                  ApexTextField(label: 'Server URL', controller: _urlController, required: true, hint: 'http://192.168.1.100:8080/Webservice.asmx'),
                  const SizedBox(height: 14),
                  ApexTextField(label: 'Username', controller: _usernameController, required: true),
                  const SizedBox(height: 14),
                  ApexTextField(label: 'Password', controller: _passwordController, required: true, obscure: true),
                  if (widget.serverId != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ApexButton(
                        label: 'Manage Locations',
                        onPressed: () => context.push('/settings/essl/${widget.serverId}/locations'),
                        type: ApexButtonType.outline,
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ApexSection(
                title: 'SYNC SETTINGS',
                children: [
                  SwitchListTile(
                    title: Text('Auto Sync', style: ApexTypography.body),
                    subtitle: Text('Automatically sync at regular intervals', style: ApexTypography.caption),
                    value: _autoSync,
                    onChanged: (v) => setState(() => _autoSync = v),
                    activeColor: ApexColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  _numberField('Attendance Sync (minutes)', _attendanceInterval, (v) => setState(() => _attendanceInterval = v)),
                  _numberField('Device Sync (minutes)', _deviceInterval, (v) => setState(() => _deviceInterval = v)),
                  _numberField('Employee Sync Hour', _employeeHour, (v) => setState(() => _employeeHour = v)),
                ],
              ),
              const SizedBox(height: 24),
              ApexButton(
                label: widget.serverId != null ? 'Update Server' : 'Create Server',
                onPressed: _save,
                type: ApexButtonType.primary,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.body),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: '$value',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ),
        ],
      ),
    );
  }
}
