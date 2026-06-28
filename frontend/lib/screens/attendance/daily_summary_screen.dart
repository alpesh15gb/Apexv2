import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_section.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Summary', style: ApexTypography.titleLarge.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ApexDatePicker(
              label: 'Select Date',
              value: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (v) { if (v != null) setState(() => _selectedDate = v); },
            ),
          ),
          const Divider(height: 1),

          // Summary Stats Content
          Expanded(
            child: summaryAsync.when(
              data: (summary) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatRow('Present', '${summary.present}', Icons.check_circle_outline, ApexColors.success),
                  _buildStatRow('Absent', '${summary.absent}', Icons.cancel_outlined, ApexColors.error),
                  _buildStatRow('Late Arrival', '${summary.late}', Icons.access_time, ApexColors.warning),
                  _buildStatRow('Half Day', '${summary.halfDay}', Icons.hourglass_bottom, ApexColors.info),
                  _buildStatRow('On Leave', '${summary.onLeave}', Icons.work_off_outlined, ApexColors.primary),
                  const SizedBox(height: 32),
                  ApexButton(
                    label: 'Process Attendance for this Day',
                    icon: Icons.build_circle_outlined,
                    expanded: true,
                    onPressed: () async {
                      try {
                        final service = ref.read(attendanceServiceProvider);
                        await service.processAttendance(dateStr);
                        ref.invalidate(dailySummaryProvider(dateStr));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processed daily logs successfully'), backgroundColor: ApexColors.success),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: ApexColors.error),
                          );
                        }
                      }
                    },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ApexCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: ApexTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
          trailing: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

