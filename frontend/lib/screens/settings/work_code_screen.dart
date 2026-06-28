import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

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
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Work Codes'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))],
      ),
      body: codesAsync.when(
        data: (codes) {
          if (codes.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.work_outline, size: 48, color: ApexColors.neutral500),
            const SizedBox(height: 16),
            Text('No Work Codes', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text('Create work codes for project/task tracking', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: codes.length, itemBuilder: (context, i) {
            final w = codes[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: ApexColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(w.code, style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                if (w.description != null && w.description!.isNotEmpty) Text(w.description!, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              PopupMenuButton<String>(icon: Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: ApexColors.error)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, wc: w); if (v == 'delete') _confirmDelete(context, ref, w.id, w.name); }),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {WorkCodeItem? wc}) {
    final codeCtrl = TextEditingController(text: wc?.code ?? '');
    final nameCtrl = TextEditingController(text: wc?.name ?? '');
    final descCtrl = TextEditingController(text: wc?.description ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(wc != null ? 'Edit Work Code' : 'Add Work Code', style: ApexTypography.cardTitle),
      content: SizedBox(width: 350, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ApexTextField(label: 'Code', controller: codeCtrl, required: true, hint: 'e.g. PROJ-001'),
        const SizedBox(height: 12),
        ApexTextField(label: 'Name', controller: nameCtrl, required: true),
        const SizedBox(height: 12),
        ApexTextField(label: 'Description', controller: descCtrl, maxLines: 2),
      ])),
      actions: [
        ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
        ApexButton(
          label: wc != null ? 'Update' : 'Add',
          onPressed: () async {
            final data = {'code': codeCtrl.text.trim().toUpperCase(), 'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
            final notifier = ref.read(workCodeListProvider.notifier);
            if (wc != null) { await notifier.update(wc.id, data); } else { await notifier.add(data); }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          type: ApexButtonType.primary,
        ),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Delete Work Code', style: ApexTypography.cardTitle),
      content: Text('Delete "$name"?', style: ApexTypography.body),
      actions: [
        ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
        ApexButton(
          label: 'Delete',
          onPressed: () { ref.read(workCodeListProvider.notifier).delete(id); Navigator.pop(ctx); },
          type: ApexButtonType.danger,
        ),
      ],
    ));
  }
}

