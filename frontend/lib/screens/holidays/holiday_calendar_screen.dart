import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/essl_service.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_date_picker.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

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
    final data = response.data;
    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data.containsKey('items')) {
      items = data['items'];
    } else {
      items = [];
    }
    return items.map((e) => Holiday.fromJson(e)).toList();
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

ApexBadgeType _typeBadge(String type) {
  if (type == 'national') return ApexBadgeType.info;
  if (type == 'company') return ApexBadgeType.success;
  return ApexBadgeType.neutral;
}

Color _typeColor(String type) {
  if (type == 'national') return ApexColors.primary600;
  if (type == 'company') return ApexColors.success;
  return ApexColors.neutral500;
}

class HolidayCalendarScreen extends ConsumerWidget {
  const HolidayCalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayListProvider);
    final notifier = ref.read(holidayListProvider.notifier);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(title: 'Holidays', actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => notifier.fetchHolidays(year: notifier.year - 1, isRefresh: true),
          ),
          Center(child: Text('${notifier.year}', style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900))),
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
                  Icon(Icons.calendar_month_outlined, size: 48, color: ApexColors.neutral400),
                  const SizedBox(height: 16),
                  Text('No Holidays for ${notifier.year}', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(height: 8),
                  Text('Add holidays to auto-mark attendance', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                  const SizedBox(height: 16),
                  ApexButton(
                    label: 'Add Holiday',
                    icon: Icons.add,
                    onPressed: () => _showHolidayDialog(context, ref),
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
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
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
          backgroundColor: Colors.white,
          title: Text(holiday != null ? 'Edit Holiday' : 'Add Holiday', style: ApexTypography.sectionTitle),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(label: 'Holiday Name', controller: nameController, required: true),
                const SizedBox(height: 12),
                ApexDatePicker(
                  label: 'Date',
                  value: selectedDate,
                  required: true,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onChanged: (picked) { if (picked != null) setDialogState(() => selectedDate = picked); },
                ),
                const SizedBox(height: 12),
                ApexDropdown<String>(
                  label: 'Type',
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'national', child: Text('National')),
                    DropdownMenuItem(value: 'company', child: Text('Company')),
                    DropdownMenuItem(value: 'restricted', child: Text('Restricted')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'company'),
                ),
                const SizedBox(height: 12),
                ApexTextField(label: 'Description', controller: descController, maxLines: 2),
              ],
            ),
          ),
          actions: [
            ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
            ApexButton(
              label: holiday != null ? 'Update' : 'Add',
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
                try {
                  if (holiday != null) {
                    await notifier.updateHoliday(holiday.id, data);
                  } else {
                    await notifier.addHoliday(data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error));
                  }
                }
              },
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
          backgroundColor: Colors.white,
          title: Text('Delete Holiday', style: ApexTypography.sectionTitle),
        content: Text('Delete "${holiday.name}" on ${DateFormat('MMM dd, yyyy').format(holiday.date)}?'),
        actions: [
          ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
          ApexButton(
            label: 'Delete',
            type: ApexButtonType.danger,
            onPressed: () async {
              try {
                await ref.read(holidayListProvider.notifier).deleteHoliday(holiday.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: ApexColors.error));
                }
              }
            },
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
    final typeColor = _typeColor(holiday.type);
    final dayName = DateFormat('EEE').format(holiday.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ApexCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Text(holiday.name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  if (holiday.description != null && holiday.description!.isNotEmpty)
                    Text(holiday.description!, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            ApexBadge(label: holiday.type, type: _typeBadge(holiday.type)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16),
              color: Colors.white,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: ApexColors.error))),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
