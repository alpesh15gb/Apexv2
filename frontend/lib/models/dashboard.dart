class DashboardStats {
  final int employeesPresent;
  final int employeesAbsent;
  final int lateToday;
  final int visitorsInside;
  final int onlineDevices;
  final int offlineDevices;
  final int totalEmployees;
  final int pendingLeaves;
  final double attendancePercentage;
  final int missingPunches;

  DashboardStats({
    required this.employeesPresent,
    required this.employeesAbsent,
    required this.lateToday,
    required this.visitorsInside,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.totalEmployees,
    required this.pendingLeaves,
    this.attendancePercentage = 0.0,
    this.missingPunches = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      employeesPresent: json['employees_present'] as int? ?? 0,
      employeesAbsent: json['employees_absent'] as int? ?? 0,
      lateToday: json['late_today'] as int? ?? 0,
      visitorsInside: json['visitors_inside'] as int? ?? 0,
      onlineDevices: json['online_devices'] as int? ?? 0,
      offlineDevices: json['offline_devices'] as int? ?? 0,
      totalEmployees: json['total_employees'] as int? ?? 0,
      pendingLeaves: json['pending_leaves'] as int? ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
      missingPunches: json['missing_punches'] as int? ?? 0,
    );
  }
}

class AttendanceTrend {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int halfDay;

  AttendanceTrend({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
  });

  factory AttendanceTrend.fromJson(Map<String, dynamic> json) {
    return AttendanceTrend(
      date: DateTime.parse(json['date'] as String),
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
    );
  }
}

class RecentActivity {
  final String id;
  final String activityType;
  final String description;
  final String timestamp;
  final String? userName;

  RecentActivity({
    required this.id,
    required this.activityType,
    required this.description,
    required this.timestamp,
    this.userName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      activityType: json['activity_type'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] as String,
      userName: json['user_name'] as String?,
    );
  }
}

class AttendanceHeatmapItem {
  final String date;
  final int present;
  final int absent;
  final int halfDay;
  final int total;
  final double attendanceRate;

  AttendanceHeatmapItem({
    required this.date,
    required this.present,
    required this.absent,
    required this.halfDay,
    required this.total,
    required this.attendanceRate,
  });

  factory AttendanceHeatmapItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHeatmapItem(
      date: json['date'] as String,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LeaveCalendarItem {
  final String id;
  final String employeeId;
  final String startDate;
  final String endDate;
  final String status;

  LeaveCalendarItem({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory LeaveCalendarItem.fromJson(Map<String, dynamic> json) {
    return LeaveCalendarItem(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
    );
  }
}

class BirthdayItem {
  final String id;
  final String name;
  final String dateOfBirth;
  final String? department;

  BirthdayItem({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.department,
  });

  factory BirthdayItem.fromJson(Map<String, dynamic> json) {
    return BirthdayItem(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      department: json['department'] as String?,
    );
  }
}

class AnniversaryItem {
  final String id;
  final String name;
  final String? joiningDate;
  final int years;

  AnniversaryItem({
    required this.id,
    required this.name,
    this.joiningDate,
    required this.years,
  });

  factory AnniversaryItem.fromJson(Map<String, dynamic> json) {
    return AnniversaryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      joiningDate: json['joining_date'] as String?,
      years: json['years'] as int? ?? 0,
    );
  }
}

class DepartmentDistribution {
  final String department;
  final int count;

  DepartmentDistribution({
    required this.department,
    required this.count,
  });

  factory DepartmentDistribution.fromJson(Map<String, dynamic> json) {
    return DepartmentDistribution(
      department: json['department'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final int present;
  final int absent;
  final int total;
  final double attendanceRate;

  MonthlyTrend({
    required this.month,
    required this.present,
    required this.absent,
    required this.total,
    required this.attendanceRate,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] as String,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SyncHealthStatus {
  final int totalServers;
  final int connected;
  final int error;
  final List<dynamic> recentSyncs;

  SyncHealthStatus({
    required this.totalServers,
    required this.connected,
    required this.error,
    required this.recentSyncs,
  });

  factory SyncHealthStatus.fromJson(Map<String, dynamic> json) {
    return SyncHealthStatus(
      totalServers: json['total_servers'] as int? ?? 0,
      connected: json['connected'] as int? ?? 0,
      error: json['error'] as int? ?? 0,
      recentSyncs: json['recent_syncs'] as List? ?? [],
    );
  }
}
