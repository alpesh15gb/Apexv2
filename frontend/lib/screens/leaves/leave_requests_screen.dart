import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/leave_provider.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class LeaveRequestsScreen extends ConsumerWidget {
  const LeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(leaveRequestsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Leave Balances',
            onPressed: () => context.push('/leaves/balance'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Apply Leave',
            onPressed: () => context.push('/leaves/apply'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter status bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip(ref, 'All', null, listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Pending', 'pending', listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Approved', 'approved', listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Rejected', 'rejected', listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Cancelled', 'cancelled', listState.status),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: listState.requests.when(
              data: (requests) => PaginatedList(
                items: requests,
                hasMore: listState.hasMore,
                isLoading: listState.requests.isLoading,
                onLoadMore: () => ref.read(leaveRequestsProvider.notifier).fetchRequests(),
                onRefresh: () => ref.read(leaveRequestsProvider.notifier).fetchRequests(isRefresh: true),
                emptyState: const EmptyState(
                  title: 'No Leave Requests',
                  description: 'No requests matched the status filter.',
                ),
                itemBuilder: (context, req) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(req.employeeName ?? 'Employee Request', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${req.leaveTypeName ?? 'N/A'}'),
                            Text('Duration: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)} (${req.totalDays} Days)'),
                            if (req.reason != null) Text('Reason: ${req.reason}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(status: req.status),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: req.status == 'pending'
                            ? () => _showApprovalDialog(context, ref, req.id)
                            : null,
                      ),
                    ),
                  );
                },
              ),
              loading: () => const LoadingWidget(count: 4),
              error: (err, stack) => CustomErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.read(leaveRequestsProvider.notifier).fetchRequests(isRefresh: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(WidgetRef ref, String label, String? statusVal, String? currentStatus) {
    final isSelected = statusVal == currentStatus;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(leaveRequestsProvider.notifier).setFilters(status: statusVal);
      },
    );
  }

  void _showApprovalDialog(BuildContext context, WidgetRef ref, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Leave Request'),
        content: const Text('Would you like to approve or reject this leave application?'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(leaveRequestsProvider.notifier).reject(requestId, 'Rejected by Administrator');
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(leaveRequestsProvider.notifier).approve(requestId);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
