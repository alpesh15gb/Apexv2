import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../services/essl_service.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

class EsslInitialSyncScreen extends ConsumerStatefulWidget {
  final String serverId;

  const EsslInitialSyncScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  ConsumerState<EsslInitialSyncScreen> createState() => _EsslInitialSyncScreenState();
}

class _EsslInitialSyncScreenState extends ConsumerState<EsslInitialSyncScreen> {
  String _selectedRange = '30';
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _isSyncing = false;
  String? _activeSyncId;
  SyncProgress? _progress;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Initial Attendance Sync'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: ApexColors.primary),
                      const SizedBox(width: 8),
                      Text('First-Time Import', style: ApexTypography.sectionTitle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import historical attendance data from your eSSL eBioserverNew server. '
                    'This will download punch logs for the selected date range and create raw logs '
                    'that will be processed into attendance records.',
                    style: ApexTypography.body.copyWith(color: ApexColors.neutral600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Select Date Range', style: ApexTypography.cardTitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRangeChip('30', 'Last 30 Days'),
                _buildRangeChip('90', 'Last 90 Days'),
                _buildRangeChip('180', 'Last 6 Months'),
                _buildRangeChip('365', 'Last Year'),
                _buildRangeChip('custom', 'Custom Range'),
              ],
            ),
            if (_selectedRange == 'custom') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_customFrom != null
                          ? DateFormat('MMM dd, yyyy').format(_customFrom!)
                          : 'From Date'),
                      onPressed: () => _selectDate(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApexColors.primary,
                        side: BorderSide(color: ApexColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_customTo != null
                          ? DateFormat('MMM dd, yyyy').format(_customTo!)
                          : 'To Date'),
                      onPressed: () => _selectDate(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApexColors.primary,
                        side: BorderSide(color: ApexColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (_progress != null) ...[
              ApexCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_statusText, style: ApexTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        )),
                        if (_progress!.isPaused)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ApexColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('PAUSED', style: ApexTypography.captionSmall.copyWith(color: ApexColors.warning, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _progress!.progressPercent / 100,
                      backgroundColor: ApexColors.neutral200,
                      color: ApexColors.primary,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text('${_progress!.progressPercent}% — Day ${_progress!.currentBatch} of ${_progress!.totalBatches}', style: ApexTypography.body),
                    const SizedBox(height: 16),
                    _buildStatRow('Records Created', '${_progress!.recordsCreated}'),
                    _buildStatRow('Records Skipped', '${_progress!.recordsSkipped}'),
                    _buildStatRow('Records Failed', '${_progress!.recordsFailed}'),
                    if (_progress!.durationSeconds != null)
                      _buildStatRow('Duration', '${_progress!.durationSeconds!.toStringAsFixed(1)}s'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_progress!.status == 'running' && !_progress!.isPaused)
                          ApexButton(
                            label: 'Pause',
                            onPressed: _pauseSync,
                            type: ApexButtonType.secondary,
                            icon: Icons.pause,
                          ),
                        if (_progress!.isPaused)
                          ApexButton(
                            label: 'Resume',
                            onPressed: _resumeSync,
                            type: ApexButtonType.success,
                            icon: Icons.play_arrow,
                          ),
                        if (_progress!.status == 'running' || _progress!.isPaused)
                          ApexButton(
                            label: 'Cancel',
                            onPressed: _cancelSync,
                            type: ApexButtonType.danger,
                            icon: Icons.cancel,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              ApexCard(
                child: Row(
                  children: [
                    Icon(Icons.error, color: ApexColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: ApexTypography.body.copyWith(color: ApexColors.error))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ApexButton(
              label: _isSyncing ? 'Syncing...' : 'Start Import',
              onPressed: _isSyncing ? null : _startSync,
              type: ApexButtonType.primary,
              icon: Icons.sync,
              loading: _isSyncing,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRange == value,
      selectedColor: ApexColors.primary.withValues(alpha: 0.15),
      labelStyle: ApexTypography.body.copyWith(
        color: _selectedRange == value ? ApexColors.primary : ApexColors.neutral700,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedRange = value);
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.body),
          Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String get _statusText {
    if (_progress == null) return '';
    switch (_progress!.status) {
      case 'running':
        return _progress!.isPaused ? 'Paused' : 'Syncing...';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return _progress!.status;
    }
  }

  Color get _statusColor {
    if (_progress == null) return ApexColors.neutral500;
    switch (_progress!.status) {
      case 'running':
        return _progress!.isPaused ? ApexColors.warning : ApexColors.primary;
      case 'completed':
        return ApexColors.success;
      case 'failed':
        return ApexColors.error;
      case 'cancelled':
        return ApexColors.neutral500;
      default:
        return ApexColors.neutral500;
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case '30':
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case '90':
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case '180':
        return DateTimeRange(start: now.subtract(const Duration(days: 180)), end: now);
      case '365':
        return DateTimeRange(start: now.subtract(const Duration(days: 365)), end: now);
      case 'custom':
        return DateTimeRange(
          start: _customFrom ?? now.subtract(const Duration(days: 30)),
          end: _customTo ?? now,
        );
      default:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_customFrom ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_customTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ApexColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ApexColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _customFrom = picked;
        else _customTo = picked;
      });
    }
  }

  Future<void> _startSync() async {
    if (_selectedRange == 'custom' && (_customFrom == null || _customTo == null)) {
      setState(() => _error = 'Please select both dates for custom range');
      return;
    }

    setState(() {
      _isSyncing = true;
      _error = null;
      _progress = null;
    });

    try {
      final range = _getDateRange();
      final fromStr = DateFormat('yyyy-MM-dd').format(range.start);
      final toStr = DateFormat('yyyy-MM-dd').format(range.end);

      final service = ref.read(esslServiceProvider);
      final result = await service.initialSyncAttendance(widget.serverId, fromStr, toStr);

      setState(() {
        _activeSyncId = result.id;
        _progress = SyncProgress(
          id: result.id,
          status: result.status,
          progressPercent: result.progressPercent,
          totalRecordsExpected: result.totalRecordsExpected,
          currentBatch: result.currentBatch,
          totalBatches: result.totalBatches,
          recordsFetched: result.recordsFetched,
          recordsCreated: result.recordsCreated,
          recordsUpdated: result.recordsUpdated,
          recordsSkipped: result.recordsSkipped,
          recordsFailed: result.recordsFailed,
          isPaused: result.isPaused,
          isCancelled: result.isCancelled,
          startedAt: result.startedAt.toIso8601String(),
          durationSeconds: result.durationSeconds,
        );
        _isSyncing = false;
      });

      if (result.status == 'running') {
        _pollProgress();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSyncing = false;
      });
    }
  }

  Future<void> _pollProgress() async {
    if (_activeSyncId == null) return;

    final service = ref.read(esslServiceProvider);
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final progress = await service.getSyncProgress(widget.serverId, _activeSyncId!);
        setState(() => _progress = progress);
        if (progress.status != 'running') break;
      } catch (e) {
        break;
      }
    }
  }

  Future<void> _pauseSync() async {
    if (_activeSyncId == null) return;
    final service = ref.read(esslServiceProvider);
    await service.pauseSync(widget.serverId, _activeSyncId!);
  }

  Future<void> _resumeSync() async {
    if (_activeSyncId == null) return;
    final service = ref.read(esslServiceProvider);
    await service.resumeSync(widget.serverId, _activeSyncId!);
    _pollProgress();
  }

  Future<void> _cancelSync() async {
    if (_activeSyncId == null) return;
    final service = ref.read(esslServiceProvider);
    await service.cancelSync(widget.serverId, _activeSyncId!);
  }
}
