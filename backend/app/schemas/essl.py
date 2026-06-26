"""eSSL Connector Pydantic schemas."""

import uuid
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class EsslServerCreate(BaseModel):
    name: str = Field(..., max_length=255)
    server_url: str = Field(..., max_length=512)
    username: str = Field(..., max_length=255)
    password: str
    location: str = Field(default="", max_length=255)
    timeout_seconds: int = Field(default=30, ge=5, le=120)
    timezone: str = Field(default="Asia/Kolkata", max_length=50)
    auto_sync_enabled: bool = True
    attendance_sync_interval_minutes: int = Field(default=5, ge=1, le=60)
    device_sync_interval_minutes: int = Field(default=60, ge=5, le=1440)
    employee_sync_hour: int = Field(default=2, ge=0, le=23)
    employee_conflict_policy: str = Field(default="disable")
    device_conflict_policy: str = Field(default="disable")


class EsslServerUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    server_url: Optional[str] = Field(None, max_length=512)
    username: Optional[str] = Field(None, max_length=255)
    password: Optional[str] = None
    location: Optional[str] = Field(None, max_length=255)
    timeout_seconds: Optional[int] = Field(None, ge=5, le=120)
    timezone: Optional[str] = Field(None, max_length=50)
    auto_sync_enabled: Optional[bool] = None
    attendance_sync_interval_minutes: Optional[int] = Field(None, ge=1, le=60)
    device_sync_interval_minutes: Optional[int] = Field(None, ge=5, le=1440)
    employee_sync_hour: Optional[int] = Field(None, ge=0, le=23)
    employee_conflict_policy: Optional[str] = None
    device_conflict_policy: Optional[str] = None
    is_active: Optional[bool] = None


class EsslServerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    server_url: str
    username: str
    location: str
    timeout_seconds: int
    timezone: str
    auto_sync_enabled: bool
    attendance_sync_interval_minutes: int
    device_sync_interval_minutes: int
    employee_sync_hour: int
    employee_conflict_policy: str
    device_conflict_policy: str
    status: str
    last_connected_at: Optional[datetime] = None
    last_error: Optional[str] = None
    server_version: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime


class EsslTestResult(BaseModel):
    success: bool
    server_version: Optional[str] = None
    response_time_ms: Optional[int] = None
    error: Optional[str] = None


class EsslSyncHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    essl_server_id: uuid.UUID
    sync_type: str
    status: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    duration_seconds: Optional[float] = None
    records_fetched: int
    records_created: int
    records_updated: int
    records_skipped: int
    records_failed: int
    error_message: Optional[str] = None
    triggered_by: str
    date_range_from: Optional[datetime] = None
    date_range_to: Optional[datetime] = None


class EsslSyncErrorItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    sync_history_id: uuid.UUID
    error_code: Optional[str] = None
    error_message: Optional[str] = None
    entity_type: Optional[str] = None
    entity_identifier: Optional[str] = None
    occurred_at: datetime


class EsslSyncDashboardStatus(BaseModel):
    server_id: uuid.UUID
    server_name: str
    connection_status: str
    last_connected_at: Optional[datetime] = None
    last_attendance_sync: Optional[datetime] = None
    last_employee_sync: Optional[datetime] = None
    last_device_sync: Optional[datetime] = None
    total_devices: int = 0
    total_employees_synced: int = 0
    pending_raw_logs: int = 0
    recent_errors: int = 0
    current_sync_state: Optional[str] = None
    current_progress_percent: int = 0
    soap_response_time_ms: Optional[int] = None
    last_sync_duration_seconds: Optional[float] = None
    records_downloaded_today: int = 0
    duplicate_punches_detected: int = 0
    duplicate_punches_resolved: int = 0
    failed_sync_attempts: int = 0
    consecutive_failures: int = 0
    next_scheduled_sync: Optional[datetime] = None
    current_cursor_position: Optional[datetime] = None
    recovery_status: Optional[str] = None


class AttendanceReprocessRequest(BaseModel):
    from_date: Optional[date] = None
    to_date: Optional[date] = None
    employee_id: Optional[uuid.UUID] = None
    department_id: Optional[uuid.UUID] = None


class AttendanceReprocessResult(BaseModel):
    processed: int
    created: int
    updated: int
    errors: int
    reset: int


class ServerSyncHealth(BaseModel):
    server_id: uuid.UUID
    server_name: str
    health_score: int = Field(ge=0, le=100)
    connection_status: str
    last_sync_age_minutes: Optional[float] = None
    processing_lag_minutes: Optional[float] = None
    raw_log_backlog: int = 0
    error_rate: float = 0.0
    throughput_per_hour: float = 0.0
    consecutive_failures: int = 0
    cursor_freshness_minutes: Optional[float] = None
    alerts: List[str] = []


class SyncThroughputPoint(BaseModel):
    timestamp: datetime
    records_synced: int
    errors: int
    duration_seconds: Optional[float] = None


class EnterpriseSyncDashboard(BaseModel):
    overall_health_score: int = Field(ge=0, le=100)
    total_servers: int = 0
    healthy_servers: int = 0
    degraded_servers: int = 0
    down_servers: int = 0
    total_pending_raw_logs: int = 0
    total_syncs_today: int = 0
    total_errors_today: int = 0
    avg_processing_lag_minutes: Optional[float] = None
    servers: List[ServerSyncHealth] = []
    throughput_trend: List[SyncThroughputPoint] = []
