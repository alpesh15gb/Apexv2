import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class Category {
  final String id, name, code, otFormula, weeklyOff2Week;
  final bool isActive, considerFirstLastPunch, neglectLastInOnMissedOut, considerEarlyComing, considerLateGoing, deductBreakHours, markWoHolidayAbsentIfPrefixAbsent;
  final int minOtMinutes, maxOtMinutes, graceMinutes, halfDayThresholdMinutes, absentThresholdMinutes, lateAbsentMinutes, lateOccurrencesAbsentCount, weeklyOff1;
  final int? weeklyOff2;

  Category({required this.id, required this.name, required this.code, required this.isActive, required this.otFormula, required this.minOtMinutes, required this.maxOtMinutes, required this.graceMinutes, required this.halfDayThresholdMinutes, required this.absentThresholdMinutes, required this.lateAbsentMinutes, required this.lateOccurrencesAbsentCount, required this.weeklyOff1, this.weeklyOff2, required this.weeklyOff2Week, required this.considerFirstLastPunch, required this.neglectLastInOnMissedOut, required this.considerEarlyComing, required this.considerLateGoing, required this.deductBreakHours, required this.markWoHolidayAbsentIfPrefixAbsent});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'], name: json['name'], code: json['code'], isActive: json['is_active'],
    otFormula: json['ot_formula'] ?? 'out_punch', minOtMinutes: json['min_ot_minutes'] ?? 0, maxOtMinutes: json['max_ot_minutes'] ?? 0,
    graceMinutes: json['grace_minutes'] ?? 0, halfDayThresholdMinutes: json['half_day_threshold_minutes'] ?? 240,
    absentThresholdMinutes: json['absent_threshold_minutes'] ?? 0, lateAbsentMinutes: json['late_absent_minutes'] ?? 0,
    lateOccurrencesAbsentCount: json['late_occurrences_absent_count'] ?? 0, weeklyOff1: json['weekly_off_1'] ?? 6,
    weeklyOff2: json['weekly_off_2'], weeklyOff2Week: json['weekly_off_2_week'] ?? 'every',
    considerFirstLastPunch: json['consider_first_last_punch'] ?? true, neglectLastInOnMissedOut: json['neglect_last_in_on_missed_out'] ?? false,
    considerEarlyComing: json['consider_early_coming'] ?? true, considerLateGoing: json['consider_late_going'] ?? true,
    deductBreakHours: json['deduct_break_hours'] ?? true, markWoHolidayAbsentIfPrefixAbsent: json['mark_wo_holiday_absent_if_prefix_absent'] ?? false,
  );
}

final categoryListProvider = StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>((ref) => CategoryListNotifier(ref.read(dioProvider)));

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final dynamic _dio;
  CategoryListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/categories/');
      state = AsyncValue.data((r.data as List).map((e) => Category.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/categories/', data: data);
      if (state.value != null) state = AsyncValue.data([Category.fromJson(r.data), ...state.value!]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put('/categories/$id', data: data);
      if (state.value != null) state = AsyncValue.data(state.value!.map((c) => c.id == id ? Category.fromJson(r.data) : c).toList());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/categories/$id');
      if (state.value != null) state = AsyncValue.data(state.value!.where((c) => c.id != id).toList());
    } catch (e) {
      rethrow;
    }
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

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Employee Categories'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showDialog(context, ref))],
      ),
      body: catsAsync.when(
        data: (cats) {
          if (cats.isEmpty) return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.category_outlined, size: 48, color: ApexColors.neutral500),
              const SizedBox(height: 16),
              Text('No Categories', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
              const SizedBox(height: 8),
              Text('Create categories to define attendance rules', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
              const SizedBox(height: 16),
              ApexButton(
                label: 'Add Category',
                onPressed: () => _showDialog(context, ref),
                type: ApexButtonType.primary,
              ),
            ]),
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final c = cats[i];
              final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: ApexColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.category, color: ApexColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                    Text('Code: ${c.code} | WO: ${days[c.weeklyOff1]}${c.weeklyOff2 != null ? ', ${days[c.weeklyOff2!]} (${c.weeklyOff2Week})' : ''} | Grace: ${c.graceMinutes}m | OT: ${c.otFormula}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                  ])),
                  c.isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  PopupMenuButton<String>(icon: Icon(Icons.more_vert, size: 16), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: ApexColors.error)))], onSelected: (v) { if (v == 'edit') _showDialog(context, ref, category: c); if (v == 'delete') _confirmDelete(context, ref, c.id, c.name); }),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final codeCtrl = TextEditingController(text: category?.code ?? '');
    String otFormula = category?.otFormula ?? 'out_punch';
    int grace = category?.graceMinutes ?? 0;
    int halfDay = category?.halfDayThresholdMinutes ?? 240;
    int wo1 = category?.weeklyOff1 ?? 6;
    int? wo2 = category?.weeklyOff2;
    String wo2Week = category?.weeklyOff2Week ?? 'every';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(category != null ? 'Edit Category' : 'Add Category', style: ApexTypography.cardTitle),
      content: SizedBox(width: 450, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ApexTextField(label: 'Name', controller: nameCtrl, required: true),
        const SizedBox(height: 12),
        ApexTextField(label: 'Code', controller: codeCtrl, required: true, hint: 'e.g. STAFF, WORKER'),
        const SizedBox(height: 12),
        ApexDropdown<String>(label: 'OT Formula', value: otFormula, items: const [DropdownMenuItem(value: 'out_punch', child: Text('Out Punch - Shift End')), DropdownMenuItem(value: 'total_duration', child: Text('Total Duration - Shift Duration')), DropdownMenuItem(value: 'early_late_sum', child: Text('Early Coming + Late Going'))], onChanged: (v) => setS(() => otFormula = v ?? 'out_punch')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ApexDropdown<int>(label: 'Weekly Off 1', value: wo1, items: [for (int i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]))], onChanged: (v) => setS(() => wo1 = v ?? 6))),
          const SizedBox(width: 12),
          Expanded(child: ApexDropdown<int>(label: 'Weekly Off 2', value: wo2, items: [const DropdownMenuItem(value: null, child: Text('None')), for (int i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]))], onChanged: (v) => setS(() => wo2 = v))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _NumberField(label: 'Grace (min)', initialValue: grace, onChanged: (v) => grace = v)),
          const SizedBox(width: 12),
          Expanded(child: _NumberField(label: 'Half Day (min)', initialValue: halfDay, onChanged: (v) => halfDay = v)),
        ]),
      ]))),
      actions: [
        ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
        ApexButton(
          label: category != null ? 'Update' : 'Add',
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
            final data = {'name': nameCtrl.text.trim(), 'code': codeCtrl.text.trim().toUpperCase(), 'ot_formula': otFormula, 'grace_minutes': grace, 'half_day_threshold_minutes': halfDay, 'weekly_off_1': wo1, 'weekly_off_2': wo2, 'weekly_off_2_week': wo2Week};
            final notifier = ref.read(categoryListProvider.notifier);
            try {
              if (category != null) { await notifier.update(category.id, data); } else { await notifier.add(data); }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error));
              }
            }
          },
          type: ApexButtonType.primary,
        ),
      ],
    )));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Delete Category', style: ApexTypography.cardTitle),
      content: Text('Delete "$name"?', style: ApexTypography.body),
      actions: [
        ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
        ApexButton(
          label: 'Delete',
          onPressed: () async {
            try {
              await ref.read(categoryListProvider.notifier).delete(id);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: ApexColors.error));
              }
            }
          },
          type: ApexButtonType.danger,
        ),
      ],
    ));
  }
}

