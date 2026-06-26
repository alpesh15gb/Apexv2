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

class ShiftRosterItem {
  final String id, name, rotationPattern, weeklyOff2Week;
  final String? description;
  final int weeklyOff1;
  final int? weeklyOff2;
  final bool isActive;
  ShiftRosterItem({required this.id, required this.name, this.description, required this.rotationPattern, required this.weeklyOff1, this.weeklyOff2, required this.weeklyOff2Week, required this.isActive});
  factory ShiftRosterItem.fromJson(Map<String, dynamic> json) => ShiftRosterItem(
    id: json['id'], name: json['name'], description: json['description'],
    rotationPattern: json['rotation_pattern'] ?? 'weekly', weeklyOff1: json['weekly_off_1'] ?? 6,
    weeklyOff2: json['weekly_off_2'], weeklyOff2Week: json['weekly_off_2_week'] ?? 'every', isActive: json['is_active'] ?? true,
  );
}

final shiftRosterListProvider = StateNotifierProvider<ShiftRosterListNotifier, AsyncValue<List<ShiftRosterItem>>>((ref) => ShiftRosterListNotifier(ref.read(dioProvider)));

class ShiftRosterListNotifier extends StateNotifier<AsyncValue<List<ShiftRosterItem>>> {
  final dynamic _dio;
  ShiftRosterListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/shift-rosters/');
      state = AsyncValue.data((r.data as List).map((e) => ShiftRosterItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/shift-rosters/', data: data);
    if (state.value != null) state = AsyncValue.data([ShiftRosterItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/shift-rosters/$id', data: data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((g) => g.id == id ? ShiftRosterItem.fromJson(r.data) : g).toList());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/shift-rosters/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((g) => g.id != id).toList());
  }
}

class ShiftRosterScreen extends ConsumerWidget {
  const ShiftRosterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rostersAsync = ref.watch(shiftRosterListProvider);
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Shift Rosters'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))],
      ),
      body: rostersAsync.when(
        data: (rosters) {
          if (rosters.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.calendar_month_outlined, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Shift Rosters', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Create rotation patterns for shift scheduling', style: ApexTypography.body.copyWith(color: _muted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _showDialog(context, ref), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Add Roster')),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: rosters.length, itemBuilder: (context, i) {
            final r = rosters[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month, color: _primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${r.rotationPattern.toUpperCase()} | WO: ${days[r.weeklyOff1]}${r.weeklyOff2 != null ? ', ${days[r.weeklyOff2!]} (${r.weeklyOff2Week})' : ''}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: r.isActive ? _success.withOpacity(0.1) : _muted.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(r.isActive ? 'ACTIVE' : 'INACTIVE', style: ApexTypography.captionSmall.copyWith(color: r.isActive ? _success : _muted, fontWeight: FontWeight.w600))),
              PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, roster: r); if (v == 'delete') _confirmDelete(context, ref, r.id, r.name); }),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {ShiftRosterItem? roster}) {
    final nameCtrl = TextEditingController(text: roster?.name ?? '');
    final descCtrl = TextEditingController(text: roster?.description ?? '');
    String pattern = roster?.rotationPattern ?? 'weekly';
    int wo1 = roster?.weeklyOff1 ?? 6;
    int? wo2 = roster?.weeklyOff2;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(roster != null ? 'Edit Roster' : 'Add Roster'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: pattern, decoration: const InputDecoration(labelText: 'Rotation Pattern', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'daily', child: Text('Daily')),
          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
        ], onChanged: (v) => setS(() => pattern = v ?? 'weekly')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(value: wo1, decoration: const InputDecoration(labelText: 'Weekly Off 1', border: OutlineInputBorder()), items: [for (int i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]))], onChanged: (v) => setS(() => wo1 = v ?? 6))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(value: wo2, decoration: const InputDecoration(labelText: 'Weekly Off 2', border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('None')), for (int i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]))], onChanged: (v) => setS(() => wo2 = v))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final data = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'rotation_pattern': pattern, 'weekly_off_1': wo1, 'weekly_off_2': wo2, 'weekly_off_2_week': 'every'};
          final notifier = ref.read(shiftRosterListProvider.notifier);
          if (roster != null) { await notifier.update(roster.id, data); } else { await notifier.add(data); }
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: Text(roster != null ? 'Update' : 'Add')),
      ],
    )));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Roster'), content: Text('Delete "$name"?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { ref.read(shiftRosterListProvider.notifier).delete(id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white), child: const Text('Delete')),
    ]));
  }
}
