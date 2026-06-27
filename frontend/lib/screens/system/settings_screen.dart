import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});
  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  Map<String, dynamic>? _settings;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/settings/');
      setState(() { _settings = res.data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final company = _settings?['company'] ?? {};

    return Scaffold(
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard('Company Information', [
              _infoRow('Company Name', company['name'] ?? '—'),
              _infoRow('Email', company['email'] ?? '—'),
              _infoRow('Phone', company['mobile'] ?? '—'),
              _infoRow('Contact Person', company['contact_person'] ?? '—'),
              _infoRow('Currency', company['currency'] ?? 'INR'),
              _infoRow('Timezone', company['timezone'] ?? '—'),
              _infoRow('Financial Year Start', company['financial_year_start'] ?? '—'),
              _infoRow('GST Number', company['gst_number'] ?? '—'),
              _infoRow('PAN Number', company['pan_number'] ?? '—'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Quick Links', [
              _navTile(Icons.people, 'Roles & Permissions', () {}),
              _navTile(Icons.category, 'Departments', () => context.push('/employees')),
              _navTile(Icons.location_on, 'Branches', () => context.push('/employees')),
              _navTile(Icons.schedule, 'Shift Management', () => context.push('/shifts')),
              _navTile(Icons.event_busy, 'Leave Types', () => context.push('/leaves/types')),
              _navTile(Icons.holiday_village, 'Holidays', () => context.push('/holidays')),
              _navTile(Icons.account_balance, 'Payroll Settings', () => context.push('/payroll')),
              _navTile(Icons.fingerprint, 'Attendance Settings', () => context.push('/attendance')),
              _navTile(Icons.notifications, 'Notifications', () => context.push('/notifications')),
              _navTile(Icons.webhook, 'Integrations', () {}),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Subscription', [
              _infoRow('Status', (_settings?['subscription']?['status'] ?? '—').toString().toUpperCase()),
              _infoRow('Plan', _settings?['subscription']?['plan'] ?? '—'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 160, child: Text(label, style: const TextStyle(fontSize: 13, color: _muted))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: _text, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _navTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: _primary),
      title: Text(title, style: const TextStyle(fontSize: 14, color: _text)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: _muted),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context) {
    final company = _settings?['company'] ?? {};
    final nameCtrl = TextEditingController(text: company['name'] ?? '');
    final emailCtrl = TextEditingController(text: company['email'] ?? '');
    final phoneCtrl = TextEditingController(text: company['mobile'] ?? '');
    final contactCtrl = TextEditingController(text: company['contact_person'] ?? '');
    final gstCtrl = TextEditingController(text: company['gst_number'] ?? '');
    final panCtrl = TextEditingController(text: company['pan_number'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Company Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: panCtrl, decoration: const InputDecoration(labelText: 'PAN', border: OutlineInputBorder()))),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.put('/settings/company', data: {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'mobile': phoneCtrl.text.trim(),
                  'contact_person': contactCtrl.text.trim(),
                  'gst_number': gstCtrl.text.trim(),
                  'pan_number': panCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated'), backgroundColor: _success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
