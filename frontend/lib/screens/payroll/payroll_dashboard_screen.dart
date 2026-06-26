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

final payrollStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final now = DateTime.now();
    final res = await dio.get('/payroll/stats', queryParameters: {'month': now.month, 'year': now.year});
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final payslipsProvider = StateNotifierProvider<PayslipsNotifier, PayslipsState>((ref) {
  return PayslipsNotifier(ref.read(dioProvider));
});

class PayslipsState {
  final List<Map<String, dynamic>> payslips;
  final bool loading;
  final String? error;
  final int month;
  final int year;

  PayslipsState({
    this.payslips = const [],
    this.loading = false,
    this.error,
    int? month,
    int? year,
  })  : month = month ?? DateTime.now().month,
        year = year ?? DateTime.now().year;

  PayslipsState copyWith({
    List<Map<String, dynamic>>? payslips,
    bool? loading,
    String? error,
    int? month,
    int? year,
  }) {
    return PayslipsState(
      payslips: payslips ?? this.payslips,
      loading: loading ?? this.loading,
      error: error,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

class PayslipsNotifier extends StateNotifier<PayslipsState> {
  final dynamic _dio;
  PayslipsNotifier(this._dio) : super(PayslipsState()) {
    fetch();
  }

  Future<void> fetch({int? month, int? year}) async {
    if (month != null) state = state.copyWith(month: month);
    if (year != null) state = state.copyWith(year: year);
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _dio.get('/payroll/payslips', queryParameters: {
        'month': state.month,
        'year': state.year,
        'page': 1,
        'page_size': 100,
      });
      final data = res.data;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? data is List ? data : []);
      state = state.copyWith(payslips: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> processPayroll() async {
    state = state.copyWith(loading: true);
    try {
      await _dio.post('/payroll/process', data: {'month': state.month, 'year': state.year});
      fetch();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

class PayrollDashboardScreen extends ConsumerWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(payrollStatsProvider);
    final payState = ref.watch(payslipsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Payroll', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/payroll/salary-structures'),
            icon: const Icon(Icons.account_balance, size: 16),
            label: const Text('Salary Structures'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/payroll/loans'),
            icon: const Icon(Icons.money, size: 16),
            label: const Text('Loans'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthSelector(
              month: payState.month,
              year: payState.year,
              onPrev: () {
                final m = payState.month == 1 ? 12 : payState.month - 1;
                final y = payState.month == 1 ? payState.year - 1 : payState.year;
                ref.read(payslipsProvider.notifier).fetch(month: m, year: y);
              },
              onNext: () {
                final m = payState.month == 12 ? 1 : payState.month + 1;
                final y = payState.month == 12 ? payState.year + 1 : payState.year;
                ref.read(payslipsProvider.notifier).fetch(month: m, year: y);
              },
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => _StatsGrid(stats: stats, isMobile: isMobile),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: _danger)),
            ),
            const SizedBox(height: 16),
            _ActionRow(
              onProcess: () => ref.read(payslipsProvider.notifier).processPayroll(),
              loading: payState.loading,
            ),
            const SizedBox(height: 16),
            _PayslipsTable(state: payState, isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({required this.month, required this.year, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          const Spacer(),
          Column(
            children: [
              Text(monthName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              Text('$year', style: const TextStyle(fontSize: 13, color: _muted)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isMobile;

  const _StatsGrid({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(title: 'To Process', value: '${stats['to_process'] ?? 0}', icon: Icons.people, color: _primary),
      _StatCard(title: 'Processed', value: '${stats['processed'] ?? 0}', icon: Icons.check_circle, color: _success),
      _StatCard(title: 'Net Salary', value: '₹${_formatAmount(stats['net_salary'] ?? 0)}', icon: Icons.payments, color: _success),
      _StatCard(title: 'Gross Salary', value: '₹${_formatAmount(stats['gross_salary'] ?? 0)}', icon: Icons.account_balance_wallet, color: _primary),
      _StatCard(title: 'Deductions', value: '₹${_formatAmount(stats['total_deductions'] ?? 0)}', icon: Icons.remove_circle, color: _danger),
      _StatCard(title: 'Payroll Cost', value: '₹${_formatAmount(stats['payroll_cost'] ?? 0)}', icon: Icons.trending_up, color: _warning),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 3,
        child: c,
      )).toList(),
    );
  }

  String _formatAmount(dynamic amount) {
    final val = (amount as num?)?.toDouble() ?? 0;
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
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
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onProcess;
  final bool loading;

  const _ActionRow({required this.onProcess, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: loading ? null : onProcess,
            icon: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(loading ? 'Processing...' : 'Run Payroll'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.receipt, size: 16),
            label: const Text('Bank Advice'),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock, size: 16),
            label: const Text('Lock Payroll'),
          ),
        ],
      ),
    );
  }
}

class _PayslipsTable extends StatelessWidget {
  final PayslipsState state;
  final bool isMobile;

  const _PayslipsTable({required this.state, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.payslips.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (state.payslips.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: const Center(child: Text('No payslips for this month', style: TextStyle(color: _muted))),
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
                SizedBox(width: 100, child: Text('GROSS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('DEDUCTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 100, child: Text('NET PAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                SizedBox(width: 60, child: Text('', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted))),
              ]),
            ),
          ...state.payslips.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final status = p['status'] ?? 'draft';

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5))),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text((p['employee_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['employee_name'] ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    Text('Net: ₹${p['net_pay'] ?? 0}', style: const TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w600)),
                  ])),
                  _statusBadge(status),
                ]),
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
                    child: Text((p['employee_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['employee_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis),
                      Text(p['employee_code'] ?? '', style: const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  )),
                ])),
                SizedBox(width: 100, child: Text('₹${p['gross_earnings'] ?? 0}', style: const TextStyle(fontSize: 13, color: _text))),
                SizedBox(width: 100, child: Text('₹${p['total_deductions'] ?? 0}', style: const TextStyle(fontSize: 13, color: _danger))),
                SizedBox(width: 100, child: Text('₹${p['net_pay'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _success))),
                SizedBox(width: 80, child: _statusBadge(status)),
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.download, size: 16, color: _muted),
                    onPressed: () {},
                    tooltip: 'Download Payslip',
                  ),
                ),
              ]),
            );
          }),
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
      case 'paid': return _success;
      case 'processed': return _primary;
      case 'draft': return _muted;
      case 'locked': return _warning;
      default: return _muted;
    }
  }
}
