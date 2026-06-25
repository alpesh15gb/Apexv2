import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationListState {
  final AsyncValue<List<NotificationModel>> notifications;
  final int page;
  final bool hasMore;
  final String? status;

  NotificationListState({
    required this.notifications,
    this.page = 1,
    this.hasMore = true,
    this.status,
  });

  NotificationListState copyWith({
    AsyncValue<List<NotificationModel>>? notifications,
    int? page,
    bool? hasMore,
    String? status,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationService _service;
  final Ref _ref;
  static const int _pageSize = 20;

  NotificationListNotifier(this._service, this._ref)
      : super(NotificationListState(notifications: const AsyncValue.loading())) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        notifications: const AsyncValue.loading(),
        page: 1,
        hasMore: true,
      );
    }

    if (!state.hasMore && !isRefresh) return;

    try {
      final data = await _service.getNotifications(
        status: state.status,
        page: state.page,
        pageSize: _pageSize,
      );

      final items = (data['items'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.notifications.value ?? [];
      state = state.copyWith(
        notifications: AsyncValue.data(isRefresh ? items : [...current, ...items]),
        page: state.page + 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e, stack) {
      state = state.copyWith(notifications: AsyncValue.error(e, stack));
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(status: status);
    fetchNotifications(isRefresh: true);
  }

  Future<void> markAsRead(String id) async {
    try {
      final updated = await _service.markAsRead(id);
      if (state.notifications.value != null) {
        final list = state.notifications.value!.map((e) => e.id == id ? updated : e).toList();
        state = state.copyWith(notifications: AsyncValue.data(list));
      }
      // Refresh the unread count provider
      _ref.read(unreadCountProvider.notifier).decrement();
    } catch (e) {
      // ignore
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>((ref) {
  final service = ref.read(notificationServiceProvider);
  return NotificationListNotifier(service, ref);
});

// Unread Count Notifier
class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationService _service;

  UnreadCountNotifier(this._service) : super(0) {
    fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      state = count;
    } catch (e) {
      // ignore
    }
  }

  void decrement() {
    if (state > 0) state--;
  }

  void set(int value) {
    state = value;
  }
}

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final service = ref.read(notificationServiceProvider);
  return UnreadCountNotifier(service);
});
