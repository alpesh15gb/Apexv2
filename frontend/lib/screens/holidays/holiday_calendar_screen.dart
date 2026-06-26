import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/typography.dart';
import '../../services/essl_service.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final String type;
  final String? description;
  final bool isActive;

  Holiday({required this.id, required this.name, required this.date, required this.type, this.description, required this.isActive});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String? ?? 'company',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
    );
  }
}

class HolidayService {
  final dynamic _dio;
  HolidayService(this._dio);

  Future<List<Holiday>> getHolidays({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _dio.get('/holidays/', queryParameters: params);
    return (response.data as List).map((e) => Holiday.fromJson(e)).toList();
  }

  Future<Holiday> createHoliday(Map<String, dynamic> data) async {
    final response = await _dio.post('/holidays/', data: data);
    return Holiday.fromJson(response.data);
  }

  Future<Holiday> updateHoliday(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/holidays/$id', data: data);
    return Holiday.fromJson(response.data);
  }

  Future<void> deleteHoliday(String id) async {
    await _dio.delete('/holidays/$id');
  }
}

final holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService(ref.read(dioProvider));
});

final holidayListProvider = StateNotifierProvider<HolidayListNotifier, AsyncValue<List<Holiday>>>((ref) {
  return HolidayListNotifier(ref.read(holidayServiceProvider));
});

class HolidayListNotifier extends StateNotifier<AsyncValue<List<Holiday>>> {
  final HolidayService _service;
  int _year = DateTime.now().year;

  HolidayListNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchHolidays();
  }

  int get year => _year;

  Future<void> fetchHolidays({int? year, bool isRefresh = false}) async {
    if (year != null) _year = year;
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final items = await _service.getHolidays(year: _year);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHoliday(Map<String, dynamic> data) async {
    final holiday = await _service.createHoliday(data);
    if (state.value != null) {
      final sorted = [...state.value!, holiday]..sort((a, b) => a.date.compareTo(b.date));
      state = AsyncValue.data(sorted);
    }
  }

  Future<void> updateHoliday(String id, Map<String, dynamic> data) async {
    final updated = await _service.updateHoliday(id, data);
    if (state.value != null) {
      state = AsyncValue.data(state.value!.map((h) => h.id == id ? updated : h).toList()..sort((a, b) => a.date.compareTo(b.date)));
    }
  }

  Future<void> deleteHoliday(String id) async {
    await _service.deleteHoliday(id);
    if (state.value != null) {
      state = AsyncValue.data(state.value!.where((h) => h.id != id).toList());
    }
  }
}

class HolidayCalendarScreen extends ConsumerWidget {
  const HolidayCalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayListProvider);
    final notifier = ref.read(holidayListProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(title: 'Holidays', actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => notifier.fetchHolidays(year: notifier.year - 1, isRefresh: true),
          ),
          Center(child: Text('${notifier.year}', style: ApexTypography.titleMedium.copyWith(color: _text))),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => notifier.fetchHolidays(year: notifier.year + 1, isRefresh: true),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Add Holiday',
            onPressed: () => _showHolidayDialog(context, ref),
          ),
        ]),
      body: holidaysAsync.when(
        data: (holidays) {
          if (holidays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No Holidays for ${notifier.year}', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text('Add holidays to auto-mark attendance', style: ApexTypography.body.copyWith(color: _muted)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showHolidayDialog(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Holiday'),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          final grouped = <String, List<Holiday>>{};
          for (final h in holidays) {
            final month = DateFormat('MMMM yyyy').format(h.date);
            grouped.putIfAbsent(month, () => []).add(h);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final month = grouped.keys.elementAt(i);
              final items = grouped[month]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(month.toUpperCase(), style: ApexTypography.sectionHeader),
                  ),
                  ...items.map((h) => _HolidayCard(
                    holiday: h,
                    onEdit: () => _showHolidayDialog(context, ref, holiday: h),
                    onDelete: () => _confirmDelete(context, ref, h),
                  )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showHolidayDialog(BuildContext context, WidgetRef ref, {Holiday? holiday}) {
    final nameController = TextEditingController(text: holiday?.name ?? '');
    DateTime selectedDate = holiday?.date ?? DateTime.now();
    String selectedType = holiday?.type ?? 'company';
    final descController = TextEditingController(text: holiday?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(holiday != null ? 'Edit Holiday' : 'Add Holiday'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Holiday Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date *', border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'national', child: Text('National')),
                    DropdownMenuItem(value: 'company', child: Text('Company')),
                    DropdownMenuItem(value: 'restricted', child: Text('Restricted')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'company'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final data = {
                  'name': name,
                  'date': selectedDate.toIso8601String().substring(0, 10),
                  'type': selectedType,
                  'description': descController.text.trim(),
                };
                final notifier = ref.read(holidayListProvider.notifier);
                if (holiday != null) {
                  await notifier.updateHoliday(holiday.id, data);
                } else {
                  await notifier.addHoliday(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: Text(holiday != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Holiday holiday) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Delete "${holiday.name}" on ${DateFormat('MMM dd, yyyy').format(holiday.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(holidayListProvider.notifier).deleteHoliday(holiday.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final Holiday holiday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HolidayCard({required this.holiday, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeColor = holiday.type == 'national' ? _primary : holiday.type == 'company' ? _success : _muted;
    final dayName = DateFormat('EEE').format(holiday.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${holiday.date.day}', style: ApexTypography.titleMedium.copyWith(color: typeColor, fontWeight: FontWeight.w700)),
                Text(dayName, style: ApexTypography.captionSmall.copyWith(color: typeColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holiday.name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: _text)),
                if (holiday.description != null && holiday.description!.isNotEmpty)
                  Text(holiday.description!, style: ApexTypography.caption.copyWith(color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(holiday.type.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: typeColor, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger))),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}
