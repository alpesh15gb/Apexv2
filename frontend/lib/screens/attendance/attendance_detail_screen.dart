import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/attendance_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/status_badge.dart';

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

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Range Header
            Text(
              'History Summary (${DateFormat('MMMM yyyy').format(now)})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                childAspectRatio: 1.8,
                children: [
                  _buildSummaryMiniCard('Present Days', '${summary.presentDays}/${summary.totalDays}', Colors.green),
                  _buildSummaryMiniCard('Absent Days', '${summary.absentDays}', Colors.red),
                  _buildSummaryMiniCard('Late Days', '${summary.lateDays}', Colors.orange),
                  _buildSummaryMiniCard('Total Hours', '${summary.totalHours.toStringAsFixed(1)} hrs', Colors.blue),
                ],
              ),
              loading: () => const LoadingWidget(count: 1),
              error: (err, stack) => Center(child: Text('Summary Error: ${err.toString()}')),
            ),
            const SizedBox(height: 24),

            // Raw Punch Logs
            Text(
              'Raw Biometric Punch Logs',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            punchLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No biometric punch logs found.')),
                    ),
                  );
                }
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final log = logs[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                          child: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                        ),
                        title: Text('Punched at: ${DateFormat('hh:mm a').format(log.timestamp)}'),
                        subtitle: Text('Date: ${DateFormat('MMM dd, yyyy').format(log.timestamp)} • Source: ${log.source}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingWidget(count: 3),
              error: (err, stack) => Center(child: Text('Logs Error: ${err.toString()}')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
