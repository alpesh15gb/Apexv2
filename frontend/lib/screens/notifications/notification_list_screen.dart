import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/notification_provider.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          // Unread Count banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unread Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${ref.watch(unreadCountProvider)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: listState.notifications.when(
              data: (items) => PaginatedList(
                items: items,
                hasMore: listState.hasMore,
                isLoading: listState.notifications.isLoading,
                onLoadMore: () => ref.read(notificationListProvider.notifier).fetchNotifications(),
                onRefresh: () => ref.read(notificationListProvider.notifier).fetchNotifications(isRefresh: true),
                emptyState: const EmptyState(
                  title: 'All Caught Up!',
                  description: 'You have no notifications.',
                ),
                itemBuilder: (context, item) {
                  return Card(
                    color: item.isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.04),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: ListTile(
                      leading: Icon(
                        item.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: item.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.message),
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(item.createdAt),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: !item.isRead
                          ? TextButton(
                              onPressed: () => ref.read(notificationListProvider.notifier).markAsRead(item.id),
                              child: const Text('Mark Read', style: TextStyle(fontSize: 11)),
                            )
                          : null,
                    ),
                  );
                },
              ),
              loading: () => const LoadingWidget(count: 5),
              error: (err, stack) => CustomErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.read(notificationListProvider.notifier).fetchNotifications(isRefresh: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
