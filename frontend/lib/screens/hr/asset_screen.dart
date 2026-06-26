import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _warning = Color(0xFFF59E0B);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class AssetItem {
  final String id, name, assetCode, category, status;
  final String? serialNumber, description, assignedTo;
  AssetItem({required this.id, required this.name, required this.assetCode, required this.category, required this.status, this.serialNumber, this.description, this.assignedTo});
  factory AssetItem.fromJson(Map<String, dynamic> json) => AssetItem(id: json['id'], name: json['name'], assetCode: json['asset_code'], category: json['category'] ?? 'other', status: json['status'] ?? 'available', serialNumber: json['serial_number'], description: json['description'], assignedTo: json['assigned_to']);
}

final assetListProvider = StateNotifierProvider<AssetListNotifier, AsyncValue<List<AssetItem>>>((ref) => AssetListNotifier(ref.read(dioProvider)));

class AssetListNotifier extends StateNotifier<AsyncValue<List<AssetItem>>> {
  final dynamic _dio;
  AssetListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/hr/assets');
      state = AsyncValue.data((r.data as List).map((e) => AssetItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/hr/assets', data: data);
    if (state.value != null) state = AsyncValue.data([AssetItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/hr/assets/$id', data: data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((a) => a.id == id ? AssetItem.fromJson(r.data) : a).toList());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/hr/assets/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((a) => a.id != id).toList());
  }
}

class AssetScreen extends ConsumerWidget {
  const AssetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(title: 'Company Assets', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))]),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Assets', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Track company assets like laptops, phones, etc.', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: assets.length, itemBuilder: (context, i) {
            final a = assets[i];
            final statusColor = a.status == 'assigned' ? _primary : a.status == 'available' ? _success : _muted;
            final catIcons = {'laptop': Icons.laptop, 'phone': Icons.phone, 'vehicle': Icons.directions_car};
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(catIcons[a.category] ?? Icons.inventory_2, color: statusColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${a.assetCode} • ${a.category} • ${a.serialNumber ?? "No S/N"}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(a.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
              PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, asset: a); if (v == 'delete') ref.read(assetListProvider.notifier).delete(a.id); }),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {AssetItem? asset}) {
    final nameCtrl = TextEditingController(text: asset?.name ?? '');
    final codeCtrl = TextEditingController(text: asset?.assetCode ?? '');
    final serialCtrl = TextEditingController(text: asset?.serialNumber ?? '');
    String category = asset?.category ?? 'other';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(asset != null ? 'Edit Asset' : 'Add Asset'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Asset Code *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'laptop', child: Text('Laptop')),
          DropdownMenuItem(value: 'phone', child: Text('Phone')),
          DropdownMenuItem(value: 'vehicle', child: Text('Vehicle')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
        ], onChanged: (v) => setS(() => category = v ?? 'other')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final data = {'name': nameCtrl.text.trim(), 'asset_code': codeCtrl.text.trim(), 'serial_number': serialCtrl.text.trim(), 'category': category};
          final notifier = ref.read(assetListProvider.notifier);
          if (asset != null) { await notifier.update(asset.id, data); } else { await notifier.add(data); }
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: Text(asset != null ? 'Update' : 'Add')),
      ],
    )));
  }
}
