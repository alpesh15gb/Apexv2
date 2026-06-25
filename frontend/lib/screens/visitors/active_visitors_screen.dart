import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/visitor_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class ActiveVisitorsScreen extends ConsumerWidget {
  const ActiveVisitorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeVisitorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Visitors (Inside)'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeVisitorsProvider),
        child: activeAsync.when(
          data: (passes) {
            if (passes.isEmpty) {
              return const EmptyState(
                title: 'No Active Visitors',
                description: 'There are no checked-in visitors in the workspace currently.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: passes.length,
              itemBuilder: (context, idx) {
                final pass = passes[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.badge)),
                    title: Text(pass.visitorName ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Host: ${pass.hostName ?? 'N/A'}\nChecked-in at: ${pass.checkInTime != null ? DateFormat('hh:mm a').format(pass.checkInTime!) : ''}'),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await ref.read(visitorPassesProvider.notifier).checkOut(pass.id);
                        ref.invalidate(activeVisitorsProvider);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                      child: const Text('Check Out', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(count: 3),
          error: (err, stack) => CustomErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(activeVisitorsProvider),
          ),
        ),
      ),
    );
  }
}
