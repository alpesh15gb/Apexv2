import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/shift_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class ShiftListScreen extends ConsumerWidget {
  const ShiftListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Shifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_ind_outlined),
            tooltip: 'Assign Shifts',
            onPressed: () => context.push('/shifts/assign'),
          ),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) {
            return EmptyState(
              title: 'No Shifts Configured',
              description: 'Configure daily work timings and late rules.',
              actionLabel: 'Create Shift',
              onActionPressed: () => context.push('/shifts/create'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, idx) {
              final s = shifts[idx];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.schedule)),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Hours: ${s.startTime} - ${s.endTime}\nGrace Period: ${s.gracePeriodMinutes} mins'),
                  isThreeLine: true,
                  trailing: Icon(
                    Icons.circle,
                    color: s.isActive ? Colors.green : Colors.grey,
                    size: 12,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(count: 3),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(shiftListProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/shifts/create'),
        tooltip: 'Create Shift',
        child: const Icon(Icons.add),
      ),
    );
  }
}
