import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/page_wrapper.dart';

class DocItem {
  final String id, title, docType, fileName;
  final String? employeeId, description;
  final int fileSize;
  final bool isConfidential;
  DocItem({
    required this.id,
    required this.title,
    required this.docType,
    required this.fileName,
    this.employeeId,
    this.description,
    required this.fileSize,
    required this.isConfidential,
  });
  factory DocItem.fromJson(Map<String, dynamic> json) => DocItem(
        id: json['id'],
        title: json['title'],
        docType: json['doc_type'] ?? 'other',
        fileName: json['file_name'],
        employeeId: json['employee_id'],
        description: json['description'],
        fileSize: json['file_size'] ?? 0,
        isConfidential: json['is_confidential'] ?? false,
      );
}

final documentListProvider = StateNotifierProvider<DocumentListNotifier, AsyncValue<List<DocItem>>>((ref) {
  return DocumentListNotifier(ref.read(dioProvider));
});

class DocumentListNotifier extends StateNotifier<AsyncValue<List<DocItem>>> {
  final dynamic _dio;
  DocumentListNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch({bool isRefresh = false, String? employeeId}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final params = <String, dynamic>{};
      if (employeeId != null) params['employee_id'] = employeeId;
      final r = await _dio.get('/documents/', queryParameters: params);
      state = AsyncValue.data((r.data as List).map((e) => DocItem.fromJson(e)).toList());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/documents/', data: data);
    if (state.value != null) {
      state = AsyncValue.data([DocItem.fromJson(r.data), ...state.value!]);
    }
  }

  Future<void> delete(String id) async {
    await _dio.delete('/documents/$id');
    if (state.value != null) {
      state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
    }
  }
}

class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee Documents',
        description: 'Store and manage employee document templates and records.',
        onRefresh: () => ref.read(documentListProvider.notifier).fetch(isRefresh: true),
        actions: [
          ApexButton(
            label: 'Add Document',
            onPressed: () => _showAddDialog(context, ref),
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        body: docsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Documents', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 8),
                    Text('Upload documents to get started', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final typeIcons = {
                  'offer_letter': Icons.description,
                  'experience_letter': Icons.work,
                  'id_proof': Icons.badge,
                  'certificate': Icons.school,
                  'policy': Icons.gavel,
                  'other': Icons.insert_drive_file,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ApexColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ApexColors.primary600.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(typeIcons[d.docType] ?? Icons.insert_drive_file, color: ApexColors.primary600, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(d.title, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                                  ),
                                  if (d.isConfidential)
                                    const Icon(Icons.lock, size: 14, color: ApexColors.error),
                                ],
                              ),
                              Text('${d.docType.replaceAll("_", " ").toUpperCase()} • ${d.fileName}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: ApexColors.error),
                          onPressed: () => ref.read(documentListProvider.notifier).delete(d.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final fileNameCtrl = TextEditingController();
    final filePathCtrl = TextEditingController();
    String docType = 'other';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Add Document', style: ApexTypography.sectionTitle),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(label: 'Title', controller: titleCtrl, required: true),
                const SizedBox(height: 12),
                ApexDropdown<String>(
                  label: 'Type',
                  value: docType,
                  items: const [
                    DropdownMenuItem(value: 'offer_letter', child: Text('Offer Letter')),
                    DropdownMenuItem(value: 'experience_letter', child: Text('Experience Letter')),
                    DropdownMenuItem(value: 'id_proof', child: Text('ID Proof')),
                    DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
                    DropdownMenuItem(value: 'policy', child: Text('Policy')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setS(() => docType = v ?? 'other'),
                ),
                const SizedBox(height: 12),
                ApexTextField(label: 'File Name', controller: fileNameCtrl, required: true),
                const SizedBox(height: 12),
                ApexTextField(label: 'File Path', controller: filePathCtrl, required: true),
              ],
            ),
          ),
          actions: [
            ApexButton(
              label: 'Cancel',
              type: ApexButtonType.ghost,
              onPressed: () => Navigator.pop(ctx),
            ),
            ApexButton(
              label: 'Add',
              onPressed: () async {
                await ref.read(documentListProvider.notifier).add({
                  'title': titleCtrl.text.trim(),
                  'doc_type': docType,
                  'file_name': fileNameCtrl.text.trim(),
                  'file_path': filePathCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
