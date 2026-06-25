import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shift.dart';
import '../services/shift_service.dart';

class ShiftListNotifier extends StateNotifier<AsyncValue<List<Shift>>> {
  final ShiftService _service;
  int _page = 1;
  bool _hasMore = true;

  ShiftListNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchShifts();
  }

  Future<void> fetchShifts({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final data = await _service.getShifts(page: _page, pageSize: 20);
      final items = (data['items'] as List)
          .map((e) => Shift.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.value ?? [];
      state = AsyncValue.data(isRefresh ? items : [...current, ...items]);
      _hasMore = items.length >= 20;
      _page++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addShift(Map<String, dynamic> data) async {
    try {
      final newShift = await _service.createShift(data);
      if (state.value != null) {
        state = AsyncValue.data([newShift, ...state.value!]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateShift(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateShift(id, data);
      if (state.value != null) {
        final list = state.value!.map((e) => e.id == id ? updated : e).toList();
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteShift(String id) async {
    try {
      await _service.deleteShift(id);
      if (state.value != null) {
        final list = state.value!.where((e) => e.id != id).toList();
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final shiftListProvider = StateNotifierProvider<ShiftListNotifier, AsyncValue<List<Shift>>>((ref) {
  final service = ref.read(shiftServiceProvider);
  return ShiftListNotifier(service);
});

// Shift Schedules Provider
final shiftSchedulesProvider =
    FutureProvider.family<List<ShiftSchedule>, String?>((ref, employeeId) async {
  final service = ref.read(shiftServiceProvider);
  final data = await service.getSchedules(
    employeeId: employeeId,
    page: 1,
    pageSize: 100,
  );
  final items = data['items'] as List;
  return items.map((e) => ShiftSchedule.fromJson(e as Map<String, dynamic>)).toList();
});
