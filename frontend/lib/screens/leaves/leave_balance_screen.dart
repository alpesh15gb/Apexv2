import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/leave_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(currentEmployeeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave Balance'),
      ),
      body: employeeAsync.when(
        data: (employee) {
          if (employee == null) {
            return const Center(child: Text('No employee record found for your account.'));
          }
          final balanceAsync = ref.watch(leaveBalanceProvider(employee.id));
          return balanceAsync.when(
            data: (balances) {
              if (balances.isEmpty) {
                return const EmptyState(
                  title: 'No Leave Balances',
                  description: 'Your leave allocation balances will appear here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: balances.length,
                itemBuilder: (context, idx) {
                  final b = balances[idx];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.leaveTypeName ?? 'Leave Category',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBalanceStat('Allowed', '${b.totalDays}', Colors.grey),
                              _buildBalanceStat('Used', '${b.usedDays}', Colors.red),
                              _buildBalanceStat('Pending', '${b.pendingDays}', Colors.amber),
                              _buildBalanceStat('Available', '${b.availableDays}', Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingWidget(count: 3),
            error: (err, stack) => CustomErrorWidget(
              errorMessage: err.toString(),
              onRetry: () => ref.invalidate(leaveBalanceProvider(employee.id)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(currentEmployeeProvider),
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
