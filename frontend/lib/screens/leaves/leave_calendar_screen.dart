import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';


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
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
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
            const Text('Upcoming Holidays', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
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

                if (upcoming.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No upcoming holidays', style: TextStyle(color: ApexColors.neutral500))));

                return Column(
                  children: upcoming.map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: ApexColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getDay(h['date']), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ApexColors.primary)),
                              Text(_getMonth(h['date']), style: TextStyle(fontSize: 10, color: ApexColors.primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                        Text(h['type'] ?? 'Company', style: TextStyle(fontSize: 12, color: ApexColors.neutral500)),
                      ])),
                      Text(_getWeekday(h['date']), style: TextStyle(fontSize: 12, color: ApexColors.neutral500)),
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
        Text(DateFormat('MMMM yyyy').format(month), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
          child: Column(
            children: [
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
                  Expanded(child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ApexColors.neutral500)),
                  )))
                ).toList(),
              ),
              const Divider(height: 1, color: ApexColors.neutral200),
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
                      color: holiday != null ? ApexColors.primary.withOpacity(0.08) : (isSunday ? ApexColors.error.withOpacity(0.03) : null),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: ApexColors.primary, width: 2) : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: holiday != null ? ApexColors.primary : (isSunday ? ApexColors.error : ApexColors.neutral900),
                          )),
                          if (holiday != null)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: ApexColors.primary, shape: BoxShape.circle),
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




