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

final holidayListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/holidays/', queryParameters: {'year': DateTime.now().year});
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

final leaveBalanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/ess/leaves/balance');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class LeaveCalendarScreen extends ConsumerStatefulWidget {
  const LeaveCalendarScreen({super.key});
  @override
  ConsumerState<LeaveCalendarScreen> createState() => _LeaveCalendarScreenState();
}

class _LeaveCalendarScreenState extends ConsumerState<LeaveCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidayListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Leave Calendar', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarHeader(
              month: _selectedMonth,
              onPrev: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
              onNext: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
            ),
            const SizedBox(height: 8),
            _CalendarGrid(month: _selectedMonth, holidaysAsync: holidaysAsync),
            const SizedBox(height: 24),
            const Text('Upcoming Holidays', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            holidaysAsync.when(
              data: (holidays) {
                final upcoming = holidays.where((h) {
                  try {
                    final d = DateTime.parse(h['date'].toString());
                    return d.isAfter(DateTime.now());
                  } catch (_) {
                    return false;
                  }
                }).toList();

                if (upcoming.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No upcoming holidays', style: TextStyle(color: _muted))));

                return Column(
                  children: upcoming.map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getDay(h['date']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                              Text(_getMonth(h['date']), style: const TextStyle(fontSize: 10, color: _primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                        Text(h['type'] ?? 'Company', style: const TextStyle(fontSize: 12, color: _muted)),
                      ])),
                      Text(_getWeekday(h['date']), style: const TextStyle(fontSize: 12, color: _muted)),
                    ]),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDay(dynamic date) {
    try { return DateTime.parse(date.toString()).day.toString(); } catch (_) { return '?'; }
  }

  String _getMonth(dynamic date) {
    try { return DateFormat('MMM').format(DateTime.parse(date.toString())); } catch (_) { return ''; }
  }

  String _getWeekday(dynamic date) {
    try { return DateFormat('EEEE').format(DateTime.parse(date.toString())); } catch (_) { return ''; }
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
  final AsyncValue<List<dynamic>> holidaysAsync;

  const _CalendarGrid({required this.month, required this.holidaysAsync});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = lastDay.day;

    return holidaysAsync.when(
      data: (holidays) {
        final holidayMap = <String, String>{};
        for (final h in holidays) {
          try {
            final d = h['date'].toString().substring(0, 10);
            holidayMap[d] = h['name'] ?? 'Holiday';
          } catch (_) {}
        }

        return Container(
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: Column(
            children: [
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
                  Expanded(child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
                  )))
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
                  final holiday = holidayMap[dateStr];
                  final isToday = day == DateTime.now().day && month.month == DateTime.now().month && month.year == DateTime.now().year;
                  final isSunday = (startWeekday + i) % 7 == 6;

                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: holiday != null ? _primary.withOpacity(0.08) : (isSunday ? _danger.withOpacity(0.03) : null),
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
                            color: holiday != null ? _primary : (isSunday ? _danger : _text),
                          )),
                          if (holiday != null)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
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
}
