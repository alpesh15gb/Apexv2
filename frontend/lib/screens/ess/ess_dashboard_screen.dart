import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
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
                  const Text('Leave Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 8),
                  ...balances.map((b) => _LeaveBalanceCard(balance: b)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
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
        gradient: const LinearGradient(colors: [_primary, Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Employee Code: $code', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
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
    final checkIn = hasAttendance ? attendance['check_in'] : null;
    final checkOut = hasAttendance ? attendance['check_out'] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: _primary),
              const SizedBox(width: 8),
              const Text('Today\'s Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _timeBlock('Clock In', checkIn ?? '--:--')),
              Expanded(child: _timeBlock('Clock Out', checkOut ?? '--:--')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBlock(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return _success;
      case 'absent': return _danger;
      case 'late': return _warning;
      default: return _muted;
    }
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(Icons.login, 'Clock In', _success, () => _clockIn(context)),
              const SizedBox(width: 12),
              _actionBtn(Icons.logout, 'Clock Out', _danger, () => _clockOut(context)),
              const SizedBox(width: 12),
              _actionBtn(Icons.event_busy, 'Apply Leave', _primary, () => context.push('/leaves/apply')),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(balance['type'] ?? 'Leave', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 4),
                Text('$used used of $total', style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${available.toInt()} left', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
          ),
        ],
      ),
    );
  }
}
