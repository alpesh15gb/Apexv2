import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/attendance_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../services/attendance_service.dart';

class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
      ),
      body: Column(
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Summary Stats Content
          Expanded(
            child: summaryAsync.when(
              data: (summary) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatRow('Present', '${summary.present}', Icons.check_circle_outline, Colors.green),
                  _buildStatRow('Absent', '${summary.absent}', Icons.cancel_outlined, Colors.red),
                  _buildStatRow('Late Arrival', '${summary.late}', Icons.access_time, Colors.orange),
                  _buildStatRow('Half Day', '${summary.halfDay}', Icons.hourglass_bottom, Colors.blue),
                  _buildStatRow('On Leave', '${summary.onLeave}', Icons.work_off_outlined, Colors.purple),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final service = ref.read(attendanceServiceProvider);
                        await service.processAttendance(dateStr);
                        ref.invalidate(dailySummaryProvider(dateStr));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processed daily logs successfully'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.build_circle_outlined),
                    label: const Text('Process Attendance for this Day'),
                  ),
                ],
              ),
              loading: () => const LoadingWidget(count: 3),
              error: (err, stack) => CustomErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.invalidate(dailySummaryProvider(dateStr)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
