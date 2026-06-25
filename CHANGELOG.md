# Changelog

All notable changes to the Apex Attendance Platform.

## [2.1.0] - 2026-06-25

### Added
- **Enterprise Sync Dashboard**: New `/essl/dashboard/enterprise` endpoint with per-server health scoring (0-100), throughput trends, processing lag, raw log backlog, and alert thresholds. Frontend tabbed UI with health overview and server details.
- **Sync Audit Trail**: `SyncAuditService` writes sync lifecycle events (started/completed/failed/reprocess/recovery/config changes) to the `audit_logs` table. Integrated into all eSSL connector endpoints.
- **Timezone-Aware Parsing**: `_parse_datetime` now uses `essl_servers.timezone` to convert device-local punch times to UTC instead of blindly tagging as UTC. Supports IST, EST, and all IANA timezones.
- **Clock Drift Detection**: New `GET /essl/{id}/clock-drift` endpoint that analyzes recent punch data to detect devices with future timestamps, large gaps, or time reversals.
- **Current Employee Provider**: `currentEmployeeProvider` in `employee_provider.dart` looks up the employee record matching the current user's email.
- **Stress Tests**: `test_stress.py` with bulk processing (10K logs), reprocess performance, concurrent inserts, and idempotency tests.
- **Timezone Tests**: `test_timezone.py` with IST/EST/UTC conversion, ISO 8601 parsing, and edge cases.
- **E2E Pipeline Tests**: `test_e2e_pipeline.py` with full pipeline flow (present/late/half-day), multi-day processing, reprocess integrity, and audit lifecycle tests.
- **Design System**: Complete design system with 60+ color tokens, 15 typography styles, 8-point spacing scale, 7 border radius values, 6 elevation levels, and 6 status color categories.
- **Reusable Components**: 10 components (ApexCard, ApexButton, ApexBadge, ApexTable, ApexEmptyState, ApexLoadingSkeleton, ApexStatCard, ApexSearchBar, ApexFilterBar, ApexBreadcrumb).
- **Collapsible Sidebar Navigation**: Desktop sidebar (240px/64px) with navigation items, breadcrumbs, global search (Cmd+K), and quick actions.
- **Responsive Layout**: Mobile (<600px), tablet (600-1200px), desktop (>1200px) breakpoints with adaptive layouts.
- **Table-First Employee List**: Default table view with 8 columns, sorting, bulk selection, bulk actions, and grid view toggle.
- **Multi-View Attendance**: Table view (default), calendar view (placeholder), timeline view (placeholder), quick date selectors.
- **Device Operations Dashboard**: Health summary cards, device grid with status indicators, connection quality visualization.
- **Enhanced Report Selection**: Report type grid, configuration card, format selection chips, download with progress.
- **Loading Skeletons**: Shimmer loading states for lists, cards, tables, and stat cards.
- **Empty States**: Illustrated empty states with optional action buttons.
- **Audit Reports**: 18 audit reports covering architecture, database, security, performance, UI/UX, and more.

### Fixed
- **Leave Balance Wrong ID**: `leave_balance_screen.dart` now uses `currentEmployeeProvider` to get the employee ID instead of `user.id`.
- **Report Download No Save**: `report_selection_screen.dart` now saves downloaded bytes to disk via `dart:html` blob/anchor download with proper filenames.
- **Timezone Blind UTC**: `essl_connector.py:_parse_datetime` was tagging all punch times as UTC regardless of device timezone. Now uses `server.timezone` for proper conversion.

### Changed
- **eSSL Dashboard Screen**: Converted to tabbed layout with "Health Overview" (enterprise dashboard) and "Server Details" (per-server metrics).
- **ESSl Server CRUD**: Create and delete endpoints now log config changes to audit trail.
- **Sync Endpoints**: All manual sync endpoints (employees/attendance/devices) now log start/completion to audit trail.
- **Dashboard Screen**: Redesigned with stat cards, attendance trend chart, quick actions, and activity feed.
- **Employee List Screen**: Redesigned with table-first layout, column sorting, bulk actions, and responsive grid.
- **Attendance List Screen**: Redesigned with multiple view modes, quick date selectors, and enhanced filters.
- **Device List Screen**: Redesigned with operations dashboard layout, health cards, and device grid.
- **Report Selection Screen**: Redesigned with report type grid and configuration card.
- **Main Shell**: Rewritten with collapsible sidebar (desktop) and bottom navigation (mobile).
- **Theme**: Updated to use design system tokens for consistent styling.

## [2.0.0] - 2026-06-20

### Added
- Multi-tenant eSSL server support
- SOAP connector with circuit breaker and retry
- Employee, device, and attendance sync
- Initial sync wizard with date range
- Sync cursor for incremental fetching
- Offline recovery
- Duplicate detection (per-server + cross-server)
- Manual attendance reprocessing
- Celery background tasks (4 periodic)
- Audit middleware
- Rate limiting middleware
- Flutter web frontend (38 screens)
- Docker Compose deployment
