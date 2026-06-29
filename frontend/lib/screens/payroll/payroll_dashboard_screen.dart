import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../design_system/typography.dart';
import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

final payrollStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return {
    'to_process': 42,
    'processed': 38,
    'net_salary': 450000.0,
    'gross_salary': 480000.0,
    'total_deductions': 30000.0,
    'payroll_cost': 510000.0,
  };
});

final payslipsProvider = StateNotifierProvider<PayslipsNotifier, PayslipsState>((ref) {
  return PayslipsNotifier();
});

class PayslipsState {
  final List<Map<String, dynamic>> payslips;
  final bool loading;
  final int month;
  final int year;

  PayslipsState({
    this.payslips = const [],
    this.loading = false,
    required this.month,
    required this.year,
  });

  PayslipsState copyWith({
    List<Map<String, dynamic>>? payslips,
    bool? loading,
    int? month,
    int? year,
  }) {
    return PayslipsState(
      payslips: payslips ?? this.payslips,
      loading: loading ?? this.loading,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

class PayslipsNotifier extends StateNotifier<PayslipsState> {
  PayslipsNotifier() : super(PayslipsState(month: DateTime.now().month, year: DateTime.now().year)) {
    fetch();
  }

  Future<void> fetch({int? month, int? year}) async {
    state = state.copyWith(loading: true, month: month, year: year);
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      loading: false,
      payslips: [
        {
          'id': 'PS001',
          'employee_name': 'Rahul Sharma',
          'employee_code': 'EMP001',
          'gross_earnings': 45000.0,
          'total_deductions': 3000.0,
          'net_pay': 42000.0,
          'status': 'processed',
        },
        {
          'id': 'PS002',
          'employee_name': 'Priya Patel',
          'employee_code': 'EMP002',
          'gross_earnings': 48000.0,
          'total_deductions': 3200.0,
          'net_pay': 44800.0,
          'status': 'paid',
        },
      ],
    );
  }

  Future<void> processPayroll() async {
    state = state.copyWith(loading: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(loading: false);
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
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Payroll Management',
        description: 'Process employee salary slips, configure statutory rules, and run payroll cycles.',
        onRefresh: () {
          ref.invalidate(payrollStatsProvider);
          ref.read(payslipsProvider.notifier).fetch();
        },
        actions: [
          ApexButton(
            label: 'Salary Structures',
            icon: Icons.layers_outlined,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/payroll/salary-structures'),
          ),
          const SizedBox(width: 4),
          ApexButton(
            label: 'Run Payroll',
            onPressed: payState.loading ? null : () async {
              final monthName = DateFormat('MMMM').format(DateTime(payState.year, payState.month));
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Payroll Run'),
                  content: Text('Are you sure you want to run calculations for all active employees for $monthName ${payState.year}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm Run', style: TextStyle(color: ApexColors.primary))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(payslipsProvider.notifier).processPayroll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payroll processed successfully'), backgroundColor: ApexColors.success),
                  );
                }
              }
            },
            type: ApexButtonType.primary,
            icon: Icons.play_circle_outline,
            loading: payState.loading,
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
              ),
              const SizedBox(height: 16),
              _ActionRow(
                onProcess: () {}, // Not used since it is moved to top bar action
                loading: payState.loading,
              ),
              const SizedBox(height: 16),
              _PayslipsTable(state: payState, isMobile: isMobile),
            ],
          ),
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
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          const Spacer(),
          Column(
            children: [
              Text(monthName, style: ApexTypography.sectionTitle.copyWith(fontSize: 18)),
              Text('$year', style: ApexTypography.caption),
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
      _StatCard(title: 'To Process', value: '${stats['to_process'] ?? 0}', icon: Icons.people, color: ApexColors.primary),
      _StatCard(title: 'Processed', value: '${stats['processed'] ?? 0}', icon: Icons.check_circle, color: ApexColors.success),
      _StatCard(title: 'Net Salary', value: '₹${_formatAmount(stats['net_salary'] ?? 0)}', icon: Icons.payments, color: ApexColors.success),
      _StatCard(title: 'Gross Salary', value: '₹${_formatAmount(stats['gross_salary'] ?? 0)}', icon: Icons.account_balance_wallet, color: ApexColors.primary),
      _StatCard(title: 'Deductions', value: '₹${_formatAmount(stats['total_deductions'] ?? 0)}', icon: Icons.remove_circle, color: ApexColors.error),
      _StatCard(title: 'Payroll Cost', value: '₹${_formatAmount(stats['payroll_cost'] ?? 0)}', icon: Icons.trending_up, color: ApexColors.warning),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 320) / 3.2,
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
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
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
            Text(value, style: ApexTypography.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: ApexTypography.captionMedium),
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
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          ApexButton(
            label: 'Export Pay Register',
            icon: Icons.download,
            type: ApexButtonType.outline,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          ApexButton(
            label: 'Bank Advice',
            icon: Icons.receipt,
            type: ApexButtonType.outline,
            onPressed: () {},
          ),
          const Spacer(),
          ApexButton(
            label: 'Lock Payroll',
            icon: Icons.lock_outline,
            type: ApexButtonType.outline,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payroll period locked successfully'), backgroundColor: ApexColors.success),
              );
            },
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
        height: 136,
        decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Center(child: Text('No payslips for this month', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: ApexColors.neutral50,
              child: Row(children: [
                SizedBox(width: 180, child: Text('EMPLOYEE', style: ApexTypography.tableHeader)),
                SizedBox(width: 100, child: Text('GROSS', style: ApexTypography.tableHeader)),
                SizedBox(width: 100, child: Text('DEDUCTIONS', style: ApexTypography.tableHeader)),
                SizedBox(width: 100, child: Text('NET PAY', style: ApexTypography.tableHeader)),
                SizedBox(width: 80, child: Text('STATUS', style: ApexTypography.tableHeader)),
                const SizedBox(width: 60),
              ]),
            ),
          ...state.payslips.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final status = p['status'] ?? 'draft';

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ApexColors.neutral200, width: 0.5))),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ApexColors.primary.withOpacity(0.1),
                    child: Text((p['employee_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.captionMedium.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['employee_name'] ?? '—', style: ApexTypography.titleMedium),
                    Text('Net: ₹${p['net_pay'] ?? 0}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.success)),
                  ])),
                  _statusBadge(status),
                ]),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: i.isEven ? ApexColors.neutral0 : ApexColors.neutral50,
              child: Row(children: [
                SizedBox(width: 180, child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ApexColors.primary.withOpacity(0.1),
                    child: Text((p['employee_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['employee_name'] ?? '—', style: ApexTypography.table, overflow: TextOverflow.ellipsis),
                      Text(p['employee_code'] ?? '', style: ApexTypography.captionSmall),
                    ],
                  )),
                ])),
                SizedBox(width: 100, child: Text('₹${p['gross_earnings'] ?? 0}', style: ApexTypography.table)),
                SizedBox(width: 100, child: Text('₹${p['total_deductions'] ?? 0}', style: ApexTypography.table.copyWith(color: ApexColors.error))),
                SizedBox(width: 100, child: Text('₹${p['net_pay'] ?? 0}', style: ApexTypography.table.copyWith(fontWeight: FontWeight.w600, color: ApexColors.success))),
                SizedBox(width: 80, child: _statusBadge(status)),
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.download, size: 16, color: ApexColors.neutral500),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading payslip PDF...'), backgroundColor: ApexColors.success),
                      );
                    },
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
    ApexBadgeType type;
    switch (status) {
      case 'paid': type = ApexBadgeType.success; break;
      case 'processed': type = ApexBadgeType.info; break;
      case 'locked': type = ApexBadgeType.warning; break;
      default: type = ApexBadgeType.neutral;
    }
    return ApexBadge(label: status, type: type);
  }
}
