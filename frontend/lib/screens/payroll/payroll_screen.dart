import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../design_system/colors.dart';


class PayslipItem {
  final String id, employeeId, status;
  final int month, year, workingDays, presentDays, absentDays, leaveDays, lopDays;
  final double basic, hra, da, conveyance, medical, special, grossEarnings, pf, esi, pt, it, totalDeductions, netPay, otHours, otAmount, lopAmount;
  PayslipItem({required this.id, required this.employeeId, required this.month, required this.year, required this.status, required this.basic, required this.hra, required this.da, required this.conveyance, required this.medical, required this.special, required this.grossEarnings, required this.pf, required this.esi, required this.pt, required this.it, required this.totalDeductions, required this.netPay, required this.workingDays, required this.presentDays, required this.absentDays, required this.leaveDays, required this.otHours, required this.otAmount, required this.lopDays, required this.lopAmount});
  factory PayslipItem.fromJson(Map<String, dynamic> json) => PayslipItem(
    id: json['id'], employeeId: json['employee_id'], month: json['month'], year: json['year'], status: json['status'] ?? 'draft',
    basic: (json['basic'] as num).toDouble(), hra: (json['hra'] as num).toDouble(), da: (json['da'] as num).toDouble(),
    conveyance: (json['conveyance'] as num).toDouble(), medical: (json['medical'] as num).toDouble(), special: (json['special'] as num).toDouble(),
    grossEarnings: (json['gross_earnings'] as num).toDouble(), pf: (json['pf'] as num).toDouble(), esi: (json['esi'] as num).toDouble(),
    pt: (json['pt'] as num).toDouble(), it: (json['it'] as num).toDouble(), totalDeductions: (json['total_deductions'] as num).toDouble(),
    netPay: (json['net_pay'] as num).toDouble(), workingDays: json['working_days'] ?? 0, presentDays: json['present_days'] ?? 0,
    absentDays: json['absent_days'] ?? 0, leaveDays: json['leave_days'] ?? 0, otHours: (json['ot_hours'] as num?)?.toDouble() ?? 0,
    otAmount: (json['ot_amount'] as num?)?.toDouble() ?? 0, lopDays: json['lop_days'] ?? 0, lopAmount: (json['lop_amount'] as num?)?.toDouble() ?? 0,
  );
}

final payrollTabProvider = StateProvider<int>((ref) => 0);

final payslipListProvider = StateNotifierProvider<PayslipListNotifier, AsyncValue<List<PayslipItem>>>((ref) => PayslipListNotifier(ref.read(dioProvider)));

class PayslipListNotifier extends StateNotifier<AsyncValue<List<PayslipItem>>> {
  final dynamic _dio;
  PayslipListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false, int? month, int? year}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;
      if (year != null) params['year'] = year;
      final r = await _dio.get('/payroll/payslips', queryParameters: params);
      state = AsyncValue.data((r.data as List).map((e) => PayslipItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<Map<String, dynamic>> generate(int month, int year) async {
    final r = await _dio.post('/payroll/payslips/generate', queryParameters: {'month': month, 'year': year});
    await fetch(isRefresh: true, month: month, year: year);
    return r.data as Map<String, dynamic>;
  }

  Future<void> freeze(String id) async {
    await _dio.put('/payroll/payslips/$id/freeze');
    if (state.value != null) state = AsyncValue.data(state.value!.map((p) => p.id == id ? PayslipItem(id: p.id, employeeId: p.employeeId, month: p.month, year: p.year, status: 'frozen', basic: p.basic, hra: p.hra, da: p.da, conveyance: p.conveyance, medical: p.medical, special: p.special, grossEarnings: p.grossEarnings, pf: p.pf, esi: p.esi, pt: p.pt, it: p.it, totalDeductions: p.totalDeductions, netPay: p.netPay, workingDays: p.workingDays, presentDays: p.presentDays, absentDays: p.absentDays, leaveDays: p.leaveDays, otHours: p.otHours, otAmount: p.otAmount, lopDays: p.lopDays, lopAmount: p.lopAmount) : p).toList());
  }
}

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(payrollTabProvider);
    final slipsAsync = ref.watch(payslipListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Payroll'),
      body: Column(children: [
        Container(color: Colors.white, child: Row(children: [
          _tab('Payslips', 0, tab, ref),
          _tab('Generate', 1, tab, ref),
        ])),
        Expanded(child: tab == 0 ? _payslipsList(slipsAsync, ref) : _generateTab(context, ref)),
      ]),
    );
  }

  Widget _tab(String label, int index, int current, WidgetRef ref) {
    final active = index == current;
    return Expanded(child: InkWell(
      onTap: () => ref.read(payrollTabProvider.notifier).state = index,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? ApexColors.primary : ApexColors.neutral200, width: 2))),
        child: Text(label, textAlign: TextAlign.center, style: ApexTypography.body.copyWith(color: active ? ApexColors.primary : ApexColors.neutral500, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    ));
  }

  Widget _payslipsList(AsyncValue<List<PayslipItem>> slipsAsync, WidgetRef ref) {
    return slipsAsync.when(
      data: (slips) {
        if (slips.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long, size: 48, color: ApexColors.neutral500),
          const SizedBox(height: 16),
          Text('No Payslips', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('Generate payslips from the Generate tab', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
        ]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: slips.length, itemBuilder: (context, i) {
          final p = slips[i];
          final statusColor = p.status == 'frozen' ? ApexColors.primary : p.status == 'paid' ? ApexColors.success : ApexColors.neutral500;
          final monthName = DateFormat('MMMM').format(DateTime(p.year, p.month));
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)), child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: ApexColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${p.month}', style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
              Text(p.year.toString().substring(2), style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(monthName, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
              Text('P: ${p.presentDays} | A: ${p.absentDays} | HD: ${p.leaveDays} | OT: ${p.otHours.toStringAsFixed(1)}h', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${p.netPay.toStringAsFixed(0)}', style: ApexTypography.titleSmall.copyWith(color: ApexColors.success)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(p.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
            ]),
            if (p.status == 'calculated') IconButton(icon: Icon(Icons.lock, size: 16, color: ApexColors.primary), onPressed: () => ref.read(payslipListProvider.notifier).freeze(p.id)),
          ]));
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _generateTab(BuildContext context, WidgetRef ref) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    return StatefulBuilder(builder: (context, setS) => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Generate Payslips', style: ApexTypography.sectionTitle),
      const SizedBox(height: 8),
      Text('Select month and year to generate payslips for all active employees.', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: DropdownButtonFormField<int>(value: selectedMonth, decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()), items: [for (int i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(months[i - 1]))], onChanged: (v) => setS(() => selectedMonth = v ?? selectedMonth))),
        const SizedBox(width: 16),
        Expanded(child: DropdownButtonFormField<int>(value: selectedYear, decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()), items: [for (int y = 2024; y <= 2030; y++) DropdownMenuItem(value: y, child: Text('$y'))], onChanged: (v) => setS(() => selectedYear = v ?? selectedYear))),
      ]),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating payslips...')));
          try {
            final result = await ref.read(payslipListProvider.notifier).generate(selectedMonth, selectedYear);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated ${result['generated']} payslips'), backgroundColor: ApexColors.success));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error));
          }
        },
        icon: const Icon(Icons.calculate, size: 18),
        label: const Text('Generate Payslips'),
        style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
      )),
    ])));
  }
}





