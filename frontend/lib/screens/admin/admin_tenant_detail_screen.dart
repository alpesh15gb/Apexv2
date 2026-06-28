import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';

class AdminTenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const AdminTenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<AdminTenantDetailScreen> createState() => _AdminTenantDetailScreenState();
}

class _AdminTenantDetailScreenState extends ConsumerState<AdminTenantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _tenant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _loadTenant();
  }

  Future<void> _loadTenant() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/admin/tenants/${widget.tenantId}');
      setState(() { _tenant = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_tenant == null) return const Scaffold(body: Center(child: Text('Tenant not found')));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text(_tenant!['name'] ?? 'Tenant', style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/tenants')),
        actions: [
          if (_tenant!['subscription_status'] == 'suspended')
            TextButton.icon(
              onPressed: () => _activateTenant(),
              icon: Icon(Icons.check_circle, size: 16, color: ApexColors.successDark),
              label: Text('Activate', style: ApexTypography.body.copyWith(color: ApexColors.successDark)),
            )
          else
            TextButton.icon(
              onPressed: () => _suspendTenant(),
              icon: Icon(Icons.block, size: 16, color: ApexColors.errorDark),
              label: Text('Suspend', style: ApexTypography.body.copyWith(color: ApexColors.errorDark)),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: ApexColors.primary600,
          unselectedLabelColor: ApexColors.neutral500,
          indicatorColor: ApexColors.primary600,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subscription'),
            Tab(text: 'Limits'),
            Tab(text: 'Features'),
            Tab(text: 'Users'),
            Tab(text: 'Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(tenant: _tenant!, onRefresh: _loadTenant),
          _SubscriptionTab(tenantId: widget.tenantId),
          _LimitsTab(tenantId: widget.tenantId),
          _FeaturesTab(tenantId: widget.tenantId),
          _UsersTab(tenantId: widget.tenantId),
          _AuditTab(tenantId: widget.tenantId),
        ],
      ),
    );
  }

  void _suspendTenant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Tenant'),
        content: Text('Suspend ${_tenant!['name']}? All users will lose access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: ApexColors.errorDark), child: const Text('Suspend')),
        ],
      ),
    );
    if (confirm == true) {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/tenants/${widget.tenantId}/suspend');
      _loadTenant();
    }
  }

  void _activateTenant() async {
    final dio = ref.read(dioProvider);
    await dio.post('/admin/tenants/${widget.tenantId}/activate');
    _loadTenant();
  }
}

class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic> tenant;
  final VoidCallback onRefresh;
  const _OverviewTab({required this.tenant, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = tenant['subscription_status'] ?? 'unknown';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard('Company Information', [
            _infoRow('Name', tenant['name']),
            _infoRow('Slug', tenant['slug']),
            _infoRow('Email', tenant['email'] ?? '—'),
            _infoRow('Mobile', tenant['mobile'] ?? '—'),
            _infoRow('Contact Person', tenant['contact_person'] ?? '—'),
            _infoRow('Company Code', tenant['company_code'] ?? '—'),
            _infoRow('GST Number', tenant['gst_number'] ?? '—'),
            _infoRow('PAN Number', tenant['pan_number'] ?? '—'),
            _infoRow('Currency', tenant['currency'] ?? 'INR'),
            _infoRow('Timezone', tenant['timezone'] ?? '—'),
          ]),
          const SizedBox(height: 16),
          _infoCard('Statistics', [
            _infoRow('Employees', '${tenant['employee_count'] ?? 0}'),
            _infoRow('Users', '${tenant['user_count'] ?? 0}'),
            _infoRow('Status', status.toUpperCase()),
            _infoRow('Active', tenant['is_active'] == true ? 'Yes' : 'No'),
            _infoRow('Created', tenant['created_at'] ?? '—'),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
        Expanded(child: Text(value, style: ApexTypography.caption.copyWith(color: ApexColors.neutral900))),
      ]),
    );
  }
}

class _SubscriptionTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _SubscriptionTab({required this.tenantId});
  @override
  ConsumerState<_SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends ConsumerState<_SubscriptionTab> {
  List<dynamic> _plans = [];
  Map<String, dynamic>? _subscription;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final plansRes = await dio.get('/admin/plans/');
      final tenantRes = await dio.get('/admin/tenants/${widget.tenantId}');
      setState(() {
        _plans = plansRes.data is List ? plansRes.data : [];
        _subscription = tenantRes.data['subscription'];
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_subscription != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current Subscription', style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
              const SizedBox(height: 12),
              _row('Status', _subscription!['status'] ?? '—'),
              _row('Plan', _subscription!['plan_id'] ?? '—'),
              _row('Start Date', _subscription!['start_date'] ?? '—'),
              _row('End Date', _subscription!['end_date'] ?? '—'),
              _row('Billing Cycle', _subscription!['billing_cycle'] ?? '—'),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        Text('Available Plans', style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        const SizedBox(height: 12),
        ..._plans.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
              Text('₹${p['price_monthly']}/mo • ${p['max_employees']} employees', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            ])),
            ElevatedButton(
              onPressed: () => _assignPlan(p['id']),
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              child: const Text('Assign'),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
      Text(value, style: ApexTypography.caption.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w600)),
    ]));
  }

  void _assignPlan(String planId) async {
    final dio = ref.read(dioProvider);
    await dio.put('/admin/tenants/${widget.tenantId}', data: {'subscription_status': 'active'});
    _load();
  }
}

