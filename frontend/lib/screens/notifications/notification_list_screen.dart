import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_button.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Notifications'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ApexColors.primary50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Unread Alerts', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: ApexColors.primary600,
                  child: Text(
                    '${ref.watch(unreadCountProvider)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: ApexColors.neutral200),

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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: ApexCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.isRead ? Icons.notifications_none : Icons.notifications_active,
                            color: item.isRead ? ApexColors.neutral400 : ApexColors.primary600,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: ApexTypography.body.copyWith(fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(item.message, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral600)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, hh:mm a').format(item.createdAt),
                                  style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isRead)
                            ApexButton(
                              label: 'Mark Read',
                              type: ApexButtonType.ghost,
                              onPressed: () => ref.read(notificationListProvider.notifier).markAsRead(item.id),
                            ),
                        ],
                      ),
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
