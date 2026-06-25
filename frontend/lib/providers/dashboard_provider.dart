import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/websocket_service.dart';

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final DashboardService _service;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  DashboardStatsNotifier(this._service, this._wsService)
      : super(const AsyncValue.loading()) {
    loadStats();
    _listenToWs();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.getStats();
      if (mounted) state = AsyncValue.data(stats);
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  void _listenToWs() {
    _wsSubscription = _wsService.stream.listen(
      (event) {
        if (!mounted) return;
        if (event['type'] == 'dashboard_update') {
          final data = event['data'];
          if (data != null && mounted) {
            state = AsyncValue.data(DashboardStats.fromJson(data as Map<String, dynamic>));
          }
        }
      },
      onError: (_) {}, // Silently handle WS errors
    );
  }
}

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>((ref) {
  final service = ref.read(dashboardServiceProvider);
  final wsService = ref.read(webSocketServiceProvider);
  return DashboardStatsNotifier(service, wsService);
});

// Trend/Chart Data Provider
final dashboardChartProvider =
    FutureProvider.family<List<AttendanceTrend>, int>((ref, days) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getAttendanceChart(days: days);
});

// Recent Activity Notifier (with real-time updates)
class RecentActivityNotifier extends StateNotifier<AsyncValue<List<RecentActivity>>> {
  final DashboardService _service;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  RecentActivityNotifier(this._service, this._wsService)
      : super(const AsyncValue.loading()) {
    loadActivities();
    _listenToWs();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getRecentActivity();
      if (mounted) state = AsyncValue.data(list);
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  void _listenToWs() {
    _wsSubscription = _wsService.stream.listen(
      (event) {
        if (!mounted) return;
        final type = event['type'] as String?;
        if (type == 'punch_event' || type == 'device_status' || type?.startsWith('visitor_') == true) {
          if (state.value != null && mounted) {
            final description = event['description'] ?? _formatEventDescription(event);
            final newActivity = RecentActivity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              activityType: type ?? 'general',
              description: description,
              timestamp: DateTime.now().toIso8601String(),
              userName: event['user_name'] ?? 'System',
            );
            state = AsyncValue.data([newActivity, ...state.value!.take(19)]);
          }
        }
      },
      onError: (_) {},
    );
  }

  String _formatEventDescription(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'device_status') {
      return 'Device ${event['device_id']} went ${event['status']}';
    }
    if (type == 'punch_event') {
      final data = event['data'] ?? {};
      return 'Employee ${data['employee_name'] ?? 'Unknown'} punched ${data['direction'] ?? 'in/out'}';
    }
    if (type == 'visitor_check_in') {
      final data = event['data'] ?? {};
      return 'Visitor ${data['visitor_name'] ?? 'Unknown'} checked in';
    }
    return 'Real-time dashboard update received';
  }
}

final recentActivityProvider =
    StateNotifierProvider<RecentActivityNotifier, AsyncValue<List<RecentActivity>>>((ref) {
  final service = ref.read(dashboardServiceProvider);
  final wsService = ref.read(webSocketServiceProvider);
  return RecentActivityNotifier(service, wsService);
});

// Attendance Heatmap Provider
final attendanceHeatmapProvider =
    FutureProvider.family<List<AttendanceHeatmapItem>, int>((ref, days) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getAttendanceHeatmap(days: days);
});

// Leave Calendar Provider
final leaveCalendarProvider =
    FutureProvider.family<List<LeaveCalendarItem>, Map<String, int>>((ref, params) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getLeaveCalendar(year: params['year'], month: params['month']);
});

// Birthdays Provider
final birthdaysProvider = FutureProvider<List<BirthdayItem>>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getBirthdays();
});

// Anniversaries Provider
final anniversariesProvider = FutureProvider<List<AnniversaryItem>>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getAnniversaries();
});

// Department Distribution Provider
final departmentDistributionProvider = FutureProvider<List<DepartmentDistribution>>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getDepartmentDistribution();
});

// Monthly Trend Provider
final monthlyTrendProvider =
    FutureProvider.family<List<MonthlyTrend>, int>((ref, months) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getMonthlyTrend(months: months);
});

// Sync Health Provider
final syncHealthProvider = FutureProvider<SyncHealthStatus>((ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getSyncHealth();
});
