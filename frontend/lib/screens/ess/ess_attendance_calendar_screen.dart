import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

final essAttendanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
  final to = now.toIso8601String().substring(0, 10);
  final res = await dio.get('/ess/attendance', queryParameters: {'from_date': from, 'to_date': to});
  return res.data is List ? res.data : [];
});

final essShiftProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/ess/dashboard');
    return res.data;
  } catch (e) {
    return null;
  }
});

class EssAttendanceCalendarScreen extends ConsumerStatefulWidget {
  const EssAttendanceCalendarScreen({super.key});
  @override
  ConsumerState<EssAttendanceCalendarScreen> createState() => _EssAttendanceCalendarScreenState();
}

class _EssAttendanceCalendarScreenState extends ConsumerState<EssAttendanceCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _clockingIn = false;

  @override
  Widget build(BuildContext context) {
    final attAsync = ref.watch(essAttendanceProvider);
    final dashAsync = ref.watch(essShiftProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('My Attendance', style: ApexTypography.cardTitle),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ApexButton(
              label: 'Clock In',
              onPressed: _clockingIn ? null : () => _clockIn(context),
              type: ApexButtonType.success,
              icon: Icons.login,
              loading: _clockingIn,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ApexButton(
              label: 'Clock Out',
              onPressed: () => _clockOut(context),
              type: ApexButtonType.danger,
              icon: Icons.logout,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayCard(dashAsync: dashAsync),
            const SizedBox(height: 16),
            _CalendarHeader(
              month: _selectedMonth,
              onPrev: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
              onNext: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
            ),
            const SizedBox(height: 8),
            _CalendarGrid(month: _selectedMonth, attAsync: attAsync),
            const SizedBox(height: 24),
            Text('Daily Logs', style: ApexTypography.titleLarge),
            const SizedBox(height: 8),
            attAsync.when(
              data: (records) {
                if (records.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No attendance records this month', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))));
                return Column(
                  children: records.map((r) => _DailyLogCard(record: r)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  void _clockIn(BuildContext context) async {
    setState(() => _clockingIn = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-in');
      ref.invalidate(essAttendanceProvider);
      ref.invalidate(essShiftProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clocked in successfully!'), backgroundColor: ApexColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: ApexColors.error));
    } finally {
      if (mounted) setState(() => _clockingIn = false);
    }
  }

  void _clockOut(BuildContext context) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ess/attendance/clock-out');
      ref.invalidate(essAttendanceProvider);
      ref.invalidate(essShiftProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clocked out successfully!'), backgroundColor: ApexColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: ApexColors.error));
    }
  }
}

class _TodayCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> dashAsync;
  const _TodayCard({required this.dashAsync});

  @override
  Widget build(BuildContext context) {
    return dashAsync.when(
      data: (dash) {
        final att = dash?['today_attendance'];
        final status = att?['status'] ?? 'not_marked';
        final checkIn = att?['punch_in'];
        final checkOut = att?['punch_out'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [ApexColors.primary600, ApexColors.primary600.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: ApexTypography.body.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _timeBlock('Clock In', checkIn ?? '--:--', Icons.login),
                  const SizedBox(width: 32),
                  _timeBlock('Clock Out', checkOut ?? '--:--', Icons.logout),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusText(status), style: ApexTypography.titleMedium.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _timeBlock(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: ApexTypography.captionSmall.copyWith(color: Colors.white70)),
        ]),
        const SizedBox(height: 4),
        Text(time, style: ApexTypography.sectionTitle.copyWith(fontSize: 22, color: Colors.white)),
      ],
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'present': return 'Present';
      case 'absent': return 'Absent';
      case 'late': return 'Late';
      case 'half_day': return 'Half Day';
      case 'on_leave': return 'On Leave';
      default: return 'Not Marked';
    }
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarHeader({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: Icon(Icons.chevron_left, color: ApexColors.neutral700), onPressed: onPrev),
        Text(DateFormat('MMMM yyyy').format(month), style: ApexTypography.cardTitle),
        IconButton(icon: Icon(Icons.chevron_right, color: ApexColors.neutral700), onPressed: onNext),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final AsyncValue<List<dynamic>> attAsync;

  const _CalendarGrid({required this.month, required this.attAsync});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = lastDay.day;

    return attAsync.when(
      data: (records) {
        final attendanceMap = <String, String>{};
        for (final r in records) {
          final dateStr = r['date']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            attendanceMap[dateStr.substring(0, 10)] = r['status'] ?? 'unknown';
          }
        }

        return ApexCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
                  Expanded(child: Center(child: Text(d, style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500))))
                ).toList(),
              ),
              Divider(height: 1, color: ApexColors.neutral200),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                itemCount: startWeekday + totalDays,
                itemBuilder: (context, i) {
                  if (i < startWeekday) return const SizedBox.shrink();
                  final day = i - startWeekday + 1;
                  final dateStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                  final status = attendanceMap[dateStr];
                  final isToday = day == DateTime.now().day && month.month == DateTime.now().month && month.year == DateTime.now().year;

                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _dayColor(status).withValues(alpha: status != null ? 0.1 : 0),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: ApexColors.primary600, width: 2) : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: ApexTypography.caption.copyWith(
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday ? ApexColors.primary600 : ApexColors.neutral900,
                          )),
                          if (status != null)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: _dayColor(status), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
    );
  }

  Color _dayColor(String? status) {
    switch (status) {
      case 'present': return ApexColors.success;
      case 'absent': return ApexColors.error;
      case 'late': return ApexColors.warning;
      case 'half_day': return ApexColors.warning;
      case 'on_leave': return ApexColors.primary600;
      default: return ApexColors.neutral500;
    }
  }
}

class _DailyLogCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _DailyLogCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] ?? 'unknown';
    final date = record['date'] ?? '';
    final checkIn = record['punch_in'];
    final checkOut = record['punch_out'];
    final hours = record['total_hours'];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ApexCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(date.length >= 10 ? date.substring(8, 10) : '?', style: ApexTypography.titleMedium.copyWith(color: _statusColor(status))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: ApexTypography.titleMedium),
                Text('${_formatTime(checkIn)} → ${_formatTime(checkOut)}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusBadge(status),
              if (hours != null) ...[
                const SizedBox(height: 4),
                Text('${hours}h', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
              ],
            ],
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    if (s == 'present') return ApexBadge.success(s.toUpperCase());
    if (s == 'absent') return ApexBadge.danger(s.toUpperCase());
    if (s == 'late') return ApexBadge.warning(s.toUpperCase());
    if (s == 'half_day') return ApexBadge.warning(s.toUpperCase());
    if (s == 'on_leave') return ApexBadge.info(s.toUpperCase());
    return ApexBadge(label: s.toUpperCase(), type: ApexBadgeType.neutral);
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return time.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return ApexColors.success;
      case 'absent': return ApexColors.error;
      case 'late': return ApexColors.warning;
      case 'half_day': return ApexColors.warning;
      case 'on_leave': return ApexColors.primary600;
      default: return ApexColors.neutral500;
    }
  }
}

