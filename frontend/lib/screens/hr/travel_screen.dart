import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

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

ApexBadgeType _statusBadge(String status) {
  if (status == 'approved') return ApexBadgeType.success;
  if (status == 'rejected') return ApexBadgeType.danger;
  return ApexBadgeType.warning;
}

class TravelScreen extends ConsumerWidget {
  const TravelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelAsync = ref.watch(travelListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(title: 'Travel Requests', actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))]),
      body: travelAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.flight, size: 48, color: ApexColors.neutral400),
            const SizedBox(height: 16),
            Text('No Travel Requests', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final t = items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ApexCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.flight, color: ApexColors.primary600, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.destination, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                    Text('${DateFormat('MMM dd').format(t.fromDate)} - ${DateFormat('MMM dd, yyyy').format(t.toDate)}${t.purpose != null ? ' • ${t.purpose}' : ''}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${t.estimatedCost.toStringAsFixed(0)}', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                    ApexBadge(label: t.status, type: _statusBadge(t.status)),
                  ]),
                  if (t.status == 'pending') IconButton(icon: Icon(Icons.check, size: 18, color: ApexColors.success), onPressed: () => ref.read(travelListProvider.notifier).approve(t.id)),
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
    final destCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text('New Travel Request', style: ApexTypography.sectionTitle),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ApexTextField(label: 'Destination', controller: destCtrl, required: true),
        const SizedBox(height: 12),
        ApexTextField(label: 'Purpose', controller: purposeCtrl),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ApexDatePicker(label: 'From', value: fromDate, onChanged: (p) { if (p != null) setS(() => fromDate = p); })),
          const SizedBox(width: 12),
          Expanded(child: ApexDatePicker(label: 'To', value: toDate, onChanged: (p) { if (p != null) setS(() => toDate = p); })),
        ]),
        const SizedBox(height: 12),
        ApexTextField(label: 'Estimated Cost', controller: costCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.currency_rupee),
      ])),
      actions: [
        ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
        ApexButton(label: 'Submit', onPressed: () async {
          if (destCtrl.text.trim().isEmpty) return;
          await ref.read(travelListProvider.notifier).add({'employee_id': '00000000-0000-0000-0000-000000000000', 'destination': destCtrl.text.trim(), 'purpose': purposeCtrl.text.trim(), 'from_date': fromDate.toIso8601String().substring(0, 10), 'to_date': toDate.toIso8601String().substring(0, 10), 'estimated_cost': double.tryParse(costCtrl.text) ?? 0});
          if (ctx.mounted) Navigator.pop(ctx);
        }),
      ],
    )));
  }
}
