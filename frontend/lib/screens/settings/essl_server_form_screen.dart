import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
            SnackBar(content: Text(widget.serverId != null ? 'Server updated' : 'Server created'), backgroundColor: _success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: _danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(widget.serverId != null ? 'Edit Server' : 'Add Server'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'CONNECTION',
                children: [
                  _field('Server Name', _nameController, required: true),
                  _field('Server URL', _urlController, required: true, hint: 'http://192.168.1.100:8080/Webservice.asmx'),
                  _field('Username', _usernameController, required: true),
                  _field('Password', _passwordController, required: true, obscure: true),
                  if (widget.serverId != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/settings/essl/${widget.serverId}/locations'),
                        icon: const Icon(Icons.location_on_outlined, size: 16),
                        label: const Text('Manage Locations'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'SYNC SETTINGS',
                children: [
                  SwitchListTile(
                    title: Text('Auto Sync', style: ApexTypography.body),
                    subtitle: Text('Automatically sync at regular intervals', style: ApexTypography.caption),
                    value: _autoSync,
                    onChanged: (v) => setState(() => _autoSync = v),
                    activeColor: _primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  _numberField('Attendance Sync (minutes)', _attendanceInterval, (v) => setState(() => _attendanceInterval = v)),
                  _numberField('Device Sync (minutes)', _deviceInterval, (v) => setState(() => _deviceInterval = v)),
                  _numberField('Employee Sync Hour', _employeeHour, (v) => setState(() => _employeeHour = v)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(widget.serverId != null ? 'Update Server' : 'Create Server', style: ApexTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool required = false, String? hint, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ApexTypography.titleSmall.copyWith(color: _text)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          ),
        ],
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ApexTypography.sectionHeader),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
