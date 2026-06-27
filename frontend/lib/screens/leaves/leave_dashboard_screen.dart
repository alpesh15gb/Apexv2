import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';

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
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('Leave Management', style: ApexTypography.sectionTitle),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ApexCard(
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: ApexColors.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Failed to load stats', style: ApexTypography.body.copyWith(color: ApexColors.error))),
                    ApexButton(label: 'Retry', type: ApexButtonType.outline, onPressed: () => ref.invalidate(leaveStatsProvider)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FiltersBar(),
            const SizedBox(height: 16),
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
      _StatCard(title: 'On Leave Today', value: '${stats['on_leave_today'] ?? 0}', icon: Icons.event_busy, color: ApexColors.primary),
      _StatCard(title: 'Pending Requests', value: '${stats['pending'] ?? 0}', icon: Icons.pending, color: ApexColors.warning),
      _StatCard(title: 'Approved', value: '${stats['approved'] ?? 0}', icon: Icons.check_circle, color: ApexColors.success),
      _StatCard(title: 'Rejected', value: '${stats['rejected'] ?? 0}', icon: Icons.cancel, color: ApexColors.error),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
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
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Text(value, style: ApexTypography.kpiValue.copyWith(color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: ApexTypography.kpiLabel),
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
    return ApexCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statusChip('All', null),
          _statusChip('Pending', 'pending'),
          _statusChip('Approved', 'approved'),
          _statusChip('Rejected', 'rejected'),
          _statusChip('Cancelled', 'cancelled'),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.download, size: 18, color: ApexColors.neutral500),
            onPressed: () {},
          ),
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
        label: Text(label, style: ApexTypography.captionSmall.copyWith(
          color: isActive ? ApexColors.primary : ApexColors.neutral500,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        )),
        selected: isActive,
        onSelected: (_) => ref.read(leaveRequestsProvider.notifier).setFilter(status: status),
        selectedColor: ApexColors.primary50,
        side: BorderSide(color: isActive ? ApexColors.primary : ApexColors.neutral200),
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
      return const ApexCard(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.requests.isEmpty) {
      return ApexCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 40, color: ApexColors.neutral300),
                const SizedBox(height: 12),
                Text('No leave requests', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
        ),
      );
    }

    return ApexCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ApexColors.neutral50,
                border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
              ),
              child: Row(children: [
                SizedBox(width: 180, child: Text('EMPLOYEE', style: ApexTypography.sectionHeader)),
                SizedBox(width: 100, child: Text('LEAVE TYPE', style: ApexTypography.sectionHeader)),
                SizedBox(width: 100, child: Text('FROM', style: ApexTypography.sectionHeader)),
                SizedBox(width: 100, child: Text('TO', style: ApexTypography.sectionHeader)),
                SizedBox(width: 60, child: Text('DAYS', style: ApexTypography.sectionHeader)),
                SizedBox(width: 80, child: Text('STATUS', style: ApexTypography.sectionHeader)),
                SizedBox(width: 120, child: Text('ACTIONS', style: ApexTypography.sectionHeader)),
              ]),
            ),
          ...state.requests.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final status = r['status'] ?? 'pending';
            final isPending = status == 'pending';

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: ApexColors.neutral100, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: ApexColors.primary50,
                        child: Text(
                          (r['employee_name'] ?? '?')[0].toUpperCase(),
                          style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['employee_name'] ?? '—', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        Text(r['leave_type_name'] ?? '—', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ])),
                      _statusBadge(status),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text('${r['start_date'] ?? ''} → ${r['end_date'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                      const Spacer(),
                      Text('${r['days'] ?? 1} day(s)', style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                    ]),
                    if (r['reason'] != null && r['reason'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r['reason'], style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: ApexButton(
                            label: 'Reject',
                            type: ApexButtonType.danger,
                            onPressed: () => _rejectDialog(context, ref, r['id']),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ApexButton(
                            label: 'Approve',
                            type: ApexButtonType.success,
                            onPressed: () => ref.read(leaveRequestsProvider.notifier).approve(r['id']),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: i.isEven ? Colors.white : ApexColors.neutral50,
              child: Row(children: [
                SizedBox(width: 180, child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ApexColors.primary50,
                    child: Text(
                      (r['employee_name'] ?? '?')[0].toUpperCase(),
                      style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r['employee_name'] ?? '—', style: ApexTypography.table, overflow: TextOverflow.ellipsis)),
                ])),
                SizedBox(width: 100, child: Text(r['leave_type_name'] ?? '—', style: ApexTypography.table.copyWith(color: ApexColors.neutral600))),
                SizedBox(width: 100, child: Text(r['start_date'] ?? '—', style: ApexTypography.table)),
                SizedBox(width: 100, child: Text(r['end_date'] ?? '—', style: ApexTypography.table)),
                SizedBox(width: 60, child: Text('${r['days'] ?? 1}', style: ApexTypography.table.copyWith(fontWeight: FontWeight.w600))),
                SizedBox(width: 80, child: _statusBadge(status)),
                SizedBox(
                  width: 120,
                  child: isPending
                      ? Row(children: [
                          IconButton(
                            icon: Icon(Icons.check, size: 16, color: ApexColors.success),
                            onPressed: () => ref.read(leaveRequestsProvider.notifier).approve(r['id']),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: ApexColors.error),
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
              decoration: BoxDecoration(border: Border(top: BorderSide(color: ApexColors.neutral200))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${state.total} requests', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.page > 1 ? () => ref.read(leaveRequestsProvider.notifier).fetch(page: state.page - 1) : null,
                  ),
                  Text('Page ${state.page} of ${state.totalPages}', style: ApexTypography.caption),
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
    switch (status) {
      case 'approved':
        return ApexBadge.success('Approved');
      case 'rejected':
        return ApexBadge.danger('Rejected');
      case 'pending':
        return ApexBadge.warning('Pending');
      case 'cancelled':
        return ApexBadge(label: 'Cancelled');
      default:
        return ApexBadge(label: status);
    }
  }

  void _rejectDialog(BuildContext context, WidgetRef ref, String requestId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Leave Request', style: ApexTypography.sectionTitle),
        content: ApexTextField(
          label: 'Rejection Reason',
          controller: reasonCtrl,
          maxLines: 3,
          required: true,
        ),
        actions: [
          ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
          ApexButton(label: 'Reject', type: ApexButtonType.danger, onPressed: () {
            ref.read(leaveRequestsProvider.notifier).reject(requestId, reasonCtrl.text);
            Navigator.pop(ctx);
          }),
        ],
      ),
    );
  }
}
