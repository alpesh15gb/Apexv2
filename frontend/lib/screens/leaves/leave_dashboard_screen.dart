import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final leaveStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/leaves/stats');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final leaveRequestsProvider = StateNotifierProvider<LeaveRequestsNotifier, LeaveRequestsState>((ref) {
  return LeaveRequestsNotifier(ref.read(dioProvider));
});

class LeaveRequestsState {
  final List<Map<String, dynamic>> requests;
  final bool loading;
  final String? error;
  final int page;
  final int total;
  final int totalPages;
  final String? statusFilter;

  LeaveRequestsState({
    this.requests = const [],
    this.loading = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.statusFilter,
  });

  LeaveRequestsState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? loading,
    String? error,
    int? page,
    int? total,
    int? totalPages,
    String? statusFilter,
  }) {
    return LeaveRequestsState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      error: error,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class LeaveRequestsNotifier extends StateNotifier<LeaveRequestsState> {
  final dynamic _dio;
  LeaveRequestsNotifier(this._dio) : super(LeaveRequestsState()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 20};
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final res = await _dio.get('/leaves/requests', queryParameters: params);
      final data = res.data;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      state = state.copyWith(
        requests: items,
        loading: false,
        total: data['total'] ?? 0,
        totalPages: data['total_pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter({String? status}) {
    state = state.copyWith(statusFilter: status);
    fetch();
  }

  Future<void> approve(String requestId) async {
    try {
      await _dio.put('/leaves/requests/$requestId/approve');
      fetch(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reject(String requestId, String reason) async {
    try {
      await _dio.put('/leaves/requests/$requestId/reject', data: {'reason': reason});
      fetch(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class LeaveDashboardScreen extends ConsumerWidget {
  const LeaveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(leaveStatsProvider);
    final reqState = ref.watch(leaveRequestsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Leave Management', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/leaves/types'),
            icon: const Icon(Icons.category, size: 16),
            label: const Text('Leave Types'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/leaves/calendar'),
            icon: const Icon(Icons.calendar_month, size: 16),
            label: const Text('Calendar'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/holidays'),
            icon: const Icon(Icons.celebration, size: 16),
            label: const Text('Holidays'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: _danger)),
            ),
            const SizedBox(height: 16),
            _FiltersBar(),
            const SizedBox(height: 12),
            _LeaveRequestsTable(state: reqState, isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final cards = [
      _StatCard(title: 'On Leave Today', value: '${stats['on_leave_today'] ?? 0}', icon: Icons.event_busy, color: _primary),
      _StatCard(title: 'Pending Requests', value: '${stats['pending'] ?? 0}', icon: Icons.pending, color: _warning),
      _StatCard(title: 'Approved', value: '${stats['approved'] ?? 0}', icon: Icons.check_circle, color: _success),
      _StatCard(title: 'Rejected', value: '${stats['rejected'] ?? 0}', icon: Icons.cancel, color: _danger),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 4,
        child: c,
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Row(
        children: [
          _statusChip('All', null),
          _statusChip('Pending', 'pending'),
          _statusChip('Approved', 'approved'),
          _statusChip('Rejected', 'rejected'),
          _statusChip('Cancelled', 'cancelled'),
          const Spacer(),
          IconButton(icon: const Icon(Icons.download, size: 18, color: _muted), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String? status) {
    final current = ref.watch(leaveRequestsProvider).statusFilter;
    final isActive = current == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isActive ? _primary : _muted)),
        selected: isActive,
        onSelected: (_) => ref.read(leaveRequestsProvider.notifier).setFilter(status: status),
        selectedColor: _primary.withOpacity(0.1),
        side: BorderSide(color: isActive ? _primary : _border),
      ),
    );
  }
}

class _LeaveRequestsTable extends ConsumerWidget {
  final LeaveRequestsState state;
  final bool isMobile;

  const _LeaveRequestsTable({required this.state, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading && state.requests.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (state.requests.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: const Center(child: Text('No leave requests', style: TextStyle(color: _muted))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _bg,
              child: Row(children: const [
                SizedBox(width: 180, child: Text('EMPLOYEE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('LEAVE TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('FROM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('TO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 60, child: Text('DAYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 120, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
              ]),
            ),
          ...state.requests.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final status = r['status'] ?? 'pending';
            final isPending = status == 'pending';

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _primary.withOpacity(0.1),
                        child: Text((r['employee_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['employee_name'] ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                        Text(r['leave_type_name'] ?? '—', style: const TextStyle(fontSize: 11, color: _muted)),
                      ])),
                      _statusBadge(status),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('${r['start_date'] ?? ''} → ${r['end_date'] ?? ''}', style: const TextStyle(fontSize: 12, color: _muted)),
                      const Spacer(),
                      Text('${r['days'] ?? 1} day(s)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                    ]),
                    if (r['reason'] != null && r['reason'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r['reason'], style: const TextStyle(fontSize: 12, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectDialog(context, ref, r['id']),
                            style: OutlinedButton.styleFrom(foregroundColor: _danger, side: const BorderSide(color: _danger)),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => ref.read(leaveRequestsProvider.notifier).approve(r['id']),
                            style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white),
                            child: const Text('Approve', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: i.isEven ? _surface : _bg,
              child: Row(children: [
                SizedBox(width: 180, child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text((r['employee_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r['employee_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
                ])),
                SizedBox(width: 100, child: Text(r['leave_type_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _muted))),
                SizedBox(width: 100, child: Text(r['start_date'] ?? '—', style: const TextStyle(fontSize: 13, color: _text))),
                SizedBox(width: 100, child: Text(r['end_date'] ?? '—', style: const TextStyle(fontSize: 13, color: _text))),
                SizedBox(width: 60, child: Text('${r['days'] ?? 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text))),
                SizedBox(width: 80, child: _statusBadge(status)),
                SizedBox(
                  width: 120,
                  child: isPending
                      ? Row(children: [
                          IconButton(
                            icon: const Icon(Icons.check, size: 16, color: _success),
                            onPressed: () => ref.read(leaveRequestsProvider.notifier).approve(r['id']),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: _danger),
                            onPressed: () => _rejectDialog(context, ref, r['id']),
                            tooltip: 'Reject',
                          ),
                        ])
                      : const SizedBox.shrink(),
                ),
              ]),
            );
          }),
          if (state.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${state.total} requests', style: const TextStyle(fontSize: 13, color: _muted)),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.page > 1 ? () => ref.read(leaveRequestsProvider.notifier).fetch(page: state.page - 1) : null,
                  ),
                  Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontSize: 13, color: _text)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.page < state.totalPages ? () => ref.read(leaveRequestsProvider.notifier).fetch(page: state.page + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return _success;
      case 'rejected': return _danger;
      case 'pending': return _warning;
      case 'cancelled': return _muted;
      default: return _muted;
    }
  }

  void _rejectDialog(BuildContext context, WidgetRef ref, String requestId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Rejection Reason', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(leaveRequestsProvider.notifier).reject(requestId, reasonCtrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
