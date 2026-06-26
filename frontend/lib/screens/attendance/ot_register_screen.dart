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

class OTItem {
  final String id, employeeId, otType, status;
  final DateTime date;
  final double otHours;
  final String? remarks;
  OTItem({required this.id, required this.employeeId, required this.date, required this.otHours, required this.otType, required this.status, this.remarks});
  factory OTItem.fromJson(Map<String, dynamic> json) => OTItem(id: json['id'], employeeId: json['employee_id'], date: DateTime.parse(json['date'].toString()), otHours: (json['ot_hours'] as num).toDouble(), otType: json['ot_type'] ?? 'normal', status: json['status'] ?? 'pending', remarks: json['remarks']);
}

final otListProvider = StateNotifierProvider<OTListNotifier, AsyncValue<List<OTItem>>>((ref) => OTListNotifier(ref.read(dioProvider)));

class OTListNotifier extends StateNotifier<AsyncValue<List<OTItem>>> {
  final dynamic _dio;
  OTListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/ot-register/');
      state = AsyncValue.data((r.data as List).map((e) => OTItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> approve(String id) async {
    await _dio.put('/ot-register/$id', data: {'status': 'approved'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((o) => o.id == id ? OTItem(id: o.id, employeeId: o.employeeId, date: o.date, otHours: o.otHours, otType: o.otType, status: 'approved', remarks: o.remarks) : o).toList());
  }

  Future<void> preserve(String id) async {
    await _dio.put('/ot-register/$id', data: {'status': 'preserved'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((o) => o.id == id ? OTItem(id: o.id, employeeId: o.employeeId, date: o.date, otHours: o.otHours, otType: o.otType, status: 'preserved', remarks: o.remarks) : o).toList());
  }
}

class OTRegisterScreen extends ConsumerWidget {
  const OTRegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otAsync = ref.watch(otListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('OT Register'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: otAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.access_time_filled, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No OT Records', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Overtime records will appear here', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final o = items[i];
            final statusColor = o.status == 'approved' ? _success : o.status == 'preserved' ? _primary : o.status == 'rejected' ? _danger : _warning;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.access_time_filled, color: statusColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('MMM dd, yyyy').format(o.date), style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${o.otHours.toStringAsFixed(1)}h • ${o.otType}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(o.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
              if (o.status == 'pending') ...[
                IconButton(icon: const Icon(Icons.check, size: 18, color: _success), onPressed: () => ref.read(otListProvider.notifier).approve(o.id)),
                IconButton(icon: const Icon(Icons.lock, size: 18, color: _primary), onPressed: () => ref.read(otListProvider.notifier).preserve(o.id)),
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
