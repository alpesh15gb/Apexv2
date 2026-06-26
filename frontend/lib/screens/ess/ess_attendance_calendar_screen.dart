import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _clockingIn ? null : () => _clockIn(context),
              icon: _clockingIn
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login, size: 16),
              label: const Text('Clock In'),
              style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _clockOut(context),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Clock Out'),
              style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
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
            const Text('Daily Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            attAsync.when(
              data: (records) {
                if (records.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No attendance records this month', style: TextStyle(color: _muted))));
                return Column(
                  children: records.map((r) => _DailyLogCard(record: r)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: _danger)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in successfully!'), backgroundColor: _success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out successfully!'), backgroundColor: _success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
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
        final checkIn = att?['check_in'];
        final checkOut = att?['check_out';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primary, _primary.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusText(status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
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
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Text(DateFormat('MMMM yyyy').format(month), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
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

        return Container(
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: Column(
            children: [
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
                  Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted))))
                ).toList(),
              ),
              const Divider(height: 1, color: _border),
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
                      color: _dayColor(status).withOpacity(status != null ? 0.1 : 0),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: _primary, width: 2) : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday ? _primary : _text,
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
      error: (e, _) => Text('Error: $e'),
    );
  }

  Color _dayColor(String? status) {
    switch (status) {
      case 'present': return _success;
      case 'absent': return _danger;
      case 'late': return _warning;
      case 'half_day': return const Color(0xFFF59E0B);
      case 'on_leave': return _primary;
      default: return _muted;
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
    final checkIn = record['check_in'];
    final checkOut = record['check_out'];
    final hours = record['working_hours'];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(date.length >= 10 ? date.substring(8, 10) : '?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _statusColor(status))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
              Text('${_formatTime(checkIn)} → ${_formatTime(checkOut)}', style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
            ),
            if (hours != null) ...[
              const SizedBox(height: 4),
              Text('${hours}h', style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          ],
        ),
      ]),
    );
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
      case 'present': return _success;
      case 'absent': return _danger;
      case 'late': return _warning;
      case 'half_day': return const Color(0xFFF59E0B);
      case 'on_leave': return _primary;
      default: return _muted;
    }
  }
}
