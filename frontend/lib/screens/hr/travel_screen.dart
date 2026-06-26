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

class TravelItem {
  final String id, employeeId, destination, status;
  final String? purpose;
  final DateTime fromDate, toDate;
  final double estimatedCost;
  TravelItem({required this.id, required this.employeeId, required this.destination, required this.status, this.purpose, required this.fromDate, required this.toDate, required this.estimatedCost});
  factory TravelItem.fromJson(Map<String, dynamic> json) => TravelItem(id: json['id'], employeeId: json['employee_id'], destination: json['destination'], status: json['status'] ?? 'pending', purpose: json['purpose'], fromDate: DateTime.parse(json['from_date']), toDate: DateTime.parse(json['to_date']), estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0);
}

final travelListProvider = StateNotifierProvider<TravelListNotifier, AsyncValue<List<TravelItem>>>((ref) => TravelListNotifier(ref.read(dioProvider)));

class TravelListNotifier extends StateNotifier<AsyncValue<List<TravelItem>>> {
  final dynamic _dio;
  TravelListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/hr/travel');
      state = AsyncValue.data((r.data as List).map((e) => TravelItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/hr/travel', data: data);
    if (state.value != null) state = AsyncValue.data([TravelItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> approve(String id) async {
    await _dio.put('/hr/travel/$id', data: {'status': 'approved'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((t) => t.id == id ? TravelItem(id: t.id, employeeId: t.employeeId, destination: t.destination, status: 'approved', purpose: t.purpose, fromDate: t.fromDate, toDate: t.toDate, estimatedCost: t.estimatedCost) : t).toList());
  }
}

class TravelScreen extends ConsumerWidget {
  const TravelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelAsync = ref.watch(travelListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(title: 'Travel Requests', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))]),
      body: travelAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.flight, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Travel Requests', style: ApexTypography.headingMedium.copyWith(color: _text)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final t = items[i];
            final statusColor = t.status == 'approved' ? _success : t.status == 'rejected' ? _danger : _warning;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.flight, color: _primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.destination, style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${DateFormat('MMM dd').format(t.fromDate)} - ${DateFormat('MMM dd, yyyy').format(t.toDate)}${t.purpose != null ? ' • ${t.purpose}' : ''}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${t.estimatedCost.toStringAsFixed(0)}', style: ApexTypography.titleSmall.copyWith(color: _text)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
              ]),
              if (t.status == 'pending') IconButton(icon: const Icon(Icons.check, size: 18, color: _success), onPressed: () => ref.read(travelListProvider.notifier).approve(t.id)),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final destCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('New Travel Request'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: destCtrl, decoration: const InputDecoration(labelText: 'Destination *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: InkWell(onTap: () async { final p = await showDatePicker(context: ctx, initialDate: fromDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setS(() => fromDate = p); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()), child: Text(DateFormat('MMM dd').format(fromDate))))),
          const SizedBox(width: 12),
          Expanded(child: InkWell(onTap: () async { final p = await showDatePicker(context: ctx, initialDate: toDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setS(() => toDate = p); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()), child: Text(DateFormat('MMM dd').format(toDate))))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Estimated Cost', border: OutlineInputBorder(), prefixText: '₹'), keyboardType: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (destCtrl.text.trim().isEmpty) return;
          await ref.read(travelListProvider.notifier).add({'employee_id': '00000000-0000-0000-0000-000000000000', 'destination': destCtrl.text.trim(), 'purpose': purposeCtrl.text.trim(), 'from_date': fromDate.toIso8601String().substring(0, 10), 'to_date': toDate.toIso8601String().substring(0, 10), 'estimated_cost': double.tryParse(costCtrl.text) ?? 0});
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Submit')),
      ],
    )));
  }
}
