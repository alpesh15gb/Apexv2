import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';

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
      backgroundColor: ApexColors.darkBackground,
      appBar: AppBar(
        backgroundColor: ApexColors.darkSurface,
        foregroundColor: ApexColors.darkOnSurface,
        elevation: 0,
        title: Text('Tenant Management', style: ApexTypography.titleLarge.copyWith(color: ApexColors.darkOnSurface)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: tenantsAsync.when(
        data: (tenants) {
          if (tenants.isEmpty) {
            return Center(child: Text('No tenants found', style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant)));
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
                  color: ApexColors.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.darkSurfaceVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: ApexColors.primary500.withOpacity(0.15),
                    child: Text(
                      (t['name'] ?? '?')[0].toUpperCase(),
                      style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary500),
                    ),
                  ),
                  title: Text(t['name'] ?? '', style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface, fontWeight: FontWeight.w600)),
                  subtitle: Text('${t['slug']} • ${t['employee_count'] ?? 0} employees • ${t['user_count'] ?? 0} users', style: ApexTypography.captionMedium.copyWith(color: ApexColors.darkOnSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ApexBadge(
                        label: status,
                        type: status == 'active' ? ApexBadgeType.success : status == 'trial' ? ApexBadgeType.warning : (status == 'suspended' || status == 'expired') ? ApexBadgeType.danger : ApexBadgeType.neutral,
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: ApexColors.darkOnSurfaceVariant),
                    ],
                  ),
                  onTap: () => context.go('/admin/tenants/${t['id']}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: ApexColors.primary500)),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return ApexColors.success;
      case 'trial': return ApexColors.warning;
      case 'suspended': return ApexColors.error;
      case 'expired': return ApexColors.error;
      default: return ApexColors.darkOnSurfaceVariant;
    }
  }
}

