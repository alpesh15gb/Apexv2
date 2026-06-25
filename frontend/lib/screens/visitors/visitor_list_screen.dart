import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/visitor_provider.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class VisitorListScreen extends ConsumerWidget {
  const VisitorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(visitorPassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Active Visitors',
            onPressed: () => context.push('/visitors/active'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: 'Register Visitor',
            onPressed: () => context.push('/visitors/register'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip(ref, 'All', null, listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Scheduled', 'scheduled', listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Checked In', 'checked_in', listState.status),
                const SizedBox(width: 8),
                _buildStatusChip(ref, 'Checked Out', 'checked_out', listState.status),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: listState.passes.when(
              data: (passes) => PaginatedList(
                items: passes,
                hasMore: listState.hasMore,
                isLoading: listState.passes.isLoading,
                onLoadMore: () => ref.read(visitorPassesProvider.notifier).fetchPasses(),
                onRefresh: () => ref.read(visitorPassesProvider.notifier).fetchPasses(isRefresh: true),
                emptyState: const EmptyState(
                  title: 'No Visitors Found',
                  description: 'Register a visitor or clear your search filters.',
                ),
                itemBuilder: (context, pass) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: ListTile(
                      title: Text(pass.visitorName ?? 'Visitor Pass', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host: ${pass.hostName ?? 'N/A'}'),
                          Text('Purpose: ${pass.purpose}'),
                          Text('Expected Date: ${DateFormat('MMM dd, yyyy').format(pass.expectedDate)}'),
                          if (pass.checkInTime != null)
                            Text('In: ${DateFormat('hh:mm a').format(pass.checkInTime!)} ${pass.checkOutTime != null ? '• Out: ${DateFormat('hh:mm a').format(pass.checkOutTime!)}' : ''}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusBadge(status: pass.status),
                        ],
                      ),
                      onTap: () => context.push('/visitors/pass?passId=${pass.id}'),
                    ),
                  );
                },
              ),
              loading: () => const LoadingWidget(count: 4),
              error: (err, stack) => CustomErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.read(visitorPassesProvider.notifier).fetchPasses(isRefresh: true),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/visitors/register'),
        tooltip: 'Register Visitor',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(WidgetRef ref, String label, String? statusVal, String? currentStatus) {
    final isSelected = statusVal == currentStatus;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(visitorPassesProvider.notifier).setFilters(status: statusVal);
      },
    );
  }
}
