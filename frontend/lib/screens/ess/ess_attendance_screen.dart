import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final essAttendanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/attendance');
  return res.data is List ? res.data : [];
});

class EssAttendanceScreen extends ConsumerWidget {
  const EssAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(essAttendanceProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('My Attendance', style: ApexTypography.cardTitle),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [
          TextButton.icon(
            onPressed: () => _clockIn(context, ref),
            icon: Icon(Icons.login, size: 16, color: ApexColors.success),
            label: Text('Clock In', style: ApexTypography.body.copyWith(color: ApexColors.success)),
          ),
          TextButton.icon(
            onPressed: () => _clockOut(context, ref),
            icon: Icon(Icons.logout, size: 16, color: ApexColors.error),
            label: Text('Clock Out', style: ApexTypography.body.copyWith(color: ApexColors.error)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: attAsync.when(
        data: (records) {
          if (records.isEmpty) return const EmptyState(
            icon: Icons.access_time_outlined,
            title: 'No Attendance Records',
            description: 'Your attendance history will appear here.',
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final r = records[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: ApexCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _statusColor(r['status']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text((r['date'] ?? '').substring(8, 10), style: ApexTypography.titleMedium.copyWith(color: _statusColor(r['status'])))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['date'] ?? '', style: ApexTypography.titleMedium),
                      Text('${r['punch_in'] ?? '—'} → ${r['punch_out'] ?? '—'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _statusBadge(r['status']),
                      if (r['total_hours'] != null) ...[
                        const SizedBox(height: 4),
                        Text('${r['total_hours']}h', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ]),
                  ]),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => CustomErrorWidget(
          errorMessage: e.toString(),
          onRetry: () => ref.invalidate(essAttendanceProvider),
        ),
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'present') return ApexBadge.success(s.toUpperCase());
    if (s == 'absent') return ApexBadge.danger(s.toUpperCase());
    if (s == 'late') return ApexBadge.warning(s.toUpperCase());
    return ApexBadge(label: (status ?? '').toUpperCase(), type: ApexBadgeType.neutral);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return ApexColors.success;
      case 'absent': return ApexColors.error;
      case 'late': return ApexColors.warning;
      default: return ApexColors.neutral500;
    }
  }

  void _clockIn(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-in');
      ref.invalidate(essAttendanceProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clocked in!'), backgroundColor: ApexColors.success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: ApexColors.error));
    }
  }

  void _clockOut(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-out');
      ref.invalidate(essAttendanceProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clocked out!'), backgroundColor: ApexColors.success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: ApexColors.error));
    }
  }
}

