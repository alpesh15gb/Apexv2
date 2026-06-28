import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

final assetStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/assets/stats');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final assetListProvider = StateNotifierProvider<AssetListNotifier, AssetListState>((ref) {
  return AssetListNotifier(ref.read(dioProvider));
});

class AssetListState {
  final List<Map<String, dynamic>> assets;
  final bool loading;
  final String? error;
  final int total;
  final int totalPages;
  final int page;
  final String? categoryFilter;
  final String? statusFilter;

  AssetListState({
    this.assets = const [],
    this.loading = false,
    this.error,
    this.total = 0,
    this.totalPages = 1,
    this.page = 1,
    this.categoryFilter,
    this.statusFilter,
  });

  AssetListState copyWith({
    List<Map<String, dynamic>>? assets,
    bool? loading,
    String? error,
    int? total,
    int? totalPages,
    int? page,
    String? categoryFilter,
    String? statusFilter,
  }) {
    return AssetListState(
      assets: assets ?? this.assets,
      loading: loading ?? this.loading,
      error: error,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      page: page ?? this.page,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AssetListNotifier extends StateNotifier<AssetListState> {
  final dynamic _dio;
  AssetListNotifier(this._dio) : super(AssetListState()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 20};
      if (state.categoryFilter != null) params['category'] = state.categoryFilter;
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final res = await _dio.get('/assets/', queryParameters: params);
      final data = res.data;
      state = state.copyWith(
        assets: List<Map<String, dynamic>>.from(data['items'] ?? []),
        loading: false,
        total: data['total'] ?? 0,
        totalPages: data['total_pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter({String? category, String? status}) {
    state = state.copyWith(categoryFilter: category, statusFilter: status);
    fetch();
  }
}

class AssetDashboardScreen extends ConsumerWidget {
  const AssetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(assetStatsProvider);
    final assetState = ref.watch(assetListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('Asset Management', style: ApexTypography.sectionTitle),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateAssetDialog(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Asset'),
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _StatsRow(stats: stats, isMobile: isMobile),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            _FiltersBar(),
            const SizedBox(height: 12),
            _AssetTable(state: assetState, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  void _showCreateAssetDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'laptop';
    DateTime? purchaseDate;
    DateTime? warrantyEnd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name *', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Asset Code *', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['laptop', 'desktop', 'monitor', 'mobile', 'tablet', 'printer', 'furniture', 'vehicle', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Purchase Cost', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/assets/', data: {
                    'name': nameCtrl.text.trim(),
                    'asset_code': codeCtrl.text.trim(),
                    'category': category,
                    'serial_number': serialCtrl.text.trim(),
                    'model': modelCtrl.text.trim(),
                    'brand': brandCtrl.text.trim(),
                    'vendor': vendorCtrl.text.trim(),
                    'purchase_cost': double.tryParse(costCtrl.text),
                    'location': locationCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(assetListProvider);
                  ref.invalidate(assetStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset created'), backgroundColor: ApexColors.successDark));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isMobile;

  const _StatsRow({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(title: 'Total Assets', value: '${stats['total_assets'] ?? 0}', icon: Icons.inventory_2, color: ApexColors.primary600),
      _StatCard(title: 'Assigned', value: '${stats['assigned'] ?? 0}', icon: Icons.person, color: ApexColors.successDark),
      _StatCard(title: 'Available', value: '${stats['available'] ?? 0}', icon: Icons.check_circle, color: ApexColors.primary600),
      _StatCard(title: 'Maintenance', value: '${stats['maintenance'] ?? 0}', icon: Icons.build, color: ApexColors.warning),
      _StatCard(title: 'Warranty Expiring', value: '${stats['warranty_expiring'] ?? 0}', icon: Icons.warning, color: ApexColors.error),
      _StatCard(title: 'Total Value', value: '₹${_formatAmount(stats['total_value'] ?? 0)}', icon: Icons.account_balance_wallet, color: ApexColors.successDark),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 3,
        child: c,
      )).toList(),
    );
  }

  String _formatAmount(dynamic amount) {
    final val = (amount as num?)?.toDouble() ?? 0;
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Text(value, style: ApexTypography.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          _statusChip('All', null),
          _statusChip('Available', 'available'),
          _statusChip('Assigned', 'assigned'),
          _statusChip('Maintenance', 'maintenance'),
          _statusChip('Retired', 'retired'),
          const Spacer(),
          IconButton(icon: Icon(Icons.download, size: 18, color: ApexColors.neutral500), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String? status) {
    final current = ref.watch(assetListProvider).statusFilter;
    final isActive = current == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: ApexTypography.captionMedium.copyWith(color: isActive ? ApexColors.primary600 : ApexColors.neutral500)),
        selected: isActive,
        onSelected: (_) => ref.read(assetListProvider.notifier).setFilter(status: status),
        selectedColor: ApexColors.primary600.withOpacity(0.1),
        side: BorderSide(color: isActive ? ApexColors.primary600 : ApexColors.neutral200),
      ),
    );
  }
}

class _AssetTable extends StatelessWidget {
  final AssetListState state;
  final bool isMobile;

  const _AssetTable({required this.state, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.assets.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (state.assets.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Center(child: Text('No assets found', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: ApexColors.neutral50,
              child: Row(children: [
                SizedBox(width: 180, child: Text('ASSET', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('CODE', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('CATEGORY', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('SERIAL', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5))),
                SizedBox(width: 80, child: Text('STATUS', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5))),
                SizedBox(width: 60, child: Text('', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500))),
              ]),
            ),
          ...state.assets.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            final status = a['status'] ?? 'available';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: i.isEven ? ApexColors.neutral0 : ApexColors.neutral50,
              child: Row(children: [
                SizedBox(width: 180, child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: _categoryColor(a['category']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_categoryIcon(a['category']), size: 18, color: _categoryColor(a['category'])),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['name'] ?? '—', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900), overflow: TextOverflow.ellipsis),
                      Text(a['brand'] ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ],
                  )),
                ])),
                SizedBox(width: 100, child: Text(a['asset_code'] ?? '—', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
                SizedBox(width: 100, child: Text((a['category'] ?? '—').toString().toUpperCase(), style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral900))),
                SizedBox(width: 100, child: Text(a['serial_number'] ?? '—', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500))),
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(status.toUpperCase(), style: ApexTypography.badge.copyWith(fontSize: 10, color: _statusColor(status))),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'view', child: Text('View')),
                      if (status == 'available') const PopupMenuItem(value: 'assign', child: Text('Assign')),
                      if (status == 'assigned') const PopupMenuItem(value: 'return', child: Text('Return')),
                      const PopupMenuItem(value: 'maintenance', child: Text('Send to Maintenance')),
                    ],
                    onSelected: (v) {
                      if (v == 'assign') _showAssignDialog(context, a['id']);
                    },
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, String assetId) {
    // Simplified assign dialog
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assign feature - select employee')));
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'laptop': return ApexColors.primary600;
      case 'desktop': return ApexColors.info;
      case 'mobile': return ApexColors.successDark;
      case 'printer': return ApexColors.warning;
      default: return ApexColors.neutral500;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'laptop': return Icons.laptop;
      case 'desktop': return Icons.desktop_windows;
      case 'mobile': return Icons.phone_android;
      case 'tablet': return Icons.tablet;
      case 'printer': return Icons.print;
      case 'furniture': return Icons.chair;
      case 'vehicle': return Icons.directions_car;
      default: return Icons.inventory_2;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available': return ApexColors.successDark;
      case 'assigned': return ApexColors.primary600;
      case 'maintenance': return ApexColors.warning;
      case 'retired': return ApexColors.neutral500;
      case 'lost': return ApexColors.error;
      case 'damaged': return ApexColors.error;
      default: return ApexColors.neutral500;
    }
  }
}

