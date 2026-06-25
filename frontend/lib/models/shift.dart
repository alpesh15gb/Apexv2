class Shift {
  final String id;
  final String tenantId;
  final String name;
  final String startTime; // formatted as HH:mm:ss
  final String endTime; // formatted as HH:mm:ss
  final int gracePeriodMinutes;
  final int lateRuleMinutes;
  final int earlyRuleMinutes;
  final int overtimeThresholdMinutes;
  final bool isNightShift;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.lateRuleMinutes,
    required this.earlyRuleMinutes,
    required this.overtimeThresholdMinutes,
    required this.isNightShift,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      gracePeriodMinutes: json['grace_period_minutes'] as int? ?? 10,
      lateRuleMinutes: json['late_rule_minutes'] as int? ?? 15,
      earlyRuleMinutes: json['early_rule_minutes'] as int? ?? 15,
      overtimeThresholdMinutes: json['overtime_threshold_minutes'] as int? ?? 30,
      isNightShift: json['is_night_shift'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'grace_period_minutes': gracePeriodMinutes,
      'late_rule_minutes': lateRuleMinutes,
      'early_rule_minutes': earlyRuleMinutes,
      'overtime_threshold_minutes': overtimeThresholdMinutes,
      'is_night_shift': isNightShift,
      'is_active': isActive,
    };
  }
}

class ShiftSchedule {
  final String id;
  final String tenantId;
  final String employeeId;
  final String shiftId;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final int? dayOfWeek;
  final DateTime createdAt;
  final String? employeeName;
  final String? shiftName;

  ShiftSchedule({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.shiftId,
    required this.effectiveFrom,
    this.effectiveTo,
    this.dayOfWeek,
    required this.createdAt,
    this.employeeName,
    this.shiftName,
  });

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      shiftId: json['shift_id'] as String,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null ? DateTime.parse(json['effective_to'] as String) : null,
      dayOfWeek: json['day_of_week'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: json['employee_name'] as String?,
      shiftName: json['shift_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'shift_id': shiftId,
      'effective_from': effectiveFrom.toIso8601String().substring(0, 10),
      'effective_to': effectiveTo?.toIso8601String().substring(0, 10),
      'day_of_week': dayOfWeek,
    };
  }
}
