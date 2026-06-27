import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.read(dioProvider));
});

class NotificationsState {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final int unread;
  final int total;

  NotificationsState({this.items = const [], this.loading = false, this.unread = 0, this.total = 0});

  NotificationsState copyWith({List<Map<String, dynamic>>? items, bool? loading, int? unread, int? total}) {
    return NotificationsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      unread: unread ?? this.unread,
      total: total ?? this.total,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final dynamic _dio;
  NotificationsNotifier(this._dio) : super(NotificationsState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true);
    try {
      final res = await _dio.get('/notifications/');
      final data = res.data;
      state = state.copyWith(
        items: List<Map<String, dynamic>>.from(data['items'] ?? []),
        loading: false,
        unread: data['unread'] ?? 0,
        total: data['total'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
      fetch();
    } catch (e) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
      fetch();
    } catch (e) {}
  }
}

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
            if (notifState.unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                child: Text('${notifState.unread}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        actions: [
          if (notifState.unread > 0)
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark All Read'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: notifState.loading && notifState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: _muted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
                      const SizedBox(height: 8),
                      const Text('You\'re all caught up!', style: TextStyle(fontSize: 13, color: _muted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifState.items.length,
                  itemBuilder: (context, i) {
                    final n = notifState.items[i];
                    final isRead = n['is_read'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isRead ? _surface : _primary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isRead ? _border : _primary.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isRead ? _muted.withOpacity(0.1) : _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isRead ? Icons.notifications_none : Icons.notifications_active,
                            size: 20,
                            color: isRead ? _muted : _primary,
                          ),
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                            color: _text,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n['message'] != null)
                              Text(n['message'], style: const TextStyle(fontSize: 12, color: _muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(n['created_at']),
                              style: const TextStyle(fontSize: 11, color: _muted),
                            ),
                          ],
                        ),
                        trailing: !isRead
                            ? IconButton(
                                icon: const Icon(Icons.check, size: 16, color: _primary),
                                onPressed: () => ref.read(notificationsProvider.notifier).markRead(n['id']),
                                tooltip: 'Mark as read',
                              )
                            : null,
                        onTap: !isRead ? () => ref.read(notificationsProvider.notifier).markRead(n['id']) : null,
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return time.toString();
    }
  }
}
