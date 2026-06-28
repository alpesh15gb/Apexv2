import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

class ExitItem {
  final String id, employeeId, status, clearanceStatus;
  final DateTime resignationDate;
  final DateTime? lastWorkingDate;
  final String? reason, exitInterviewNotes;
  ExitItem({required this.id, required this.employeeId, required this.status, required this.clearanceStatus, required this.resignationDate, this.lastWorkingDate, this.reason, this.exitInterviewNotes});
  factory ExitItem.fromJson(Map<String, dynamic> json) => ExitItem(id: json['id'], employeeId: json['employee_id'], status: json['status'] ?? 'pending', clearanceStatus: json['clearance_status'] ?? 'pending', resignationDate: DateTime.parse(json['resignation_date']), lastWorkingDate: json['last_working_date'] != null ? DateTime.parse(json['last_working_date']) : null, reason: json['reason'], exitInterviewNotes: json['exit_interview_notes']);
}

final exitListProvider = StateNotifierProvider<ExitListNotifier, AsyncValue<List<ExitItem>>>((ref) => ExitListNotifier(ref.read(dioProvider)));

class ExitListNotifier extends StateNotifier<AsyncValue<List<ExitItem>>> {
  final dynamic _dio;
  ExitListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/exit-requests/');
      state = AsyncValue.data((r.data as List).map((e) => ExitItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> approve(String id) async {
    await _dio.put('/exit-requests/$id', data: {'status': 'approved'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((e) => e.id == id ? ExitItem(id: e.id, employeeId: e.employeeId, status: 'approved', clearanceStatus: e.clearanceStatus, resignationDate: e.resignationDate, lastWorkingDate: e.lastWorkingDate, reason: e.reason) : e).toList());
  }

  Future<void> reject(String id) async {
    await _dio.put('/exit-requests/$id', data: {'status': 'rejected'});
    if (state.value != null) state = AsyncValue.data(state.value!.map((e) => e.id == id ? ExitItem(id: e.id, employeeId: e.employeeId, status: 'rejected', clearanceStatus: e.clearanceStatus, resignationDate: e.resignationDate, lastWorkingDate: e.lastWorkingDate, reason: e.reason) : e).toList());
  }
}

ApexBadgeType _statusBadge(String status) {
  if (status == 'approved') return ApexBadgeType.success;
  if (status == 'rejected') return ApexBadgeType.danger;
  return ApexBadgeType.warning;
}

Color _statusColor(String status) {
  if (status == 'approved') return ApexColors.success;
  if (status == 'rejected') return ApexColors.error;
  return ApexColors.warning;
}

class ExitRequestScreen extends ConsumerWidget {
  const ExitRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exitsAsync = ref.watch(exitListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Exit Requests'),
      body: exitsAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.exit_to_app, size: 48, color: ApexColors.neutral400),
            const SizedBox(height: 16),
            Text('No Exit Requests', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final e = items[i];
            final statusColor = _statusColor(e.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ApexCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.exit_to_app, color: statusColor, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Resigned: ${DateFormat('MMM dd, yyyy').format(e.resignationDate)}', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                    Text('Last Working: ${e.lastWorkingDate != null ? DateFormat('MMM dd, yyyy').format(e.lastWorkingDate!) : 'TBD'} • Clearance: ${e.clearanceStatus}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    if (e.reason != null && e.reason!.isNotEmpty) Text(e.reason!, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  Column(children: [
                    ApexBadge(label: e.status, type: _statusBadge(e.status)),
                    if (e.status == 'pending') Row(children: [
                      IconButton(icon: Icon(Icons.check, size: 18, color: ApexColors.success), onPressed: () => ref.read(exitListProvider.notifier).approve(e.id)),
                      IconButton(icon: Icon(Icons.close, size: 18, color: ApexColors.error), onPressed: () => ref.read(exitListProvider.notifier).reject(e.id)),
                    ]),
                  ]),
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
}
