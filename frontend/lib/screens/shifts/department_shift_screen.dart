import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/typography.dart';
import '../../core/dio_client.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class DeptShiftItem {
  final String id, departmentId, shiftId;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  DeptShiftItem({required this.id, required this.departmentId, required this.shiftId, required this.effectiveFrom, this.effectiveTo});
  factory DeptShiftItem.fromJson(Map<String, dynamic> json) => DeptShiftItem(id: json['id'], departmentId: json['department_id'], shiftId: json['shift_id'], effectiveFrom: DateTime.parse(json['effective_from']), effectiveTo: json['effective_to'] != null ? DateTime.parse(json['effective_to']) : null);
}

class DeptOption { final String id, name; DeptOption({required this.id, required this.name}); factory DeptOption.fromJson(Map<String, dynamic> json) => DeptOption(id: json['id'], name: json['name']); }
class ShiftOption { final String id, name; ShiftOption({required this.id, required this.name}); factory ShiftOption.fromJson(Map<String, dynamic> json) => ShiftOption(id: json['id'], name: json['name']); }

final deptShiftListProvider = StateNotifierProvider<DeptShiftListNotifier, AsyncValue<List<DeptShiftItem>>>((ref) => DeptShiftListNotifier(ref.read(dioProvider)));

class DeptShiftListNotifier extends StateNotifier<AsyncValue<List<DeptShiftItem>>> {
  final dynamic _dio;
  DeptShiftListNotifier(this._dio) : super(const AsyncValue.loading()) { fetch(); }

  Future<void> fetch({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final r = await _dio.get('/department-shifts/');
      state = AsyncValue.data((r.data as List).map((e) => DeptShiftItem.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(Map<String, dynamic> data) async {
    final r = await _dio.post('/department-shifts/', data: data);
    if (state.value != null) state = AsyncValue.data([DeptShiftItem.fromJson(r.data), ...state.value!]);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/department-shifts/$id');
    if (state.value != null) state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
  }
}

class DepartmentShiftScreen extends ConsumerStatefulWidget {
  const DepartmentShiftScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<DepartmentShiftScreen> createState() => _DepartmentShiftScreenState();
}

class _DepartmentShiftScreenState extends ConsumerState<DepartmentShiftScreen> {
  List<DeptOption> _depts = [];
  List<ShiftOption> _shifts = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final dio = ref.read(dioProvider);
    final deptsR = await dio.get('/employees/departments', queryParameters: {'page': 1, 'page_size': 100});
    final shiftsR = await dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100});
    setState(() {
      _depts = (deptsR.data['items'] as List).map((e) => DeptOption.fromJson(e)).toList();
      _shifts = (shiftsR.data['items'] as List).map((e) => ShiftOption.fromJson(e)).toList();
    });
  }

  String _deptName(String id) => _depts.firstWhere((d) => d.id == id, orElse: () => DeptOption(id: id, name: 'Unknown')).name;
  String _shiftName(String id) => _shifts.firstWhere((s) => s.id == id, orElse: () => ShiftOption(id: id, name: 'Unknown')).name;

  @override
  Widget build(BuildContext context) {
    final dsAsync = ref.watch(deptShiftListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Department Shifts'),
        backgroundColor: _surface, foregroundColor: _text, elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showAddDialog())],
      ),
      body: dsAsync.when(
        data: (items) {
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.swap_horiz, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text('No Department Shifts', style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text('Assign default shifts to departments', style: ApexTypography.body.copyWith(color: _muted)),
          ]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
            final d = items[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.swap_horiz, color: _primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_deptName(d.departmentId), style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('${_shiftName(d.shiftId)} | From ${DateFormat('MMM dd, yyyy').format(d.effectiveFrom)}${d.effectiveTo != null ? ' to ${DateFormat('MMM dd, yyyy').format(d.effectiveTo!)}' : ' (ongoing)'}', style: ApexTypography.caption.copyWith(color: _muted)),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: _danger), onPressed: () => ref.read(deptShiftListProvider.notifier).delete(d.id)),
            ]));
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddDialog() {
    String? deptId, shiftId;
    DateTime fromDate = DateTime.now();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Assign Department Shift'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: deptId, decoration: const InputDecoration(labelText: 'Department *', border: OutlineInputBorder()), items: _depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(), onChanged: (v) => setS(() => deptId = v)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: shiftId, decoration: const InputDecoration(labelText: 'Shift *', border: OutlineInputBorder()), items: _shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(), onChanged: (v) => setS(() => shiftId = v)),
        const SizedBox(height: 12),
        InkWell(onTap: () async { final p = await showDatePicker(context: ctx, initialDate: fromDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setS(() => fromDate = p); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Effective From', border: OutlineInputBorder()), child: Text(DateFormat('MMM dd, yyyy').format(fromDate)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (deptId == null || shiftId == null) return;
          await ref.read(deptShiftListProvider.notifier).add({'department_id': deptId, 'shift_id': shiftId, 'effective_from': fromDate.toIso8601String().substring(0, 10)});
          if (ctx.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), child: const Text('Assign')),
      ],
    )));
  }
}
