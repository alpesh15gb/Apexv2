import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class WorkCodeItem {
  final String id, code, name;
  final String? description;
  final bool isActive;
  WorkCodeItem({required this.id, required this.code, required this.name, this.description, required this.isActive});
  factory WorkCodeItem.fromJson(Map<String, dynamic> json) => WorkCodeItem(id: json['id'], code: json['code'], name: json['name'], description: json['description'], isActive: json['is_active'] ?? true);
}

final workCodeListProvider = StateNotifierProvider<WorkCodeListNotifier, AsyncValue<List<WorkCodeItem>>>((ref) => WorkCodeListNotifier(ref.read(dioProvider)));

class WorkCodeListNotifier extends StateNotifier<AsyncValue<List<WorkCodeItem>>> {
  final dynamic _dio;
  WorkCodeListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/work-codes/');
      state = AsyncValue.data((r.data as List).map((e) => WorkCodeItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/work-codes/', data: data);
    if (state.value != null) state = AsyncValue.data([WorkCodeItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/work-codes/$id', data: data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((w) => w.id == id ? WorkCodeItem.fromJson(r.data) : w).toList());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/work-codes/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((w) => w.id != id).toList());
  }
}

class WorkCodeScreen extends ConsumerWidget {
  const WorkCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codesAsync = ref.watch(workCodeListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Work Codes'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))],
      ),
      body: codesAsync.when(
        data: (codes) {
          if (codes.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.work_outline, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Work Codes', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Create work codes for project/task tracking', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: codes.length, itemBuilder: (context, i) {
            final w = codes[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(w.code, style: ApexTypography.captionSmall.copyWith(color: _primary, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                if (w.description != null && w.description!.isNotEmpty) Text(w.description!, style: ApexTypography.caption.copyWith(color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, wc: w); if (v == 'delete') _confirmDelete(context, ref, w.id, w.name); }),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {WorkCodeItem? wc}) {
    final codeCtrl = TextEditingController(text: wc?.code ?? '');
    final nameCtrl = TextEditingController(text: wc?.name ?? '');
    final descCtrl = TextEditingController(text: wc?.description ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(wc != null ? 'Edit Work Code' : 'Add Work Code'),
      content: SizedBox(width: 350, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder(), hintText: 'e.g. PROJ-001')),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final data = {'code': codeCtrl.text.trim().toUpperCase(), 'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
          final notifier = ref.read(workCodeListProvider.notifier);
          if (wc != null) { await notifier.update(wc.id, data); } else { await notifier.add(data); }
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: Text(wc != null ? 'Update' : 'Add')),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Work Code'), content: Text('Delete "$name"?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { ref.read(workCodeListProvider.notifier).delete(id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white), child: const Text('Delete')),
    ]));
  }
}
