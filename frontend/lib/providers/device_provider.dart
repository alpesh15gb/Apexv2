import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../services/device_service.dart';

class DeviceListNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  final DeviceService _service;
  int _page = 1;
  bool _hasMore = true;

  DeviceListNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchDevices();
  }

  Future<void> fetchDevices({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final data = await _service.getDevices(page: _page, pageSize: 20);
      final items = (data['items'] as List)
          .map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.value ?? [];
      state = AsyncValue.data(isRefresh ? items : [...current, ...items]);
      _hasMore = items.length >= 20;
      _page++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDevice(Map<String, dynamic> data) async {
    try {
      final newDevice = await _service.createDevice(data);
      if (state.value != null) {
        state = AsyncValue.data([newDevice, ...state.value!]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateDevice(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateDevice(id, data);
      if (state.value != null) {
        final list = state.value!.map((e) => e.id == id ? updated : e).toList();
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDevice(String id) async {
    try {
      await _service.deleteDevice(id);
      if (state.value != null) {
        final list = state.value!.where((e) => e.id != id).toList();
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> syncDevice(String id) async {
    await _service.syncDevice(id);
    // Refresh to get updated lastSync timestamp
    await fetchDevices(isRefresh: true);
  }
}

final deviceListProvider = StateNotifierProvider<DeviceListNotifier, AsyncValue<List<Device>>>((ref) {
  final service = ref.read(deviceServiceProvider);
  return DeviceListNotifier(service);
});

final deviceHealthProvider = FutureProvider<DeviceHealth>((ref) async {
  final service = ref.read(deviceServiceProvider);
  return await service.getDeviceHealth();
});
