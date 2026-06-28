import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/page_wrapper.dart';

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
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Outdoor Duty',
        description: 'Track and approve out-of-office client visits or site assignments.',
        onRefresh: () => ref.read(odListProvider.notifier).fetch(isRefresh: true),
        body: odAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.directions_walk, size: 48, color: ApexColors.neutral400),
                const SizedBox(height: 16),
                Text('No Outdoor Duty Entries', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 8),
                Text('OD entries will appear here when created', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
              ]));
            }
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
              final o = items[i];
              final badge = o.status == 'approved' ? ApexBadge.success('APPROVED') : o.status == 'rejected' ? ApexBadge.danger('REJECTED') : ApexBadge.warning('PENDING');
              final statusColor = o.status == 'approved' ? ApexColors.success : o.status == 'rejected' ? ApexColors.error : ApexColors.warning;
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
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.directions_walk, color: statusColor, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat('MMM dd, yyyy').format(o.date), style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                      Text('${o.reason ?? 'No reason'}${o.location != null ? ' • ${o.location}' : ''}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    ])),
                    badge,
                    if (o.status == 'pending') ...[
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.check, size: 18, color: ApexColors.success), onPressed: () => ref.read(odListProvider.notifier).approve(o.id)),
                      IconButton(icon: const Icon(Icons.close, size: 18, color: ApexColors.error), onPressed: () => ref.read(odListProvider.notifier).reject(o.id)),
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
