import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/secure_storage.dart';
import '../../core/constants.dart';
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

class AdminTenantListScreen extends ConsumerStatefulWidget {
  const AdminTenantListScreen({super.key});

  @override
  ConsumerState<AdminTenantListScreen> createState() => _AdminTenantListScreenState();
}

class _AdminTenantListScreenState extends ConsumerState<AdminTenantListScreen> {
  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(adminTenantListProvider);

    return Scaffold(
      backgroundColor: ApexColors.darkBackground,
      appBar: AppBar(
        backgroundColor: ApexColors.darkSurface,
        foregroundColor: ApexColors.darkOnSurface,
        elevation: 0,
        title: Text('Tenant Management', style: ApexTypography.titleLarge.copyWith(color: ApexColors.darkOnSurface)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddTenantDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Tenant'),
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await secureStorage.delete(StorageKeys.accessToken);
              await secureStorage.delete(StorageKeys.refreshToken);
              await secureStorage.delete('is_admin');
              if (context.mounted) context.go('/admin/login');
            },
            icon: Icon(Icons.logout, size: 18, color: ApexColors.error),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 16),
        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTenantDialog(context),
        backgroundColor: ApexColors.primary600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Tenant', style: ApexTypography.button.copyWith(color: Colors.white)),
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final companyCodeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String tenantType = 'corporate';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ApexColors.darkSurface,
          title: Text('Add New Tenant', style: ApexTypography.titleLarge.copyWith(color: ApexColors.darkOnSurface)),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameCtrl, 'Company Name', Icons.business, required: true),
                    const SizedBox(height: 12),
                    _dialogField(slugCtrl, 'Slug (URL-friendly)', Icons.link, required: true, hint: 'e.g. acme-corp'),
                    const SizedBox(height: 12),
                    _dialogField(emailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _dialogField(mobileCtrl, 'Mobile', Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _dialogField(contactCtrl, 'Contact Person', Icons.person),
                    const SizedBox(height: 12),
                    _dialogField(companyCodeCtrl, 'Company Code', Icons.code),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tenantType,
                      dropdownColor: ApexColors.darkSurface,
                      style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface),
                      decoration: InputDecoration(
                        labelText: 'Tenant Type',
                        labelStyle: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant),
                        prefixIcon: Icon(Icons.category, color: ApexColors.darkOnSurfaceVariant, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.primary500)),
                        filled: true,
                        fillColor: ApexColors.darkBackground,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'corporate', child: Text('Corporate (HRMS)')),
                        DropdownMenuItem(value: 'school', child: Text('School (ERP)')),
                      ],
                      onChanged: (v) => setDialogState(() => tenantType = v ?? 'corporate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final dio = ref.read(dioProvider);
                await dio.post('/admin/tenants/', data: {
                  'name': nameCtrl.text.trim(),
                  'slug': slugCtrl.text.trim().toLowerCase().replaceAll(' ', '-'),
                  if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                  if (mobileCtrl.text.isNotEmpty) 'mobile': mobileCtrl.text.trim(),
                  if (contactCtrl.text.isNotEmpty) 'contact_person': contactCtrl.text.trim(),
                  if (companyCodeCtrl.text.isNotEmpty) 'company_code': companyCodeCtrl.text.trim(),
                  'tenant_type': tenantType,
                });
                Navigator.pop(ctx);
                ref.invalidate(adminTenantListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tenant "${nameCtrl.text}" created successfully'), backgroundColor: ApexColors.success),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
            child: Text('Create Tenant', style: ApexTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {bool required = false, String? hint, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant),
        hintText: hint,
        hintStyle: ApexTypography.captionMedium.copyWith(color: ApexColors.darkOnSurfaceVariant.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: ApexColors.darkOnSurfaceVariant, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.primary500)),
        filled: true,
        fillColor: ApexColors.darkBackground,
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
    );
  }
}

