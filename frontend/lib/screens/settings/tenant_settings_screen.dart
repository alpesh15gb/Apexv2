import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

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

class _NumberField extends StatefulWidget {
  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _NumberField({required this.label, required this.initialValue, required this.onChanged});
  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.initialValue}');
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ApexTextField(
      label: widget.label,
      controller: _ctrl,
      keyboardType: TextInputType.number,
      onChanged: (v) => widget.onChanged(int.tryParse(v) ?? widget.initialValue),
    );
  }
}

class TenantSettingsScreen extends ConsumerWidget {
  const TenantSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(tenantSettingsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Attendance Settings'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: settingsAsync.when(
        data: (s) {
          if (s == null) return Center(child: Text('No settings found', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
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
            ApexButton(
              label: 'Edit Settings',
              onPressed: () => _showEditDialog(context, ref, s),
              type: ApexButtonType.primary,
              icon: Icons.edit,
              expanded: true,
            ),
          ]));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
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
      title: Text('Edit Settings', style: ApexTypography.cardTitle),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ApexDropdown<int>(
          label: 'Attendance Year Start Month',
          value: startMonth,
          items: [for (int i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(_monthName(i)))],
          onChanged: (v) => setS(() => startMonth = v ?? 1),
        ),
        const SizedBox(height: 12),
        _NumberField(label: 'Start Day', initialValue: startDay, onChanged: (v) => startDay = v),
        const SizedBox(height: 12),
        _NumberField(label: 'Min Punch Difference (min)', initialValue: minPunch, onChanged: (v) => minPunch = v),
        const SizedBox(height: 12),
        _NumberField(label: 'Punch Begin Before (min)', initialValue: punchBegin, onChanged: (v) => punchBegin = v),
        const SizedBox(height: 12),
        SwitchListTile(title: Text('Auto Shift if No Schedule', style: ApexTypography.body), value: autoShift, onChanged: (v) => setS(() => autoShift = v), activeColor: ApexColors.primary, contentPadding: EdgeInsets.zero),
        SwitchListTile(title: Text('Fixed Shift Mode', style: ApexTypography.body), value: fixedShift, onChanged: (v) => setS(() => fixedShift = v), activeColor: ApexColors.primary, contentPadding: EdgeInsets.zero),
      ])),
      actions: [
        ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
        ApexButton(
          label: 'Save',
          onPressed: () async {
            await ref.read(tenantSettingsProvider.notifier).update({
              'attendance_year_start_month': startMonth, 'attendance_year_start_day': startDay,
              'min_punch_difference_minutes': minPunch, 'punch_begin_before_minutes': punchBegin,
              'auto_shift_if_no_schedule': autoShift, 'fixed_shift_mode': fixedShift,
            });
            if (ctx.mounted) Navigator.pop(ctx);
          },
          type: ApexButtonType.primary,
        ),
      ],
    )));
  }
}

