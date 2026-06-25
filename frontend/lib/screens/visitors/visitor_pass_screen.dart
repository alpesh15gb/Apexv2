import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/visitor.dart';
import '../../providers/visitor_provider.dart';
import '../../services/visitor_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/status_badge.dart';

final visitorPassDetailProvider = FutureProvider.family<VisitorPass, String>((ref, id) async {
  final service = ref.read(visitorServiceProvider);
  // Find pass in lists or retrieve
  final data = await service.getVisitorPasses(page: 1, pageSize: 100);
  final items = (data['items'] as List).map((e) => VisitorPass.fromJson(e)).toList();
  return items.firstWhere((e) => e.id == id);
});

class VisitorPassScreen extends ConsumerWidget {
  final String passId;

  const VisitorPassScreen({Key? key, required this.passId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(visitorPassDetailProvider(passId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Access Pass'),
      ),
      body: detailAsync.when(
        data: (pass) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'VISITOR PASS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pass.passNumber,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatusBadge(status: pass.status),
                    const Divider(height: 32),
                    _buildRow('Visitor Name', pass.visitorName ?? 'N/A'),
                    _buildRow('Host Employee', pass.hostName ?? 'N/A'),
                    _buildRow('Purpose', pass.purpose),
                    _buildRow('Expected Date', DateFormat('MMM dd, yyyy').format(pass.expectedDate)),
                    _buildRow('Check-in', pass.checkInTime != null ? DateFormat('hh:mm a').format(pass.checkInTime!) : '--:--'),
                    _buildRow('Check-out', pass.checkOutTime != null ? DateFormat('hh:mm a').format(pass.checkOutTime!) : '--:--'),
                    const SizedBox(height: 32),
                    if (pass.status == 'scheduled')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(visitorPassesProvider.notifier).checkIn(pass.id);
                          ref.invalidate(visitorPassDetailProvider(passId));
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      )
                    else if (pass.status == 'checked_in')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(visitorPassesProvider.notifier).checkOut(pass.id);
                          ref.invalidate(visitorPassDetailProvider(passId));
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        loading: () => const LoadingWidget(count: 1),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(visitorPassDetailProvider(passId)),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
