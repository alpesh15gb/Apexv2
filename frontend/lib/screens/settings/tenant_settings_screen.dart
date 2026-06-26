import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class TenantSettings {
  final int attendanceYearStartMonth, attendanceYearStartDay, minPunchDifferenceMinutes, punchBeginBeforeMinutes;
  final bool autoShiftIfNoSchedule, fixedShiftMode;

  TenantSettings({required this.attendanceYearStartMonth, required this.attendanceYearStartDay, required this.minPunchDifferenceMinutes, required this.punchBeginBeforeMinutes, required this.autoShiftIfNoSchedule, required this.fixedShiftMode});

  factory TenantSettings.fromJson(Map<String, dynamic> json) => TenantSettings(
    attendanceYearStartMonth: json['attendance_year_start_month'] ?? 1, attendanceYearStartDay: json['attendance_year_start_day'] ?? 1,
    minPunchDifferenceMinutes: json['min_punch_difference_minutes'] ?? 1, punchBeginBeforeMinutes: json['punch_begin_before_minutes'] ?? 60,
    autoShiftIfNoSchedule: json['auto_shift_if_no_schedule'] ?? true, fixedShiftMode: json['fixed_shift_mode'] ?? false,
  );
}

final tenantSettingsProvider = StateNotifierProvider<TenantSettingsNotifier, AsyncValue<TenantSettings?>>((ref) => TenantSettingsNotifier(ref.read(dioProvider)));

class TenantSettingsNotifier extends StateNotifier<AsyncValue<TenantSettings?>> {
  final dynamic _dio;
  TenantSettingsNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch() async {
    try {
      final r = await _dio.get('/tenant-settings/');
      state = AsyncValue.data(TenantSettings.fromJson(r.data));
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> update(Map<String, dynamic> data) async {
    final r = await _dio.put('/tenant-settings/', data: data);
    state = AsyncValue.data(TenantSettings.fromJson(r.data));
  }
}

class TenantSettingsScreen extends ConsumerWidget {
  const TenantSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(tenantSettingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Attendance Settings'), backgroundColor: _surface, foregroundColor: _text, elevation: 0, bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border))),
      body: settingsAsync.when(
        data: (s) {
          if (s == null) return const Center(child: Text('No settings found'));
          return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section('ATTENDANCE YEAR', [
              _row('Start Month', _monthName(s.attendanceYearStartMonth)),
              _row('Start Day', '${s.attendanceYearStartDay}'),
            ]),
            const SizedBox(height: 16),
            _section('PUNCH RULES', [
              _row('Min Punch Difference', '${s.minPunchDifferenceMinutes} minutes'),
              _row('Punch Begin Before', '${s.punchBeginBeforeMinutes} minutes'),
            ]),
            const SizedBox(height: 16),
            _section('SHIFT RULES', [
              _row('Auto Shift if No Schedule', s.autoShiftIfNoSchedule ? 'Yes' : 'No'),
              _row('Fixed Shift Mode', s.fixedShiftMode ? 'Yes' : 'No'),
            ]),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showEditDialog(context, ref, s), icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Settings'), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
          ]));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ApexTypography.sectionHeader), const SizedBox(height: 12), ...children]),
  );

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: ApexTypography.body), Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600))]));

  String _monthName(int m) => ['','January','February','March','April','May','June','July','August','September','October','November','December'][m];

  void _showEditDialog(BuildContext context, WidgetRef ref, TenantSettings s) {
    int startMonth = s.attendanceYearStartMonth;
    int startDay = s.attendanceYearStartDay;
    int minPunch = s.minPunchDifferenceMinutes;
    int punchBegin = s.punchBeginBeforeMinutes;
    bool autoShift = s.autoShiftIfNoSchedule;
    bool fixedShift = s.fixedShiftMode;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Edit Settings'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: startMonth, decoration: const InputDecoration(labelText: 'Attendance Year Start Month', border: OutlineInputBorder()), items: [for (int i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(_monthName(i)))], onChanged: (v) => setS(() => startMonth = v ?? 1)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: 'Start Day', border: OutlineInputBorder()), keyboardType: TextInputType.number, controller: TextEditingController(text: '$startDay'), onChanged: (v) => startDay = int.tryParse(v) ?? 1),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: 'Min Punch Difference (min)', border: OutlineInputBorder()), keyboardType: TextInputType.number, controller: TextEditingController(text: '$minPunch'), onChanged: (v) => minPunch = int.tryParse(v) ?? 1),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: 'Punch Begin Before (min)', border: OutlineInputBorder()), keyboardType: TextInputType.number, controller: TextEditingController(text: '$punchBegin'), onChanged: (v) => punchBegin = int.tryParse(v) ?? 60),
        const SizedBox(height: 12),
        SwitchListTile(title: const Text('Auto Shift if No Schedule'), value: autoShift, onChanged: (v) => setS(() => autoShift = v), activeColor: _primary, contentPadding: EdgeInsets.zero),
        SwitchListTile(title: const Text('Fixed Shift Mode'), value: fixedShift, onChanged: (v) => setS(() => fixedShift = v), activeColor: _primary, contentPadding: EdgeInsets.zero),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await ref.read(tenantSettingsProvider.notifier).update({
            'attendance_year_start_month': startMonth, 'attendance_year_start_day': startDay,
            'min_punch_difference_minutes': minPunch, 'punch_begin_before_minutes': punchBegin,
            'auto_shift_if_no_schedule': autoShift, 'fixed_shift_mode': fixedShift,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Save')),
      ],
    )));
  }
}
