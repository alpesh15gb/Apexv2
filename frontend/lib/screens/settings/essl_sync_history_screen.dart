import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/essl_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _warning = Color(0xFFF59E0B);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class EsslSyncHistoryScreen extends ConsumerWidget {
  final String serverId;
  const EsslSyncHistoryScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(esslSyncHistoryProvider(serverId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Sync History'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No Sync History', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text('Sync history will appear here after the first sync', style: ApexTypography.body.copyWith(color: _muted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, i) {
              final h = history[i];
              final statusColor = h.status == 'completed' ? _success : h.status == 'failed' ? _danger : _warning;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        h.status == 'completed' ? Icons.check_circle : h.status == 'failed' ? Icons.error : Icons.sync,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${h.syncType.toUpperCase()} Sync', style: ApexTypography.titleSmall.copyWith(color: _text)),
                          Text(
                            '${DateFormat('MMM dd, HH:mm').format(h.startedAt)} • ${h.recordsFetched} records',
                            style: ApexTypography.caption.copyWith(color: _muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(h.status.toUpperCase(), style: ApexTypography.badge.copyWith(color: statusColor)),
                        ),
                        if (h.durationSeconds != null)
                          Text('${h.durationSeconds!.toStringAsFixed(1)}s', style: ApexTypography.caption.copyWith(color: _muted)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
