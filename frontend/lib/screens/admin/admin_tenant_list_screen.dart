import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';

const _bg = Color(0xFF0F172A);
const _surface = Color(0xFF1E293B);
const _border = Color(0xFF334155);
const _primary = Color(0xFF3B82F6);
const _success = Color(0xFF22C55E);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);
const _text = Color(0xFFF1F5F9);
const _muted = Color(0xFF94A3B8);

final adminTenantListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/admin/tenants/');
  final data = res.data;
  if (data is Map && data.containsKey('items')) {
    return List<Map<String, dynamic>>.from(data['items']);
  }
  return [];
});

class AdminTenantListScreen extends ConsumerWidget {
  const AdminTenantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(adminTenantListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Tenant Management', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: tenantsAsync.when(
        data: (tenants) {
          if (tenants.isEmpty) {
            return const Center(child: Text('No tenants found', style: TextStyle(color: _muted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenants.length,
            itemBuilder: (context, i) {
              final t = tenants[i];
              final status = t['subscription_status'] ?? 'unknown';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _primary.withOpacity(0.15),
                    child: Text(
                      (t['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(t['name'] ?? '', style: const TextStyle(color: _text, fontWeight: FontWeight.w600)),
                  subtitle: Text('${t['slug']} • ${t['employee_count'] ?? 0} employees • ${t['user_count'] ?? 0} users', style: const TextStyle(color: _muted, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: _muted),
                    ],
                  ),
                  onTap: () => context.go('/admin/tenants/${t['id']}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return _success;
      case 'trial': return _warning;
      case 'suspended': return _danger;
      case 'expired': return _danger;
      default: return _muted;
    }
  }
}
