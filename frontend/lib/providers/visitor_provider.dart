import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor.dart';
import '../services/visitor_service.dart';

class VisitorPassesState {
  final AsyncValue<List<VisitorPass>> passes;
  final int page;
  final bool hasMore;
  final String? status;
  final String? hostEmployeeId;
  final String? search;

  VisitorPassesState({
    required this.passes,
    this.page = 1,
    this.hasMore = true,
    this.status,
    this.hostEmployeeId,
    this.search,
  });

  VisitorPassesState copyWith({
    AsyncValue<List<VisitorPass>>? passes,
    int? page,
    bool? hasMore,
    String? status,
    String? hostEmployeeId,
    String? search,
  }) {
    return VisitorPassesState(
      passes: passes ?? this.passes,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
      hostEmployeeId: hostEmployeeId ?? this.hostEmployeeId,
      search: search ?? this.search,
    );
  }
}

class VisitorPassesNotifier extends StateNotifier<VisitorPassesState> {
  final VisitorService _service;
  static const int _pageSize = 20;

  VisitorPassesNotifier(this._service)
      : super(VisitorPassesState(passes: const AsyncValue.loading())) {
    fetchPasses();
  }

  Future<void> fetchPasses({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        passes: const AsyncValue.loading(),
        page: 1,
        hasMore: true,
      );
    }

    if (!state.hasMore && !isRefresh) return;

    try {
      final data = await _service.getVisitorPasses(
        page: state.page,
        pageSize: _pageSize,
        status: state.status,
        hostEmployeeId: state.hostEmployeeId,
        search: state.search,
      );

      final items = (data['items'] as List)
          .map((e) => VisitorPass.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.passes.value ?? [];
      state = state.copyWith(
        passes: AsyncValue.data(isRefresh ? items : [...current, ...items]),
        page: state.page + 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e, stack) {
      state = state.copyWith(passes: AsyncValue.error(e, stack));
    }
  }

  void setFilters({String? status, String? hostEmployeeId, String? search}) {
    state = state.copyWith(
      status: status,
      hostEmployeeId: hostEmployeeId,
      search: search,
    );
    fetchPasses(isRefresh: true);
  }

  void clearFilters() {
    state = VisitorPassesState(passes: const AsyncValue.loading());
    fetchPasses(isRefresh: true);
  }

  Future<void> createPass(Map<String, dynamic> data) async {
    final pass = await _service.createVisitorPass(data);
    if (state.passes.value != null) {
      state = state.copyWith(
        passes: AsyncValue.data([pass, ...state.passes.value!]),
      );
    }
  }

  Future<void> checkIn(String passId) async {
    final updated = await _service.checkIn(passId);
    if (state.passes.value != null) {
      final list = state.passes.value!.map((e) => e.id == passId ? updated : e).toList();
      state = state.copyWith(passes: AsyncValue.data(list));
    }
  }

  Future<void> checkOut(String passId) async {
    final updated = await _service.checkOut(passId);
    if (state.passes.value != null) {
      final list = state.passes.value!.map((e) => e.id == passId ? updated : e).toList();
      state = state.copyWith(passes: AsyncValue.data(list));
    }
  }
}

final visitorPassesProvider =
    StateNotifierProvider<VisitorPassesNotifier, VisitorPassesState>((ref) {
  final service = ref.read(visitorServiceProvider);
  return VisitorPassesNotifier(service);
});

// Active Visitors
final activeVisitorsProvider = FutureProvider<List<VisitorPass>>((ref) async {
  final service = ref.read(visitorServiceProvider);
  return await service.getActiveVisitors();
});
