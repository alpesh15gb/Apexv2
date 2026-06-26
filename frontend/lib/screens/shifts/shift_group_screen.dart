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

class ShiftGroupItem {
  final String id, name;
  final String? description;
  final bool isActive;
  ShiftGroupItem({required this.id, required this.name, this.description, required this.isActive});
  factory ShiftGroupItem.fromJson(Map<String, dynamic> json) => ShiftGroupItem(id: json['id'], name: json['name'], description: json['description'], isActive: json['is_active'] ?? true);
}

class ShiftOption {
  final String id, name;
  ShiftOption({required this.id, required this.name});
  factory ShiftOption.fromJson(Map<String, dynamic> json) => ShiftOption(id: json['id'], name: json['name']);
}

final shiftGroupListProvider = StateNotifierProvider<ShiftGroupListNotifier, AsyncValue<List<ShiftGroupItem>>>((ref) => ShiftGroupListNotifier(ref.read(dioProvider)));

class ShiftGroupListNotifier extends StateNotifier<AsyncValue<List<ShiftGroupItem>>> {
  final dynamic _dio;
  ShiftGroupListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/shift-groups/');
      state = AsyncValue.data((r.data as List).map((e) => ShiftGroupItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/shift-groups/', data: data);
    if (state.value != null) state = AsyncValue.data([ShiftGroupItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/shift-groups/$id', data: data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((g) => g.id == id ? ShiftGroupItem.fromJson(r.data) : g).toList());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/shift-groups/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((g) => g.id != id).toList());
  }
}

class ShiftGroupScreen extends ConsumerWidget {
  const ShiftGroupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(shiftGroupListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Shift Groups'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.group_work_outlined, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Shift Groups', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Group shifts together for easier assignment', style: ApexTypography.body.copyWith(color: _muted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _showDialog(context, ref), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Add Group')),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: groups.length, itemBuilder: (context, i) {
            final g = groups[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.group_work, color: _primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                if (g.description != null && g.description!.isNotEmpty) Text(g.description!, style: ApexTypography.caption.copyWith(color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: g.isActive ? _success.withOpacity(0.1) : _muted.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(g.isActive ? 'ACTIVE' : 'INACTIVE', style: ApexTypography.captionSmall.copyWith(color: g.isActive ? _success : _muted, fontWeight: FontWeight.w600))),
              PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, group: g); if (v == 'delete') _confirmDelete(context, ref, g.id, g.name); }),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {ShiftGroupItem? group}) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final descCtrl = TextEditingController(text: group?.description ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(group != null ? 'Edit Shift Group' : 'Add Shift Group'),
      content: SizedBox(width: 350, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final data = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
          final notifier = ref.read(shiftGroupListProvider.notifier);
          if (group != null) { await notifier.update(group.id, data); } else { await notifier.add(data); }
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: Text(group != null ? 'Update' : 'Add')),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Group'), content: Text('Delete "$name"?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { ref.read(shiftGroupListProvider.notifier).delete(id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white), child: const Text('Delete')),
    ]));
  }
}
