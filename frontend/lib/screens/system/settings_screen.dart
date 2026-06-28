import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_section.dart';
import '../../widgets/apex_text_field.dart';

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
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApexSection(
              title: 'Company Information',
              trailing: ApexButton(
                label: 'Edit',
                icon: Icons.edit,
                onPressed: () => _showEditDialog(context),
                type: ApexButtonType.primary,
              ),
              children: [
                _infoRow('Company Name', company['name'] ?? '—'),
                _infoRow('Email', company['email'] ?? '—'),
                _infoRow('Phone', company['mobile'] ?? '—'),
                _infoRow('Contact Person', company['contact_person'] ?? '—'),
                _infoRow('Currency', company['currency'] ?? 'INR'),
                _infoRow('Timezone', company['timezone'] ?? '—'),
                _infoRow('Financial Year Start', company['financial_year_start'] ?? '—'),
                _infoRow('GST Number', company['gst_number'] ?? '—'),
                _infoRow('PAN Number', company['pan_number'] ?? '—'),
              ],
            ),
            const SizedBox(height: 16),
            ApexSection(
              title: 'Quick Links',
              children: [
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
              ],
            ),
            const SizedBox(height: 16),
            ApexSection(
              title: 'Subscription',
              children: [
                _infoRow('Status', (_settings?['subscription']?['status'] ?? '—').toString().toUpperCase()),
                _infoRow('Plan', _settings?['subscription']?['plan'] ?? '—'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 160, child: Text(label, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
        Expanded(child: Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _navTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: ApexColors.primary600),
      title: Text(title, style: ApexTypography.body),
      trailing: Icon(Icons.chevron_right, size: 18, color: ApexColors.neutral500),
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
        title: Text('Edit Company Settings', style: ApexTypography.sectionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Company Name', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Email', controller: emailCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Phone', controller: phoneCtrl),
              const SizedBox(height: 12),
              ApexTextField(label: 'Contact Person', controller: contactCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ApexTextField(label: 'GST', controller: gstCtrl)),
                const SizedBox(width: 8),
                Expanded(child: ApexTextField(label: 'PAN', controller: panCtrl)),
              ]),
            ],
          ),
        ),
        actions: [
          ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
          ApexButton(
            label: 'Save',
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings updated'), backgroundColor: ApexColors.success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
              }
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }
}