class _LimitsTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _LimitsTab({required this.tenantId});
  @override
  ConsumerState<_LimitsTab> createState() => _LimitsTabState();
}

class _LimitsTabState extends ConsumerState<_LimitsTab> {
  List<dynamic> _limits = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/admin/tenants/${widget.tenantId}/limits');
      setState(() { _limits = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final defaultLimits = [
      {'key': 'max_employees', 'label': 'Max Employees', 'max': 50, 'current': 0},
      {'key': 'max_branches', 'label': 'Max Branches', 'max': 5, 'current': 0},
      {'key': 'max_departments', 'label': 'Max Departments', 'max': 10, 'current': 0},
      {'key': 'max_devices', 'label': 'Max Devices', 'max': 5, 'current': 0},
      {'key': 'max_admin_users', 'label': 'Max Admin Users', 'max': 2, 'current': 0},
      {'key': 'max_hr_users', 'label': 'Max HR Users', 'max': 5, 'current': 0},
      {'key': 'max_storage_mb', 'label': 'Max Storage (MB)', 'max': 1024, 'current': 0},
      {'key': 'max_api_calls', 'label': 'Max API Calls', 'max': 10000, 'current': 0},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resource Limits', style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        const SizedBox(height: 16),
        ...defaultLimits.map((lim) {
          final existing = _limits.where((l) => l['key'] == lim['key']).toList();
          final maxVal = existing.isNotEmpty ? existing[0]['max'] : lim['max'];
          final currentVal = existing.isNotEmpty ? existing[0]['current'] : lim['current'];
          final pct = maxVal > 0 ? (currentVal / maxVal * 100).round() : 0;
          final isWarning = pct >= 80;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: isWarning ? ApexColors.warning : ApexColors.neutral200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(lim['label'] as String, style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900))),
                if (isWarning) Icon(Icons.warning, size: 16, color: ApexColors.warning),
                const SizedBox(width: 8),
                Text('$currentVal / $maxVal', style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: isWarning ? ApexColors.warning : ApexColors.neutral900)),
                IconButton(
                  icon: Icon(Icons.edit, size: 16, color: ApexColors.neutral500),
                  onPressed: () => _editLimit(lim['key'] as String, maxVal as int),
                ),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: ApexColors.neutral200,
                color: isWarning ? ApexColors.warning : ApexColors.primary600,
                minHeight: 6,
              ),
            ]),
          );
        }),
      ]),
    );
  }

  void _editLimit(String key, int currentMax) {
    final ctrl = TextEditingController(text: '$currentMax');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Value')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.put('/admin/tenants/${widget.tenantId}/limits', data: [
                {'resource_key': key, 'max_value': int.tryParse(ctrl.text) ?? 0, 'is_unlimited': false},
              ]);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FeaturesTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _FeaturesTab({required this.tenantId});
  @override
  ConsumerState<_FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends ConsumerState<_FeaturesTab> {
  List<dynamic> _features = [];
  bool _loading = true;
  String _search = '';
  String _categoryFilter = 'All';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/admin/tenants/${widget.tenantId}/features');
      setState(() { _features = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final categories = ['All', ...{..._features.map((f) => f['category'] as String)}..toList()];
    final filtered = _features.where((f) {
      if (_categoryFilter != 'All' && f['category'] != _categoryFilter) return false;
      if (_search.isNotEmpty && !(f['name'] as String).toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: TextField(
            decoration: InputDecoration(hintText: 'Search features...', prefixIcon: Icon(Icons.search, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            onChanged: (v) => setState(() => _search = v),
          )),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _categoryFilter,
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final f = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['name'] ?? '', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w500, color: ApexColors.neutral900)),
                  Text('${f['category']} • ${f['code']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                ])),
                Switch(
                  value: f['is_enabled'] == true,
                  activeColor: ApexColors.primary600,
                  onChanged: (v) => _toggleFeature(f['code'], v),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  void _toggleFeature(String code, bool enabled) async {
    final dio = ref.read(dioProvider);
    await dio.put('/admin/tenants/${widget.tenantId}/features', data: {
      'feature_codes': [code],
      'enabled': enabled,
    });
    _load();
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _UsersTab({required this.tenantId});
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/employees/', queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _users = res.data['items'] ?? [];
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, i) {
        final u = _users[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
          child: Row(children: [
            CircleAvatar(radius: 16, backgroundColor: ApexColors.primary600.withOpacity(0.1), child: Text((u['first_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary600))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
              Text(u['employee_code'] ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (u['status'] == 'active' ? ApexColors.successDark : ApexColors.neutral500).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text((u['status'] ?? 'unknown').toUpperCase(), style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: u['status'] == 'active' ? ApexColors.successDark : ApexColors.neutral500)),
            ),
          ]),
        );
      },
    );
  }
}

class _AuditTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _AuditTab({required this.tenantId});
  @override
  ConsumerState<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<_AuditTab> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/admin/dashboard/recent-activity', queryParameters: {'limit': 50});
      setState(() { _logs = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (context, i) {
        final log = _logs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Icon(Icons.history, size: 16, color: ApexColors.neutral500),
            const SizedBox(width: 12),
            Expanded(child: Text(log['action'] ?? '', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900))),
            Text(log['timestamp']?.toString().substring(0, 16) ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
          ]),
        );
      },
    );
  }
}

