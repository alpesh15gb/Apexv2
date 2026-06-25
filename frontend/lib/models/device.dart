class Device {
  final String id;
  final String tenantId;
  final String serialNumber;
  final String deviceName;
  final String? model;
  final String? firmwareVersion;
  final String? ipAddress;
  final int? port;
  final String? location;
  final String? branchId;
  final String deviceType;
  final String communicationMode;
  final DateTime? lastPing;
  final DateTime? lastSync;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? branchName;

  Device({
    required this.id,
    required this.tenantId,
    required this.serialNumber,
    required this.deviceName,
    this.model,
    this.firmwareVersion,
    this.ipAddress,
    this.port,
    this.location,
    this.branchId,
    required this.deviceType,
    required this.communicationMode,
    this.lastPing,
    this.lastSync,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.branchName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      serialNumber: json['serial_number'] as String,
      deviceName: json['device_name'] as String,
      model: json['model'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      ipAddress: json['ip_address'] as String?,
      port: json['port'] as int?,
      location: json['location'] as String?,
      branchId: json['branch_id'] as String?,
      deviceType: json['device_type'] as String? ?? 'biometric',
      communicationMode: json['communication_mode'] as String? ?? 'tcp/ip',
      lastPing: json['last_ping'] != null ? DateTime.parse(json['last_ping'] as String) : null,
      lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync'] as String) : null,
      status: json['status'] as String? ?? 'offline',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      branchName: json['branch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'serial_number': serialNumber,
      'device_name': deviceName,
      'model': model,
      'firmware_version': firmwareVersion,
      'ip_address': ipAddress,
      'port': port,
      'location': location,
      'branch_id': branchId,
      'device_type': deviceType,
      'communication_mode': communicationMode,
      'is_active': isActive,
    };
  }
}

class DeviceCommand {
  final String id;
  final String tenantId;
  final String deviceId;
  final String commandType;
  final Map<String, dynamic>? parameters;
  final String status;
  final String requestedBy;
  final DateTime requestedAt;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? responseData;
  final String? errorMessage;

  DeviceCommand({
    required this.id,
    required this.tenantId,
    required this.deviceId,
    required this.commandType,
    this.parameters,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    this.sentAt,
    this.completedAt,
    this.responseData,
    this.errorMessage,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      deviceId: json['device_id'] as String,
      commandType: json['command_type'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
      status: json['status'] as String,
      requestedBy: json['requested_by'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      responseData: json['response_data'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'device_id': deviceId,
      'command_type': commandType,
      'parameters': parameters,
      'status': status,
      'requested_by': requestedBy,
      'requested_at': requestedAt.toIso8601String(),
    };
  }
}

class DeviceLog {
  final String id;
  final String deviceId;
  final String logType;
  final String? message;
  final Map<String, dynamic>? rawData;
  final DateTime createdAt;

  DeviceLog({
    required this.id,
    required this.deviceId,
    required this.logType,
    this.message,
    this.rawData,
    required this.createdAt,
  });

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      logType: json['log_type'] as String,
      message: json['message'] as String?,
      rawData: json['raw_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DeviceHealth {
  final int totalDevices;
  final int online;
  final int offline;
  final int inactive;
  final int error;

  DeviceHealth({
    required this.totalDevices,
    required this.online,
    required this.offline,
    required this.inactive,
    required this.error,
  });

  factory DeviceHealth.fromJson(Map<String, dynamic> json) {
    return DeviceHealth(
      totalDevices: json['total_devices'] as int? ?? 0,
      online: json['online'] as int? ?? 0,
      offline: json['offline'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
      error: json['error'] as int? ?? 0,
    );
  }
}
