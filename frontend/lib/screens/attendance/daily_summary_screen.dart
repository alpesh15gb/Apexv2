import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/page_wrapper.dart';
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
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Daily Summary',
        description: 'Track aggregate attendance KPIs and reprocess daily punch logs.',
        onRefresh: () => ref.invalidate(dailySummaryProvider(dateStr)),
        filterBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: ApexDatePicker(
                  label: 'Selected Date',
                  value: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onChanged: (v) { if (v != null) setState(() => _selectedDate = v); },
                ),
              ),
            ],
          ),
        ),
        body: summaryAsync.when(
          data: (summary) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStatRow('Present', '${summary.present}', Icons.check_circle_outline, ApexColors.success),
              _buildStatRow('Absent', '${summary.absent}', Icons.cancel_outlined, ApexColors.error),
              _buildStatRow('Late Arrival', '${summary.late}', Icons.access_time, ApexColors.warning),
              _buildStatRow('Half Day', '${summary.halfDay}', Icons.hourglass_bottom, ApexColors.info),
              _buildStatRow('On Leave', '${summary.onLeave}', Icons.work_off_outlined, ApexColors.primary),
              const SizedBox(height: 24),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $err', style: ApexTypography.body.copyWith(color: ApexColors.error)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(dailySummaryProvider(dateStr)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
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
