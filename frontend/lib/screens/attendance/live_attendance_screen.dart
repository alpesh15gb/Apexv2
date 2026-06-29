import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/page_wrapper.dart';

class LiveAttendanceScreen extends ConsumerStatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  ConsumerState<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends ConsumerState<LiveAttendanceScreen> {
  Timer? _refreshTimer;
  bool _autoRefresh = true;

  static final _todayStr = DateTime.now().toIso8601String().substring(0, 10);
  static final _punchLogsParams = <String, String?>{
    'fromDate': _todayStr,
    'toDate': _todayStr,
  };

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_autoRefresh) return;
      ref.invalidate(punchLogsProvider(_punchLogsParams));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final punchLogsAsync = ref.watch(punchLogsProvider(_punchLogsParams));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Live Attendance Feed',
        description: 'Real-time monitoring of biometric device punches.',
        actions: [
          Row(
            children: [
              Text('Auto-refresh: ', style: ApexTypography.caption),
              Switch(
                value: _autoRefresh,
                onChanged: (v) {
                  setState(() => _autoRefresh = v);
                  if (v) _startAutoRefresh();
                },
                activeColor: ApexColors.success,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh now',
                onPressed: () => ref.invalidate(punchLogsProvider(_punchLogsParams)),
              ),
            ],
          ),
        ],
        body: punchLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint, size: 48, color: ApexColors.neutral300),
                    const SizedBox(height: 12),
                    Text('No punch logs for today', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(punchLogsProvider(_punchLogsParams)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final log = logs[i];
                  final localTime = log.timestamp.toLocal();
                  final timeStr = DateFormat('hh:mm:ss a').format(localTime);
                  final dateStr = DateFormat('MMM dd, yyyy').format(localTime);
                  final name = log.employeeName ?? 'Unknown';
                  final code = log.employeeCode ?? log.employeeId;
                  final source = log.source;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ApexColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ApexColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fingerprint, color: ApexColors.success, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                              Text('$code • $source', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(timeStr, style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                            const SizedBox(height: 2),
                            Text(dateStr, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: ApexColors.error),
                const SizedBox(height: 12),
                Text('Failed to load punch logs', style: ApexTypography.body.copyWith(color: ApexColors.error)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(punchLogsProvider(_punchLogsParams)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
