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
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class DocItem {
  final String id, title, docType, fileName;
  final String? employeeId, description;
  final int fileSize;
  final bool isConfidential;
  DocItem({required this.id, required this.title, required this.docType, required this.fileName, this.employeeId, this.description, required this.fileSize, required this.isConfidential});
  factory DocItem.fromJson(Map<String, dynamic> json) => DocItem(id: json['id'], title: json['title'], docType: json['doc_type'] ?? 'other', fileName: json['file_name'], employeeId: json['employee_id'], description: json['description'], fileSize: json['file_size'] ?? 0, isConfidential: json['is_confidential'] ?? false);
}

final documentListProvider = StateNotifierProvider<DocumentListNotifier, AsyncValue<List<DocItem>>>((ref) => DocumentListNotifier(ref.read(dioProvider)));

class DocumentListNotifier extends StateNotifier<AsyncValue<List<DocItem>>> {
  final dynamic _dio;
  DocumentListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false, String? employeeId}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final params = <String, dynamic>{};
      if (employeeId != null) params['employee_id'] = employeeId;
      final r = await _dio.get('/documents/', queryParameters: params);
      state = AsyncValue.data((r.data as List).map((e) => DocItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/documents/', data: data);
    if (state.value != null) state = AsyncValue.data([DocItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/documents/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
  }
}

class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(title: 'Documents', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showAddDialog(context, ref))]),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.folder_open, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Documents', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Upload documents to get started', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (context, i) {
            final d = docs[i];
            final typeIcons = {'offer_letter': Icons.description, 'experience_letter': Icons.work, 'id_proof': Icons.badge, 'certificate': Icons.school, 'policy': Icons.gavel};
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(typeIcons[d.docType] ?? Icons.insert_drive_file, color: _primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(d.title, style: ApexTypography.titleSmall.copyWith(color: _text))), if (d.isConfidential) const Icon(Icons.lock, size: 14, color: _danger)]),
                Text('${d.docType.replaceAll("_", " ").toUpperCase()} • ${d.fileName}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: _danger), onPressed: () => ref.read(documentListProvider.notifier).delete(d.id)),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final fileNameCtrl = TextEditingController();
    final filePathCtrl = TextEditingController();
    String docType = 'other';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Add Document'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: docType, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'offer_letter', child: Text('Offer Letter')),
          DropdownMenuItem(value: 'experience_letter', child: Text('Experience Letter')),
          DropdownMenuItem(value: 'id_proof', child: Text('ID Proof')),
          DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
          DropdownMenuItem(value: 'policy', child: Text('Policy')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
        ], onChanged: (v) => setS(() => docType = v ?? 'other')),
        const SizedBox(height: 12),
        TextField(controller: fileNameCtrl, decoration: const InputDecoration(labelText: 'File Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: filePathCtrl, decoration: const InputDecoration(labelText: 'File Path *', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await ref.read(documentListProvider.notifier).add({'title': titleCtrl.text.trim(), 'doc_type': docType, 'file_name': fileNameCtrl.text.trim(), 'file_path': filePathCtrl.text.trim()});
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Add')),
      ],
    )));
  }
}
