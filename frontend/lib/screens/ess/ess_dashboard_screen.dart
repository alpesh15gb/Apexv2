import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

final essDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/dashboard');
  return Map<String, dynamic>.from(res.data);
});

class EssDashboardScreen extends ConsumerWidget {
  const EssDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(essDashboardProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'My Dashboard'),
      body: dashAsync.when(
        data: (dash) {
          final emp = dash['employee'] ?? {};
          final attendance = dash['today_attendance'];
          final balances = dash['leave_balances'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeCard(name: emp['name'] ?? 'Employee', code: emp['code'] ?? ''),
                const SizedBox(height: 16),
                _AttendanceCard(attendance: attendance),
                const SizedBox(height: 16),
                _QuickActions(),
                const SizedBox(height: 16),
                if (balances.isNotEmpty) ...[
                  Text('Leave Balance', style: ApexTypography.cardTitle),
                  const SizedBox(height: 8),
                  ...balances.map((b) => _LeaveBalanceCard(balance: b)),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => CustomErrorWidget(
          errorMessage: e.toString(),
          onRetry: () => ref.invalidate(essDashboardProvider),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final String code;
  const _WelcomeCard({required this.name, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ApexColors.primary600, ApexColors.primary800]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name', style: ApexTypography.sectionTitle.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Employee Code: $code', style: ApexTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final dynamic attendance;
  const _AttendanceCard({this.attendance});

  @override
  Widget build(BuildContext context) {
    final hasAttendance = attendance != null;
    final status = hasAttendance ? (attendance['status'] ?? 'not_marked') : 'not_marked';
    final checkIn = hasAttendance ? attendance['punch_in'] : null;
    final checkOut = hasAttendance ? attendance['punch_out'] : null;

    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: ApexColors.primary600),
              const SizedBox(width: 8),
              Text('Today\'s Attendance', style: ApexTypography.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _timeBlock('Clock In', _formatTime(checkIn))),
              Expanded(child: _timeBlock('Clock Out', _formatTime(checkOut))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    try {
      final dt = DateTime.parse(time.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time.toString();
    }
  }

  Widget _timeBlock(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
        const SizedBox(height: 4),
        Text(time, style: ApexTypography.titleMedium.copyWith(fontSize: 16)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return ApexColors.success;
      case 'absent': return ApexColors.error;
      case 'late': return ApexColors.warning;
      default: return ApexColors.neutral500;
    }
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: ApexTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(Icons.login, 'Clock In', ApexColors.success, () => _clockIn(context)),
              const SizedBox(width: 12),
              _actionBtn(Icons.logout, 'Clock Out', ApexColors.error, () => _clockOut(context)),
              const SizedBox(width: 12),
              _actionBtn(Icons.event_busy, 'Apply Leave', ApexColors.primary600, () => context.push('/leaves/apply')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(label, style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _clockIn(BuildContext context) async {
    // TODO: implement clock in
  }

  void _clockOut(BuildContext context) async {
    // TODO: implement clock out
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final Map<String, dynamic> balance;
  const _LeaveBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final total = (balance['total'] as num?)?.toDouble() ?? 0;
    final used = (balance['used'] as num?)?.toDouble() ?? 0;
    final available = (balance['available'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ApexCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(balance['type'] ?? 'Leave', style: ApexTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text('$used used of $total', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ApexColors.primary600.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${available.toInt()} left', style: ApexTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: ApexColors.primary600)),
            ),
          ],
        ),
      ),
    );
  }
}

