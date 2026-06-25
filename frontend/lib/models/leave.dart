class LeaveType {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final int defaultDays;
  final bool isPaid;
  final bool carryForward;
  final int? maxConsecutive;
  final bool isActive;
  final DateTime createdAt;

  LeaveType({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.defaultDays,
    required this.isPaid,
    required this.carryForward,
    this.maxConsecutive,
    required this.isActive,
    required this.createdAt,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      defaultDays: json['default_days'] as int,
      isPaid: json['is_paid'] as bool? ?? true,
      carryForward: json['carry_forward'] as bool? ?? false,
      maxConsecutive: json['max_consecutive'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'default_days': defaultDays,
      'is_paid': isPaid,
      'carry_forward': carryForward,
      'max_consecutive': maxConsecutive,
      'is_active': isActive,
    };
  }
}

class LeaveBalance {
  final String id;
  final String employeeId;
  final String leaveTypeId;
  final int year;
  final double totalDays;
  final double usedDays;
  final double pendingDays;
  final double carriedForward;
  final double availableDays;
  final String? leaveTypeName;

  LeaveBalance({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.pendingDays,
    required this.carriedForward,
    required this.availableDays,
    this.leaveTypeName,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      leaveTypeId: json['leave_type_id'] as String,
      year: json['year'] as int,
      totalDays: (json['total_days'] as num).toDouble(),
      usedDays: (json['used_days'] as num).toDouble(),
      pendingDays: (json['pending_days'] as num).toDouble(),
      carriedForward: (json['carried_forward'] as num).toDouble(),
      availableDays: (json['available_days'] as num? ?? 0.0).toDouble(),
      leaveTypeName: json['leave_type_name'] as String?,
    );
  }
}

class LeaveRequest {
  final String id;
  final String tenantId;
  final String employeeId;
  final String leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String? reason;
  final String status; // pending, approved, rejected, cancelled
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final String? employeeName;
  final String? leaveTypeName;

  LeaveRequest({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.employeeName,
    this.leaveTypeName,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      leaveTypeId: json['leave_type_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalDays: (json['total_days'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: json['employee_name'] as String?,
      leaveTypeName: json['leave_type_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
    };
  }
}
