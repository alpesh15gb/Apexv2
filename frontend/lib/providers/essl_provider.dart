import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/essl_server.dart';
import '../services/essl_service.dart';

class EsslServerListNotifier extends StateNotifier<AsyncValue<List<EsslServer>>> {
  final EsslService _service;

  EsslServerListNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchServers();
  }

  Future<void> fetchServers({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final data = await _service.getServers(page: 1, pageSize: 100);
      final items = (data['items'] as List).map((e) => EsslServer.fromJson(e)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addServer(Map<String, dynamic> data) async {
    final server = await _service.createServer(data);
    if (state.value != null) {
      state = AsyncValue.data([server, ...state.value!]);
    }
  }

  Future<void> deleteServer(String id) async {
    await _service.deleteServer(id);
    if (state.value != null) {
      state = AsyncValue.data(state.value!.where((s) => s.id != id).toList());
    }
  }
}

final esslServerListProvider =
    StateNotifierProvider<EsslServerListNotifier, AsyncValue<List<EsslServer>>>((ref) {
  return EsslServerListNotifier(ref.read(esslServiceProvider));
});

final esslDashboardProvider = FutureProvider<List<EsslSyncDashboardStatus>>((ref) async {
  final service = ref.read(esslServiceProvider);
  return await service.getSyncDashboard();
});

class EsslSyncHistoryNotifier extends StateNotifier<AsyncValue<List<EsslSyncHistory>>> {
  final EsslService _service;
  final String serverId;
  int _page = 1;
  bool _hasMore = true;

  EsslSyncHistoryNotifier(this._service, this.serverId) : super(const AsyncValue.loading()) {
    fetchHistory();
  }

  Future<void> fetchHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }
    if (!_hasMore) return;
    try {
      final data = await _service.getSyncHistory(serverId, page: _page, pageSize: 20);
      final items = (data['items'] as List).map((e) => EsslSyncHistory.fromJson(e)).toList();
      final current = state.value ?? [];
      state = AsyncValue.data(isRefresh ? items : [...current, ...items]);
      _hasMore = items.length >= 20;
      _page++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final esslSyncHistoryProvider = StateNotifierProvider.family<
    EsslSyncHistoryNotifier, AsyncValue<List<EsslSyncHistory>>, String>((ref, serverId) {
  return EsslSyncHistoryNotifier(ref.read(esslServiceProvider), serverId);
});

final enterpriseSyncDashboardProvider =
    FutureProvider.family<EnterpriseSyncDashboard, int>((ref, throughputDays) async {
  final service = ref.read(esslServiceProvider);
  return await service.getEnterpriseDashboard(throughputDays: throughputDays);
});
