import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/page_wrapper.dart';

class AttendanceDetailScreen extends ConsumerWidget {
  final String employeeId;

  const AttendanceDetailScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final fromDateStr = firstDayOfMonth.toIso8601String().substring(0, 10);
    final toDateStr = now.toIso8601String().substring(0, 10);

    final summaryAsync = ref.watch(employeeSummaryProvider({
      'employeeId': employeeId,
      'fromDate': fromDateStr,
      'toDate': toDateStr,
    }));

    final punchLogsAsync = ref.watch(punchLogsProvider({
      'employeeId': employeeId,
      'fromDate': fromDateStr,
      'toDate': toDateStr,
    }));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee Attendance History',
        description: 'Monthly summary analytics and raw biometric punch-in feeds.',
        onRefresh: () {
          ref.invalidate(employeeSummaryProvider({
            'employeeId': employeeId,
            'fromDate': fromDateStr,
            'toDate': toDateStr,
          }));
          ref.invalidate(punchLogsProvider({
            'employeeId': employeeId,
            'fromDate': fromDateStr,
            'toDate': toDateStr,
          }));
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History Summary (${DateFormat('MMMM yyyy').format(now)})',
                style: ApexTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Attendance Summary Cards
              summaryAsync.when(
                data: (summary) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildSummaryMiniCard('Present Days', '${summary.presentDays}/${summary.totalDays}', ApexColors.success),
                    _buildSummaryMiniCard('Absent Days', '${summary.absentDays}', ApexColors.error),
                    _buildSummaryMiniCard('Late Days', '${summary.lateDays}', ApexColors.warning),
                    _buildSummaryMiniCard('Total Hours', '${summary.totalHours.toStringAsFixed(1)} hrs', ApexColors.primary),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Summary Error: ${err.toString()}', style: ApexTypography.body.copyWith(color: ApexColors.error))),
              ),
              const SizedBox(height: 24),

              Text(
                'Raw Biometric Punch Logs',
                style: ApexTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              punchLogsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return Container(
                      height: 100,
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: const Center(child: Text('No biometric punch logs found.')),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final log = logs[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ApexColors.primary.withOpacity(0.08),
                            child: const Icon(Icons.fingerprint, color: ApexColors.primary),
                          ),
                          title: Text('Punched at: ${DateFormat('hh:mm a').format(log.timestamp.toLocal())}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Text('Date: ${DateFormat('MMM dd, yyyy').format(log.timestamp.toLocal())} • Source: ${log.source}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Logs Error: ${err.toString()}', style: ApexTypography.body.copyWith(color: ApexColors.error))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, String value, Color color) {
    return ApexCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: ApexTypography.sectionTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
