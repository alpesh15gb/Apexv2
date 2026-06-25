class AccessZone {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String branchId;
  final bool isRestricted;
  final int accessLevelRequired;
  final DateTime createdAt;

  AccessZone({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.branchId,
    required this.isRestricted,
    required this.accessLevelRequired,
    required this.createdAt,
  });

  factory AccessZone.fromJson(Map<String, dynamic> json) {
    return AccessZone(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      branchId: json['branch_id'] as String,
      isRestricted: json['is_restricted'] as bool? ?? false,
      accessLevelRequired: json['access_level_required'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'branch_id': branchId,
      'is_restricted': isRestricted,
      'access_level_required': accessLevelRequired,
    };
  }
}

class Door {
  final String id;
  final String tenantId;
  final String name;
  final String zoneId;
  final String? deviceId;
  final bool isActive;
  final DateTime createdAt;

  Door({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.zoneId,
    this.deviceId,
    required this.isActive,
    required this.createdAt,
  });

  factory Door.fromJson(Map<String, dynamic> json) {
    return Door(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      zoneId: json['zone_id'] as String,
      deviceId: json['device_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'zone_id': zoneId,
      'device_id': deviceId,
      'is_active': isActive,
    };
  }
}

class UserAccessLevel {
  final String id;
  final String tenantId;
  final String employeeId;
  final String zoneId;
  final int accessLevel;
  final String? grantedBy;
  final DateTime? validFrom;
  final DateTime? validTo;
  final DateTime createdAt;
  final String? employeeName;
  final String? zoneName;

  UserAccessLevel({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.zoneId,
    required this.accessLevel,
    this.grantedBy,
    this.validFrom,
    this.validTo,
    required this.createdAt,
    this.employeeName,
    this.zoneName,
  });

  factory UserAccessLevel.fromJson(Map<String, dynamic> json) {
    return UserAccessLevel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      zoneId: json['zone_id'] as String,
      accessLevel: json['access_level'] as int? ?? 1,
      grantedBy: json['granted_by'] as String?,
      validFrom: json['valid_from'] != null ? DateTime.parse(json['valid_from'] as String) : null,
      validTo: json['valid_to'] != null ? DateTime.parse(json['valid_to'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: json['employee_name'] as String?,
      zoneName: json['zone_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'zone_id': zoneId,
      'access_level': accessLevel,
      'valid_from': validFrom?.toIso8601String().substring(0, 10),
      'valid_to': validTo?.toIso8601String().substring(0, 10),
    };
  }
}

class AccessLog {
  final String id;
  final String tenantId;
  final String? employeeId;
  final String? visitorId;
  final String doorId;
  final DateTime accessTime;
  final String accessType;
  final bool granted;
  final String? denialReason;
  final String? doorName;

  AccessLog({
    required this.id,
    required this.tenantId,
    this.employeeId,
    this.visitorId,
    required this.doorId,
    required this.accessTime,
    required this.accessType,
    required this.granted,
    this.denialReason,
    this.doorName,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String?,
      visitorId: json['visitor_id'] as String?,
      doorId: json['door_id'] as String,
      accessTime: DateTime.parse(json['access_time'] as String),
      accessType: json['access_type'] as String? ?? 'card',
      granted: json['granted'] as bool? ?? false,
      denialReason: json['denial_reason'] as String?,
      doorName: json['door_name'] as String?,
    );
  }
}
