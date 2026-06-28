import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Common states
  bool _saving = false;

  // Company Settings
  final _compNameCtrl = TextEditingController(text: 'Acme Corporation');
  final _compDomainCtrl = TextEditingController(text: 'acme.com');
  final _compRegCtrl = TextEditingController(text: 'REG-29013A');
  final _compEmailCtrl = TextEditingController(text: 'hr@acme.com');

  // Roles List
  List<Map<String, dynamic>> _roles = [
    {'id': 'R1', 'name': 'Super Admin', 'code': 'S_ADMIN', 'perms_count': 42},
    {'id': 'R2', 'name': 'HR Admin', 'code': 'HR_ADMIN', 'perms_count': 35},
    {'id': 'R3', 'name': 'Reporting Manager', 'code': 'MANAGER', 'perms_count': 18},
    {'id': 'R4', 'name': 'Employee', 'code': 'EMPLOYEE', 'perms_count': 5},
  ];

  // Audit Logs
  List<Map<String, dynamic>> _auditLogs = [
    {
      'time': '2026-06-25 10:14 PM',
      'operator': 'admin@acme.com',
      'action': 'Biometric Mapping Linked',
      'details': 'Linked employee code EMP001 to biometric ID 10045.',
    },
    {
      'time': '2026-06-25 09:30 PM',
      'operator': 'admin@acme.com',
      'action': 'Device Settings Updated',
      'details': 'IP address of terminal eBioServer HO updated to 192.168.12.44.',
    },
  ];

  // Permissions Mapping
  final Map<String, Map<String, bool>> _permissionMatrix = {
    'S_ADMIN': {'View Attendance': true, 'Mark Attendance': true, 'Run Payroll': true, 'Manage Devices': true},
    'HR_ADMIN': {'View Attendance': true, 'Mark Attendance': true, 'Run Payroll': true, 'Manage Devices': false},
    'MANAGER': {'View Attendance': true, 'Mark Attendance': false, 'Run Payroll': false, 'Manage Devices': false},
    'EMPLOYEE': {'View Attendance': false, 'Mark Attendance': false, 'Run Payroll': false, 'Manage Devices': false},
  };

  @override
  void dispose() {
    _compNameCtrl.dispose();
    _compDomainCtrl.dispose();
    _compRegCtrl.dispose();
    _compEmailCtrl.dispose();
    super.dispose();
  }

  String get _currentRoute => GoRouterState.of(context).matchedLocation;

  void _saveCompany() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company settings saved successfully'), backgroundColor: ApexColors.success),
    );
  }

  void _savePermissions() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Role permissions matrix updated'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return Scaffold(
        backgroundColor: ApexColors.neutral50,
        body: Center(child: Text('Not logged in', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      );
    }

    final route = _currentRoute;
    final isHome = route == '/settings';
    final title = _getTitle(route);
    final description = _getDescription(route);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: title,
        description: description,
        actions: isHome
            ? [
                ApexButton(
                  label: 'Log Out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  type: ApexButtonType.danger,
                  icon: Icons.logout,
                ),
              ]
            : [
                if (route == '/settings/company')
                  ApexButton(
                    label: _saving ? 'Saving...' : 'Save Settings',
                    onPressed: _saving ? null : _saveCompany,
                    type: ApexButtonType.primary,
                    icon: _saving ? null : Icons.save,
                  ),
                if (route == '/settings/permissions')
                  ApexButton(
                    label: _saving ? 'Saving...' : 'Save Matrix',
                    onPressed: _saving ? null : _savePermissions,
                    type: ApexButtonType.primary,
                    icon: _saving ? null : Icons.save,
                  ),
              ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildRouteContent(route, user),
        ),
      ),
    );
  }

  Widget _buildRouteContent(String route, dynamic user) {
    switch (route) {
      case '/settings':
        return _buildSettingsHome(user);
      case '/settings/company':
        return _buildCompanyView();
      case '/settings/organization':
        return _buildOrganizationView();
      case '/settings/license':
        return _buildLicenseView();
      case '/settings/roles':
        return _buildRolesView();
      case '/settings/permissions':
        return _buildPermissionsView();
      case '/settings/audit':
        return _buildAuditLogsView();
      case '/settings/approval-workflow':
        return _buildApprovalWorkflowView();
      default:
        return _buildSettingsHome(user);
    }
  }

  // ─── Settings Home (Navigation Hub) ─────────────────────────────────────────

  Widget _buildSettingsHome(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(user: user),
        const SizedBox(height: 24),
        Text('SYSTEM SETTINGS', style: ApexTypography.sectionHeader),
        const SizedBox(height: 8),
        _SettingsGroup(items: [
          _SettingsItem(icon: Icons.business, label: 'Company Settings', subtitle: 'Configure registration, domain, and tax details', onTap: () => context.go('/settings/company')),
          _SettingsItem(icon: Icons.account_tree_outlined, label: 'Organisation Structure', subtitle: 'View organizational chart and hierarchy', onTap: () => context.go('/settings/organization')),
          _SettingsItem(icon: Icons.verified_outlined, label: 'License & Subscription', subtitle: 'Check limits parameters and renew plan', onTap: () => context.go('/settings/license')),
        ]),
        const SizedBox(height: 20),
        Text('SECURITY & ROLES', style: ApexTypography.sectionHeader),
        const SizedBox(height: 8),
        _SettingsGroup(items: [
          _SettingsItem(icon: Icons.shield_outlined, label: 'User Roles', subtitle: 'Configure user groups and RBAC profiles', onTap: () => context.go('/settings/roles')),
          _SettingsItem(icon: Icons.lock_outline, label: 'Permissions Matrix', subtitle: 'Map feature permissions checkboxes to roles', onTap: () => context.go('/settings/permissions')),
          _SettingsItem(icon: Icons.history, label: 'Audit Logs', subtitle: 'Track administrative overrides and actions', onTap: () => context.go('/settings/audit')),
        ]),
        const SizedBox(height: 20),
        Text('WORKFLOWS', style: ApexTypography.sectionHeader),
        const SizedBox(height: 8),
        _SettingsGroup(items: [
          _SettingsItem(icon: Icons.check_circle_outline, label: 'Approval Workflow', subtitle: 'Set up approval L1/L2 stages rules', onTap: () => context.go('/settings/approval-workflow')),
        ]),
      ],
    );
  }

  // ─── Sub-views Implementations ─────────────────────────────────────────────

  Widget _buildCompanyView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Information', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          ApexTextField(label: 'Company Name *', controller: _compNameCtrl, required: true),
          const SizedBox(height: 12),
          ApexTextField(label: 'Corporate Domain *', controller: _compDomainCtrl, required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ApexTextField(label: 'Registration Number *', controller: _compRegCtrl, required: true)),
              const SizedBox(width: 16),
              Expanded(child: ApexTextField(label: 'Primary HR Email *', controller: _compEmailCtrl, required: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Organizational Hierarchy', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          _orgNode('Acme Corporate Board', isRoot: true),
          _orgLink(),
          _orgNode('Head Office (HO Branch)'),
          _orgLink(),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                _orgNode('Engineering Department'),
                _orgLink(),
                _orgNode('HR Department'),
                _orgLink(),
                _orgNode('Finance Department'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orgNode(String name, {bool isRoot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRoot ? ApexColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isRoot ? ApexColors.primary : ApexColors.neutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isRoot ? Icons.account_tree : Icons.business, color: isRoot ? ApexColors.primary : ApexColors.neutral600, size: 16),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(fontWeight: isRoot ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _orgLink() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Icon(Icons.arrow_downward, size: 14, color: ApexColors.neutral400),
    );
  }

  Widget _buildLicenseView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Plan: Premium Enterprise SaaS', style: ApexTypography.cardTitle),
              const Spacer(),
              ApexBadge.success('ACTIVE'),
            ],
          ),
          const Divider(height: 32),
          _limitRow('Employee Records Count', '42 / 50 allocated'),
          _limitRow('Biometric Devices Pairing', '3 / 5 registered'),
          _limitRow('Office Branches Mapping', '4 / 10 mapped'),
          const Divider(height: 32),
          Row(
            children: [
              const Text('License Expiration: 2027-06-28 (1 year remaining)', style: TextStyle(fontStyle: FontStyle.italic)),
              const Spacer(),
              ApexButton(label: 'Renew Subscription', type: ApexButtonType.outline, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _limitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: ApexColors.primary)),
        ],
      ),
    );
  }

  Widget _buildRolesView() {
    return Column(
      children: [
        ..._roles.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: ApexColors.primary.withOpacity(0.1), child: const Icon(Icons.shield_outlined, color: ApexColors.primary)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['name'] as String, style: ApexTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text('Code: ${r['code']} • Perms: ${r['perms_count']} active', style: ApexTypography.captionSmall),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                    onSelected: (v) {
                      if (v == 'delete') setState(() => _roles.removeWhere((x) => x['id'] == r['id']));
                    },
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPermissionsView() {
    final roles = _permissionMatrix.keys.toList();
    final perms = _permissionMatrix.values.first.keys.toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        children: [
          // Matrix Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ApexColors.neutral50,
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('PERMISSION TYPE', style: TextStyle(fontWeight: FontWeight.bold))),
                ...roles.map((r) => Expanded(child: Text(r, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
              ],
            ),
          ),
          // Matrix Slices
          ...perms.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ApexColors.neutral200, width: 0.5))),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(p, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ...roles.map((r) {
                      final val = _permissionMatrix[r]![p] ?? false;
                      return Expanded(
                        child: Checkbox(
                          value: val,
                          onChanged: (v) {
                            setState(() {
                              _permissionMatrix[r]![p] = v ?? false;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAuditLogsView() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ApexColors.neutral50,
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('TIMESTAMP', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('OPERATOR', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 5, child: Text('DETAILS', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ..._auditLogs.map((log) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ApexColors.neutral200, width: 0.5))),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(log['time'] as String, style: const TextStyle(fontSize: 11))),
                    Expanded(flex: 2, child: Text(log['operator'] as String, style: const TextStyle(fontSize: 11))),
                    Expanded(flex: 3, child: Text(log['action'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                    Expanded(flex: 5, child: Text(log['details'] as String, style: TextStyle(color: ApexColors.neutral600, fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildApprovalWorkflowView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approval Stages Configuration', style: ApexTypography.cardTitle),
          const SizedBox(height: 16),
          _approvalRow('Leave Request Approvals', 'L1 Reporting Manager'),
          _approvalRow('Overtime Claims Approvals', 'L1 Manager + HR Admin approval'),
          _approvalRow('Attendance Regularization', 'L1 Reporting Manager'),
        ],
      ),
    );
  }

  Widget _approvalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: ApexColors.primary)),
        ],
      ),
    );
  }

  // ─── Routing Headers Helper ────────────────────────────────────────────────

  String _getTitle(String route) {
    switch (route) {
      case '/settings/company':
        return 'Company Settings';
      case '/settings/organization':
        return 'Organisation Structure';
      case '/settings/license':
        return 'License & Subscription';
      case '/settings/roles':
        return 'User Roles';
      case '/settings/permissions':
        return 'Permissions Matrix';
      case '/settings/audit':
        return 'Audit Logs';
      case '/settings/approval-workflow':
        return 'Approval Workflows';
      default:
        return 'Administration';
    }
  }

  String _getDescription(String route) {
    switch (route) {
      case '/settings/company':
        return 'Update your registration credentials, domain parameters, and primary contact.';
      case '/settings/organization':
        return 'Visualize your business departments and branches tree hierarchy.';
      case '/settings/license':
        return 'Verify billing models, subscription caps, and active counts.';
      case '/settings/roles':
        return 'Configure User Role Groups (e.g. Super Admin, HR, Manager).';
      case '/settings/permissions':
        return 'Map functional permissions checks to specific Role Groups.';
      case '/settings/audit':
        return 'Complete trail logs of all database overrides and manager actions.';
      case '/settings/approval-workflow':
        return 'Configure approval escalations levels L1/L2 for leaves and timesheets.';
      default:
        return 'Configure organization settings, roles profiles, and biometric server configs.';
    }
  }
}

// ─── Settings Home Helper widgets ───────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ApexColors.primary.withOpacity(0.1),
            child: Text(
              (user?.fullName ?? 'U').isNotEmpty ? (user?.fullName ?? 'U')[0].toUpperCase() : 'U',
              style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'User', style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900)),
                Text(user?.email ?? '', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
          ApexBadge.info('ADMIN'),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, size: 20, color: ApexColors.primary),
                title: Text(item.label, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(item.subtitle, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                trailing: const Icon(Icons.chevron_right, size: 18, color: ApexColors.neutral500),
                onTap: item.onTap,
                dense: true,
              ),
              if (i < items.length - 1) const Divider(height: 1, color: ApexColors.neutral200),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.label, required this.subtitle, required this.onTap});
}
