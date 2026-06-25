import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';

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
  final _timeoutController = TextEditingController(text: '30');

  String _timezone = 'Asia/Kolkata';
  bool _autoSync = true;
  int _attendanceInterval = 5;
  int _deviceInterval = 60;
  int _employeeHour = 2;
  String _employeeConflictPolicy = 'disable';
  String _deviceConflictPolicy = 'disable';
  bool _isLoading = false;
  bool _isEditing = false;
  EsslTestResult? _testResult;
  bool _isTesting = false;

  final List<String> _timezones = [
    'Asia/Kolkata',
    'Asia/Dubai',
    'Asia/Singapore',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Berlin',
    'UTC',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serverId != null) {
      _isEditing = true;
      _loadServer();
    }
  }

  Future<void> _loadServer() async {
    final service = ref.read(esslServiceProvider);
    final server = await service.getServer(widget.serverId!);
    setState(() {
      _nameController.text = server.name;
      _urlController.text = server.serverUrl;
      _usernameController.text = server.username;
      _timeoutController.text = server.timeoutSeconds.toString();
      _timezone = server.timezone;
      _autoSync = server.autoSyncEnabled;
      _attendanceInterval = server.attendanceSyncIntervalMinutes;
      _deviceInterval = server.deviceSyncIntervalMinutes;
      _employeeHour = server.employeeSyncHour;
      _employeeConflictPolicy = server.employeeConflictPolicy;
      _deviceConflictPolicy = server.deviceConflictPolicy;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit eSSL Server' : 'Add eSSL Server'),
        actions: [
          if (_isEditing)
            TextButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test'),
              onPressed: _isTesting ? null : _testConnection,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_testResult != null)
              Card(
                color: _testResult!.success ? Colors.green.shade50 : Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(
                    _testResult!.success ? Icons.check_circle : Icons.error,
                    color: _testResult!.success ? Colors.green : Colors.red,
                  ),
                  title: Text(_testResult!.success ? 'Connection Successful' : 'Connection Failed'),
                  subtitle: _testResult!.success
                      ? Text('Response time: ${_testResult!.responseTimeMs}ms')
                      : Text(_testResult!.error ?? 'Unknown error'),
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'e.g., Main Office Biometric',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://client-ip:8080/WebService.asmx',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isEditing ? 'New Password (leave blank to keep)' : 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (v) => (!_isEditing && (v == null || v.isEmpty)) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeoutController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Connection Timeout (seconds)',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _timezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                prefixIcon: Icon(Icons.language),
              ),
              items: _timezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
              onChanged: (v) => setState(() => _timezone = v!),
            ),
            const SizedBox(height: 24),
            const Text('Sync Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto Sync Enabled'),
              subtitle: const Text('Automatically sync data on schedule'),
              value: _autoSync,
              onChanged: (v) => setState(() => _autoSync = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _attendanceInterval,
                    decoration: const InputDecoration(labelText: 'Attendance Sync'),
                    items: [1, 2, 5, 10, 15, 30].map((v) => DropdownMenuItem(value: v, child: Text('Every $v min'))).toList(),
                    onChanged: (v) => setState(() => _attendanceInterval = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _deviceInterval,
                    decoration: const InputDecoration(labelText: 'Device Sync'),
                    items: [15, 30, 60, 120].map((v) => DropdownMenuItem(value: v, child: Text('Every $v min'))).toList(),
                    onChanged: (v) => setState(() => _deviceInterval = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _employeeHour,
              decoration: const InputDecoration(labelText: 'Employee Sync (Daily)'),
              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
              onChanged: (v) => setState(() => _employeeHour = v!),
            ),
            const SizedBox(height: 24),
            const Text('Conflict Resolution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _employeeConflictPolicy,
              decoration: const InputDecoration(labelText: 'Employee deleted in eSSL'),
              items: const [
                DropdownMenuItem(value: 'ignore', child: Text('Ignore')),
                DropdownMenuItem(value: 'disable', child: Text('Disable locally')),
                DropdownMenuItem(value: 'soft_delete', child: Text('Soft delete')),
                DropdownMenuItem(value: 'hard_delete', child: Text('Hard delete')),
              ],
              onChanged: (v) => setState(() => _employeeConflictPolicy = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _deviceConflictPolicy,
              decoration: const InputDecoration(labelText: 'Device deleted in eSSL'),
              items: const [
                DropdownMenuItem(value: 'ignore', child: Text('Ignore')),
                DropdownMenuItem(value: 'disable', child: Text('Disable locally')),
                DropdownMenuItem(value: 'soft_delete', child: Text('Soft delete')),
                DropdownMenuItem(value: 'hard_delete', child: Text('Hard delete')),
              ],
              onChanged: (v) => setState(() => _deviceConflictPolicy = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Update Server' : 'Add Server'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'server_url': _urlController.text.trim(),
        'username': _usernameController.text.trim(),
        'timeout_seconds': int.parse(_timeoutController.text),
        'timezone': _timezone,
        'auto_sync_enabled': _autoSync,
        'attendance_sync_interval_minutes': _attendanceInterval,
        'device_sync_interval_minutes': _deviceInterval,
        'employee_sync_hour': _employeeHour,
        'employee_conflict_policy': _employeeConflictPolicy,
        'device_conflict_policy': _deviceConflictPolicy,
      };
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      final service = ref.read(esslServiceProvider);
      if (_isEditing) {
        await service.updateServer(widget.serverId!, data);
      } else {
        data['password'] = _passwordController.text;
        await service.createServer(data);
      }

      ref.read(esslServerListProvider.notifier).fetchServers(isRefresh: true);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final service = ref.read(esslServiceProvider);
      final result = await service.testConnection(widget.serverId!);
      setState(() => _testResult = result);
    } catch (e) {
      setState(() => _testResult = EsslTestResult(success: false, error: e.toString()));
    } finally {
      setState(() => _isTesting = false);
    }
  }
}
