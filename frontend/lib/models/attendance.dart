class Attendance {
  final String id;
  final String tenantId;
  final String employeeId;
  final DateTime date;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final double? totalHours;
  final double? overtimeHours;
  final String status;
  final bool isLate;
  final int lateMinutes;
  final bool isEarlyOut;
  final int earlyOutMinutes;
  final String? shiftId;
  final String? remarks;
  final bool isManual;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? employeeName;
  final String? employeeCode;

  Attendance({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.date,
    this.punchIn,
    this.punchOut,
    this.totalHours,
    this.overtimeHours,
    required this.status,
    required this.isLate,
    required this.lateMinutes,
    required this.isEarlyOut,
    required this.earlyOutMinutes,
    this.shiftId,
    this.remarks,
    required this.isManual,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
    this.employeeCode,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      date: DateTime.parse(json['date'] as String),
      punchIn: json['punch_in'] != null ? DateTime.parse(json['punch_in'] as String) : null,
      punchOut: json['punch_out'] != null ? DateTime.parse(json['punch_out'] as String) : null,
      totalHours: (json['total_hours'] as num?)?.toDouble(),
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'absent',
      isLate: json['is_late'] as bool? ?? false,
      lateMinutes: json['late_minutes'] as int? ?? 0,
      isEarlyOut: json['is_early_out'] as bool? ?? false,
      earlyOutMinutes: json['early_out_minutes'] as int? ?? 0,
      shiftId: json['shift_id'] as String?,
      remarks: json['remarks'] as String?,
      isManual: json['is_manual'] as bool? ?? false,
      approvedBy: json['approved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
      employeeCode: json['employee_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'date': date.toIso8601String().substring(0, 10),
      'punch_in': punchIn?.toIso8601String(),
      'punch_out': punchOut?.toIso8601String(),
      'total_hours': totalHours,
      'overtime_hours': overtimeHours,
      'status': status,
      'is_late': isLate,
      'late_minutes': lateMinutes,
      'is_early_out': isEarlyOut,
      'early_out_minutes': earlyOutMinutes,
      'shift_id': shiftId,
      'remarks': remarks,
      'is_manual': isManual,
      'approved_by': approvedBy,
    };
  }
}

class PunchLog {
  final String id;
  final String employeeId;
  final DateTime timestamp;
  final String source;
  final DateTime createdAt;
  final String? employeeName;
  final String? employeeCode;

  PunchLog({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.source,
    required this.createdAt,
    this.employeeName,
    this.employeeCode,
  });

  factory PunchLog.fromJson(Map<String, dynamic> json) {
    return PunchLog(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String? ?? 'biometric',
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: json['employee_name'] as String?,
      employeeCode: json['employee_code'] as String?,
    );
  }
}

class AttendanceSummary {
  final String employeeId;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final double totalHours;
  final double totalOvertimeHours;

  AttendanceSummary({
    required this.employeeId,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.totalHours,
    required this.totalOvertimeHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      employeeId: json['employee_id'] as String,
      totalDays: json['total_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      absentDays: json['absent_days'] as int? ?? 0,
      lateDays: json['late_days'] as int? ?? 0,
      halfDays: json['half_days'] as int? ?? 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalOvertimeHours: (json['total_overtime_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyAttendanceSummary {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int onLeave;

  DailyAttendanceSummary({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.onLeave,
  });

  factory DailyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceSummary(
      date: DateTime.parse(json['date'] as String),
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      onLeave: json['on_leave'] as int? ?? 0,
    );
  }
}
