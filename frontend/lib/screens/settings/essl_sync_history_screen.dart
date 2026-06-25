import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/essl_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class EsslSyncHistoryScreen extends ConsumerWidget {
  final String serverId;

  const EsslSyncHistoryScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(esslSyncHistoryProvider(serverId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sync History')),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const EmptyState(
              title: 'No Sync History',
              description: 'Sync history will appear here after your first sync.',
              icon: Icons.history,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final h = history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(h.status).withOpacity(0.1),
                    child: Icon(_statusIcon(h.status), color: _statusColor(h.status), size: 20),
                  ),
                  title: Text('${h.syncType.toUpperCase()} Sync'),
                  subtitle: Text(
                    '${DateFormat('MMM dd, HH:mm').format(h.startedAt)} • ${h.triggeredBy}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(h.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      h.status.toUpperCase(),
                      style: TextStyle(color: _statusColor(h.status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow('Fetched', '${h.recordsFetched}'),
                          _buildStatRow('Created', '${h.recordsCreated}'),
                          _buildStatRow('Updated', '${h.recordsUpdated}'),
                          _buildStatRow('Skipped', '${h.recordsSkipped}'),
                          _buildStatRow('Failed', '${h.recordsFailed}'),
                          if (h.durationSeconds != null)
                            _buildStatRow('Duration', '${h.durationSeconds!.toStringAsFixed(1)}s'),
                          if (h.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text('Error:', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            Text(h.errorMessage!, style: TextStyle(color: Colors.red.shade600)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(count: 5),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.read(esslSyncHistoryProvider(serverId).notifier).fetchHistory(isRefresh: true),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'running':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check;
      case 'partial':
        return Icons.warning;
      case 'failed':
        return Icons.close;
      case 'running':
        return Icons.sync;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
