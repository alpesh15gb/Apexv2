import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _warning = Color(0xFFF59E0B);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class ODItem {
  final String id, employeeId, status;
  final DateTime date;
  final String? reason, location, fromTime, toTime;
  ODItem({required this.id, required this.employeeId, required this.status, required this.date, this.reason, this.location, this.fromTime, this.toTime});
  factory ODItem.fromJson(Map<String, dynamic> json) => ODItem(id: json['id'], employeeId: json['employee_id'], status: json['status'] ?? 'pending', date: DateTime.parse(json['date'].toString()), reason: json['reason'], location: json['location'], fromTime: json['from_time']?.toString(), toTime: json['to_time']?.toString());
}

final odListProvider = StateNotifierProvider<ODListNotifier, AsyncValue<List<ODItem>>>((ref) => ODListNotifier(ref.read(dioProvider)));

class ODListNotifier extends StateNotifier<AsyncValue<List<ODItem>>> {
  final dynamic _dio;
  ODListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/outdoor-duties/');
      state = AsyncValue.data((r.data as List).map((e) => ODItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> approve(String id) async {
    await _dio.put('/outdoor-duties/$id', data: {'status': 'approved'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((o) => o.id == id ? ODItem(id: o.id, employeeId: o.employeeId, status: 'approved', date: o.date, reason: o.reason, location: o.location) : o).toList());
  }

  Future<void> reject(String id) async {
    await _dio.put('/outdoor-duties/$id', data: {'status': 'rejected'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((o) => o.id == id ? ODItem(id: o.id, employeeId: o.employeeId, status: 'rejected', date: o.date, reason: o.reason, location: o.location) : o).toList());
  }
}

class OutdoorDutyScreen extends ConsumerWidget {
  const OutdoorDutyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final odAsync = ref.watch(odListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Outdoor Duty'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: odAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.directions_walk, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Outdoor Duty Entries', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('OD entries will appear here when created', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final o = items[i];
            final statusColor = o.status == 'approved' ? _success : o.status == 'rejected' ? _danger : _warning;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.directions_walk, color: statusColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('MMM dd, yyyy').format(o.date), style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${o.reason ?? 'No reason'}${o.location != null ? ' • ${o.location}' : ''}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(o.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
              if (o.status == 'pending') ...[
                IconButton(icon: const Icon(Icons.check, size: 18, color: _success), onPressed: () => ref.read(odListProvider.notifier).approve(o.id)),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _danger), onPressed: () => ref.read(odListProvider.notifier).reject(o.id)),
              ],
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
