class EsslServer {
  final String id;
  final String tenantId;
  final String name;
  final String serverUrl;
  final String username;
  final int timeoutSeconds;
  final String timezone;
  final bool autoSyncEnabled;
  final int attendanceSyncIntervalMinutes;
  final int deviceSyncIntervalMinutes;
  final int employeeSyncHour;
  final String employeeConflictPolicy;
  final String deviceConflictPolicy;
  final String status;
  final DateTime? lastConnectedAt;
  final String? lastError;
  final String? serverVersion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EsslServer({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.serverUrl,
    required this.username,
    required this.timeoutSeconds,
    required this.timezone,
    required this.autoSyncEnabled,
    required this.attendanceSyncIntervalMinutes,
    required this.deviceSyncIntervalMinutes,
    required this.employeeSyncHour,
    required this.employeeConflictPolicy,
    required this.deviceConflictPolicy,
    required this.status,
    this.lastConnectedAt,
    this.lastError,
    this.serverVersion,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EsslServer.fromJson(Map<String, dynamic> json) {
    return EsslServer(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      serverUrl: json['server_url'] as String,
      username: json['username'] as String,
      timeoutSeconds: json['timeout_seconds'] as int,
      timezone: json['timezone'] as String,
      autoSyncEnabled: json['auto_sync_enabled'] as bool,
      attendanceSyncIntervalMinutes: json['attendance_sync_interval_minutes'] as int,
      deviceSyncIntervalMinutes: json['device_sync_interval_minutes'] as int,
      employeeSyncHour: json['employee_sync_hour'] as int,
      employeeConflictPolicy: json['employee_conflict_policy'] as String,
      deviceConflictPolicy: json['device_conflict_policy'] as String,
      status: json['status'] as String,
      lastConnectedAt: json['last_connected_at'] != null ? DateTime.parse(json['last_connected_at']) : null,
      lastError: json['last_error'] as String?,
      serverVersion: json['server_version'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class EsslSyncHistory {
  final String id;
  final String esslServerId;
  final String syncType;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? durationSeconds;
  final int recordsFetched;
  final int recordsCreated;
  final int recordsUpdated;
  final int recordsSkipped;
  final int recordsFailed;
  final String? errorMessage;
  final String triggeredBy;
  final int progressPercent;
  final int totalRecordsExpected;
  final int currentBatch;
  final int totalBatches;
  final bool isPaused;
  final bool isCancelled;

  EsslSyncHistory({
    required this.id,
    required this.esslServerId,
    required this.syncType,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds,
    required this.recordsFetched,
    required this.recordsCreated,
    required this.recordsUpdated,
    required this.recordsSkipped,
    required this.recordsFailed,
    this.errorMessage,
    required this.triggeredBy,
    this.progressPercent = 0,
    this.totalRecordsExpected = 0,
    this.currentBatch = 0,
    this.totalBatches = 0,
    this.isPaused = false,
    this.isCancelled = false,
  });

  factory EsslSyncHistory.fromJson(Map<String, dynamic> json) {
    return EsslSyncHistory(
      id: json['id'] as String,
      esslServerId: json['essl_server_id'] as String,
      syncType: json['sync_type'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      recordsFetched: json['records_fetched'] as int,
      recordsCreated: json['records_created'] as int,
      recordsUpdated: json['records_updated'] as int,
      recordsSkipped: json['records_skipped'] as int,
      recordsFailed: json['records_failed'] as int,
      errorMessage: json['error_message'] as String?,
      triggeredBy: json['triggered_by'] as String,
      progressPercent: json['progress_percent'] as int? ?? 0,
      totalRecordsExpected: json['total_records_expected'] as int? ?? 0,
      currentBatch: json['current_batch'] as int? ?? 0,
      totalBatches: json['total_batches'] as int? ?? 0,
      isPaused: json['is_paused'] as bool? ?? false,
      isCancelled: json['is_cancelled'] as bool? ?? false,
    );
  }
}

class SyncProgress {
  final String id;
  final String status;
  final int progressPercent;
  final int totalRecordsExpected;
  final int currentBatch;
  final int totalBatches;
  final int recordsFetched;
  final int recordsCreated;
  final int recordsUpdated;
  final int recordsSkipped;
  final int recordsFailed;
  final bool isPaused;
  final bool isCancelled;
  final String? startedAt;
  final double? durationSeconds;

  SyncProgress({
    required this.id,
    required this.status,
    required this.progressPercent,
    required this.totalRecordsExpected,
    required this.currentBatch,
    required this.totalBatches,
    required this.recordsFetched,
    required this.recordsCreated,
    required this.recordsUpdated,
    required this.recordsSkipped,
    required this.recordsFailed,
    required this.isPaused,
    required this.isCancelled,
    this.startedAt,
    this.durationSeconds,
  });

  factory SyncProgress.fromJson(Map<String, dynamic> json) {
    return SyncProgress(
      id: json['id'] as String,
      status: json['status'] as String,
      progressPercent: json['progress_percent'] as int,
      totalRecordsExpected: json['total_records_expected'] as int,
      currentBatch: json['current_batch'] as int,
      totalBatches: json['total_batches'] as int,
      recordsFetched: json['records_fetched'] as int,
      recordsCreated: json['records_created'] as int,
      recordsUpdated: json['records_updated'] as int,
      recordsSkipped: json['records_skipped'] as int,
      recordsFailed: json['records_failed'] as int,
      isPaused: json['is_paused'] as bool,
      isCancelled: json['is_cancelled'] as bool,
      startedAt: json['started_at'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
    );
  }
}

class EsslTestResult {
  final bool success;
  final String? serverVersion;
  final int? responseTimeMs;
  final String? error;

  EsslTestResult({
    required this.success,
    this.serverVersion,
    this.responseTimeMs,
    this.error,
  });

  factory EsslTestResult.fromJson(Map<String, dynamic> json) {
    return EsslTestResult(
      success: json['success'] as bool,
      serverVersion: json['server_version'] as String?,
      responseTimeMs: json['response_time_ms'] as int?,
      error: json['error'] as String?,
    );
  }
}

class EsslSyncDashboardStatus {
  final String serverId;
  final String serverName;
  final String connectionStatus;
  final DateTime? lastConnectedAt;
  final DateTime? lastAttendanceSync;
  final DateTime? lastEmployeeSync;
  final DateTime? lastDeviceSync;
  final int totalDevices;
  final int totalEmployeesSynced;
  final int pendingRawLogs;
  final int recentErrors;
  final String? currentSyncState;
  final int currentProgressPercent;
  final int? soapResponseTimeMs;
  final double? lastSyncDurationSeconds;
  final int recordsDownloadedToday;
  final int duplicatePunchesDetected;
  final int duplicatePunchesResolved;
  final int failedSyncAttempts;
  final int consecutiveFailures;
  final DateTime? nextScheduledSync;
  final DateTime? currentCursorPosition;
  final String? recoveryStatus;

  EsslSyncDashboardStatus({
    required this.serverId,
    required this.serverName,
    required this.connectionStatus,
    this.lastConnectedAt,
    this.lastAttendanceSync,
    this.lastEmployeeSync,
    this.lastDeviceSync,
    required this.totalDevices,
    required this.totalEmployeesSynced,
    required this.pendingRawLogs,
    required this.recentErrors,
    this.currentSyncState,
    this.currentProgressPercent = 0,
    this.soapResponseTimeMs,
    this.lastSyncDurationSeconds,
    this.recordsDownloadedToday = 0,
    this.duplicatePunchesDetected = 0,
    this.duplicatePunchesResolved = 0,
    this.failedSyncAttempts = 0,
    this.consecutiveFailures = 0,
    this.nextScheduledSync,
    this.currentCursorPosition,
    this.recoveryStatus,
  });

  factory EsslSyncDashboardStatus.fromJson(Map<String, dynamic> json) {
    return EsslSyncDashboardStatus(
      serverId: json['server_id'] as String,
      serverName: json['server_name'] as String,
      connectionStatus: json['connection_status'] as String,
      lastConnectedAt: json['last_connected_at'] != null ? DateTime.parse(json['last_connected_at']) : null,
      lastAttendanceSync: json['last_attendance_sync'] != null ? DateTime.parse(json['last_attendance_sync']) : null,
      lastEmployeeSync: json['last_employee_sync'] != null ? DateTime.parse(json['last_employee_sync']) : null,
      lastDeviceSync: json['last_device_sync'] != null ? DateTime.parse(json['last_device_sync']) : null,
      totalDevices: json['total_devices'] as int,
      totalEmployeesSynced: json['total_employees_synced'] as int,
      pendingRawLogs: json['pending_raw_logs'] as int,
      recentErrors: json['recent_errors'] as int,
      currentSyncState: json['current_sync_state'] as String?,
      currentProgressPercent: json['current_progress_percent'] as int? ?? 0,
      soapResponseTimeMs: json['soap_response_time_ms'] as int?,
      lastSyncDurationSeconds: (json['last_sync_duration_seconds'] as num?)?.toDouble(),
      recordsDownloadedToday: json['records_downloaded_today'] as int? ?? 0,
      duplicatePunchesDetected: json['duplicate_punches_detected'] as int? ?? 0,
      duplicatePunchesResolved: json['duplicate_punches_resolved'] as int? ?? 0,
      failedSyncAttempts: json['failed_sync_attempts'] as int? ?? 0,
      consecutiveFailures: json['consecutive_failures'] as int? ?? 0,
      nextScheduledSync: json['next_scheduled_sync'] != null ? DateTime.parse(json['next_scheduled_sync']) : null,
      currentCursorPosition: json['current_cursor_position'] != null ? DateTime.parse(json['current_cursor_position']) : null,
      recoveryStatus: json['recovery_status'] as String?,
    );
  }
}

class ServerSyncHealth {
  final String serverId;
  final String serverName;
  final int healthScore;
  final String connectionStatus;
  final double? lastSyncAgeMinutes;
  final double? processingLagMinutes;
  final int rawLogBacklog;
  final double errorRate;
  final double throughputPerHour;
  final int consecutiveFailures;
  final double? cursorFreshnessMinutes;
  final List<String> alerts;

  ServerSyncHealth({
    required this.serverId,
    required this.serverName,
    required this.healthScore,
    required this.connectionStatus,
    this.lastSyncAgeMinutes,
    this.processingLagMinutes,
    required this.rawLogBacklog,
    required this.errorRate,
    required this.throughputPerHour,
    required this.consecutiveFailures,
    this.cursorFreshnessMinutes,
    required this.alerts,
  });

  factory ServerSyncHealth.fromJson(Map<String, dynamic> json) {
    return ServerSyncHealth(
      serverId: json['server_id'] as String,
      serverName: json['server_name'] as String,
      healthScore: json['health_score'] as int,
      connectionStatus: json['connection_status'] as String,
      lastSyncAgeMinutes: (json['last_sync_age_minutes'] as num?)?.toDouble(),
      processingLagMinutes: (json['processing_lag_minutes'] as num?)?.toDouble(),
      rawLogBacklog: json['raw_log_backlog'] as int? ?? 0,
      errorRate: (json['error_rate'] as num?)?.toDouble() ?? 0.0,
      throughputPerHour: (json['throughput_per_hour'] as num?)?.toDouble() ?? 0.0,
      consecutiveFailures: json['consecutive_failures'] as int? ?? 0,
      cursorFreshnessMinutes: (json['cursor_freshness_minutes'] as num?)?.toDouble(),
      alerts: (json['alerts'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class SyncThroughputPoint {
  final DateTime timestamp;
  final int recordsSynced;
  final int errors;
  final double? durationSeconds;

  SyncThroughputPoint({
    required this.timestamp,
    required this.recordsSynced,
    required this.errors,
    this.durationSeconds,
  });

  factory SyncThroughputPoint.fromJson(Map<String, dynamic> json) {
    return SyncThroughputPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      recordsSynced: json['records_synced'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
    );
  }
}

class EnterpriseSyncDashboard {
  final int overallHealthScore;
  final int totalServers;
  final int healthyServers;
  final int degradedServers;
  final int downServers;
  final int totalPendingRawLogs;
  final int totalSyncsToday;
  final int totalErrorsToday;
  final double? avgProcessingLagMinutes;
  final List<ServerSyncHealth> servers;
  final List<SyncThroughputPoint> throughputTrend;

  EnterpriseSyncDashboard({
    required this.overallHealthScore,
    required this.totalServers,
    required this.healthyServers,
    required this.degradedServers,
    required this.downServers,
    required this.totalPendingRawLogs,
    required this.totalSyncsToday,
    required this.totalErrorsToday,
    this.avgProcessingLagMinutes,
    required this.servers,
    required this.throughputTrend,
  });

  factory EnterpriseSyncDashboard.fromJson(Map<String, dynamic> json) {
    return EnterpriseSyncDashboard(
      overallHealthScore: json['overall_health_score'] as int? ?? 100,
      totalServers: json['total_servers'] as int? ?? 0,
      healthyServers: json['healthy_servers'] as int? ?? 0,
      degradedServers: json['degraded_servers'] as int? ?? 0,
      downServers: json['down_servers'] as int? ?? 0,
      totalPendingRawLogs: json['total_pending_raw_logs'] as int? ?? 0,
      totalSyncsToday: json['total_syncs_today'] as int? ?? 0,
      totalErrorsToday: json['total_errors_today'] as int? ?? 0,
      avgProcessingLagMinutes: (json['avg_processing_lag_minutes'] as num?)?.toDouble(),
      servers: (json['servers'] as List?)?.map((e) => ServerSyncHealth.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      throughputTrend: (json['throughput_trend'] as List?)?.map((e) => SyncThroughputPoint.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
