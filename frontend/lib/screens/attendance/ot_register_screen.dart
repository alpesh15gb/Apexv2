import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/page_wrapper.dart';

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
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'OT Register',
        description: 'Track and verify overtime check-in hours and pay multipliers.',
        onRefresh: () => ref.read(otListProvider.notifier).fetch(isRefresh: true),
        body: otAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.access_time_filled, size: 48, color: ApexColors.neutral400),
                const SizedBox(height: 16),
                Text('No OT Records', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 8),
                Text('Overtime records will appear here', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
              ]));
            }
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
              final o = items[i];
              final badge = o.status == 'approved' ? ApexBadge.success('APPROVED') : o.status == 'preserved' ? ApexBadge.info('PRESERVED') : o.status == 'rejected' ? ApexBadge.danger('REJECTED') : ApexBadge.warning('PENDING');
              final statusColor = o.status == 'approved' ? ApexColors.success : o.status == 'preserved' ? ApexColors.primary : o.status == 'rejected' ? ApexColors.error : ApexColors.warning;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ApexColors.neutral200),
                  ),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.access_time_filled, color: statusColor, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat('MMM dd, yyyy').format(o.date), style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                      Text('${o.otHours.toStringAsFixed(1)}h • ${o.otType}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    ])),
                    badge,
                    if (o.status == 'pending') ...[
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.check, size: 18, color: ApexColors.success), onPressed: () => ref.read(otListProvider.notifier).approve(o.id)),
                      IconButton(icon: const Icon(Icons.lock, size: 18, color: ApexColors.primary), onPressed: () => ref.read(otListProvider.notifier).preserve(o.id)),
                    ],
                  ]),
                ),
              );
            });
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
