import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

class AnnouncementItem {
  final String id, title, body, priority;
  AnnouncementItem({required this.id, required this.title, required this.body, required this.priority});
  factory AnnouncementItem.fromJson(Map<String, dynamic> json) => AnnouncementItem(id: json['id'], title: json['title'], body: json['body'], priority: json['priority'] ?? 'normal');
}

class PollItem {
  final String id, question;
  final List<dynamic> options;
  PollItem({required this.id, required this.question, required this.options});
  factory PollItem.fromJson(Map<String, dynamic> json) => PollItem(id: json['id'], question: json['question'], options: json['options'] ?? []);
}

final announcementListProvider = StateNotifierProvider<AnnouncementListNotifier, AsyncValue<List<AnnouncementItem>>>((ref) => AnnouncementListNotifier(ref.read(dioProvider)));

class AnnouncementListNotifier extends StateNotifier<AsyncValue<List<AnnouncementItem>>> {
  final dynamic _dio;
  AnnouncementListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/hr/announcements');
      state = AsyncValue.data((r.data as List).map((e) => AnnouncementItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/hr/announcements', data: data);
    if (state.value != null) state = AsyncValue.data([AnnouncementItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/hr/announcements/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((a) => a.id != id).toList());
  }
}

ApexBadgeType _priorityBadge(String priority) {
  if (priority == 'urgent') return ApexBadgeType.danger;
  if (priority == 'important') return ApexBadgeType.warning;
  return ApexBadgeType.info;
}

class AnnouncementScreen extends ConsumerWidget {
  const AnnouncementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annAsync = ref.watch(announcementListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(title: 'Announcements', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))]),
      body: annAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.campaign_outlined, size: 48, color: ApexColors.neutral400),
            const SizedBox(height: 16),
            Text('No Announcements', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text('Create announcements to share with your team', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final a = items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ApexCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    ApexBadge(label: a.priority, type: _priorityBadge(a.priority)),
                    const Spacer(),
                    IconButton(icon: Icon(Icons.delete_outline, size: 16, color: ApexColors.error), onPressed: () => ref.read(announcementListProvider.notifier).delete(a.id)),
                  ]),
                  const SizedBox(height: 8),
                  Text(a.title, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(height: 4),
                  Text(a.body, style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                ]),
              ),
            );
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String priority = 'normal';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text('New Announcement', style: ApexTypography.sectionTitle),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ApexTextField(label: 'Title', controller: titleCtrl, required: true),
        const SizedBox(height: 12),
        ApexTextField(label: 'Body', controller: bodyCtrl, required: true, maxLines: 4),
        const SizedBox(height: 12),
        ApexDropdown<String>(label: 'Priority', value: priority, items: const [
          DropdownMenuItem(value: 'normal', child: Text('Normal')),
          DropdownMenuItem(value: 'important', child: Text('Important')),
          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
        ], onChanged: (v) => setS(() => priority = v ?? 'normal')),
      ])),
      actions: [
        ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
        ApexButton(label: 'Publish', onPressed: () async {
          if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
          await ref.read(announcementListProvider.notifier).add({'title': titleCtrl.text.trim(), 'body': bodyCtrl.text.trim(), 'priority': priority});
          if (ctx.mounted) Navigator.pop(ctx);
        }),
      ],
    )));
  }
}
