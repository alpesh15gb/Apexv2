import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/page_wrapper.dart';

class DepartmentScreen extends ConsumerWidget {
  const DepartmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Departments',
        description: 'Manage organizational units and departments.',
        onRefresh: () => ref.refresh(departmentsProvider),
        actions: [
          ApexButton(
            label: 'Add Department',
            onPressed: () => _showAddDialog(context, ref),
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        body: deptsAsync.when(
          data: (depts) {
            if (depts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Departments', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 8),
                    Text('Create departments to organize your workforce', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    const SizedBox(height: 16),
                    ApexButton(
                      label: 'Add Department',
                      onPressed: () => _showAddDialog(context, ref),
                      type: ApexButtonType.primary,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: depts.length,
              itemBuilder: (context, i) {
                final d = depts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ApexColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ApexColors.primary600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: ApexColors.primary600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                            Text('Code: ${d.code}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      d.isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 16),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: ApexColors.error))),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(context, ref, d);
                          if (v == 'delete') _confirmDelete(context, ref, d.id, d.name);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder(), hintText: 'e.g. HR, IT'),
              ),
            ],
          ),
        ),
        actions: [
          ApexButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            type: ApexButtonType.outline,
          ),
          ApexButton(
            label: 'Add',
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              if (name.isEmpty || code.isEmpty) return;
              try {
                await ref.read(departmentsProvider.notifier).addDepartment({'name': name, 'code': code});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: ApexColors.error),
                  );
                }
              }
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic dept) {
    final nameCtrl = TextEditingController(text: dept.name);
    final codeCtrl = TextEditingController(text: dept.code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Department'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          ApexButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            type: ApexButtonType.outline,
          ),
          ApexButton(
            label: 'Update',
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              if (name.isEmpty || code.isEmpty) return;
              try {
                await ref.read(departmentsProvider.notifier).updateDepartment(dept.id, {'name': name, 'code': code});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: ApexColors.error),
                  );
                }
              }
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          ApexButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            type: ApexButtonType.outline,
          ),
          ApexButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(departmentsProvider.notifier).deleteDepartment(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            type: ApexButtonType.danger,
          ),
        ],
      ),
    );
  }
}
