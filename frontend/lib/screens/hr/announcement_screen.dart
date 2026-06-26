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

class AnnouncementScreen extends ConsumerWidget {
  const AnnouncementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annAsync = ref.watch(announcementListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(title: 'Announcements', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))]),
      body: annAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.campaign_outlined, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Announcements', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Create announcements to share with your team', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final a = items[i];
            final priorityColor = a.priority == 'urgent' ? _danger : a.priority == 'important' ? _warning : _primary;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(a.priority.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: priorityColor, fontWeight: FontWeight.w600))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: _danger), onPressed: () => ref.read(announcementListProvider.notifier).delete(a.id)),
              ]),
              const SizedBox(height: 8),
              Text(a.title, style: ApexTypography.titleSmall.copyWith(color: _text)),
              const SizedBox(height: 4),
              Text(a.body, style: ApexTypography.body.copyWith(color: _muted)),
            ]));
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
      title: const Text('New Announcement'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body *', border: OutlineInputBorder()), maxLines: 4),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'normal', child: Text('Normal')),
          DropdownMenuItem(value: 'important', child: Text('Important')),
          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
        ], onChanged: (v) => setS(() => priority = v ?? 'normal')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
          await ref.read(announcementListProvider.notifier).add({'title': titleCtrl.text.trim(), 'body': bodyCtrl.text.trim(), 'priority': priority});
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Publish')),
      ],
    )));
  }
}
