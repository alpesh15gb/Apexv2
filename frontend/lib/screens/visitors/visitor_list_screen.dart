import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class VisitorListScreen extends ConsumerWidget {
  const VisitorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesState = ref.watch(visitorPassesProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Visitors'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add, size: 18), tooltip: 'Register Visitor', onPressed: () => context.push('/visitors/register')),
          IconButton(icon: const Icon(Icons.card_membership, size: 18), tooltip: 'Active Visitors', onPressed: () => context.push('/visitors/active')),
        ],
      ),
      body: passesState.passes.when(
        data: (visitors) {
          if (visitors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_membership, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No Visitors', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text('Register a visitor to get started', style: ApexTypography.bodySmall.copyWith(color: _muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/visitors/register'),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                    child: const Text('Register Visitor'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            itemBuilder: (context, i) {
              final v = visitors[i];
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
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _primary.withOpacity(0.1),
                      child: Text((v.visitorName ?? 'V')[0].toUpperCase(), style: ApexTypography.titleSmall.copyWith(color: _primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.visitorName ?? 'Visitor', style: ApexTypography.titleSmall.copyWith(color: _text)),
                          Text('${v.visitorName ?? 'Visitor'} • ${v.purpose ?? '—'}', style: ApexTypography.captionMedium.copyWith(color: _muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(v.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: _success, fontWeight: FontWeight.w600)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/visitors/register'),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
