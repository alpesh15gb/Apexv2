import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../settings/category_screen.dart' show Category, categoryListProvider;

class EmploymentTypesScreen extends ConsumerStatefulWidget {
  const EmploymentTypesScreen({super.key});

  @override
  ConsumerState<EmploymentTypesScreen> createState() => _EmploymentTypesScreenState();
}

class _EmploymentTypesScreenState extends ConsumerState<EmploymentTypesScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(categoryListProvider.notifier).fetch(isRefresh: true);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Employment Type'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Type Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Code *', controller: codeCtrl, required: true),
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
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
              try {
                await ref.read(categoryListProvider.notifier).add({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error),
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

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employment Type'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          ApexButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            type: ApexButtonType.outline,
          ),
          ApexButton(
            label: 'Delete',
            onPressed: () async {
              try {
                await ref.read(categoryListProvider.notifier).delete(category.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: ApexColors.error),
                  );
                }
              }
            },
            type: ApexButtonType.danger,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employment Types',
        description: 'Define employment categories and leave policy configurations.',
        onRefresh: () => ref.read(categoryListProvider.notifier).fetch(isRefresh: true),
        actions: [
          ApexButton(
            label: 'Add Type',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add_circle_outline,
          ),
        ],
        isLoading: catsAsync.isLoading,
        isEmpty: catsAsync.hasValue && catsAsync.value!.isEmpty,
        emptyIcon: Icons.category_outlined,
        emptyTitle: 'No Employment Types',
        emptySubtitle: 'Add standard or customized employment categories.',
        body: catsAsync.when(
          data: (types) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            itemBuilder: (context, i) {
              final t = types[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ApexColors.primary600.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category, color: ApexColors.primary600, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Code: ${t.code}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                              const SizedBox(width: 12),
                              Icon(Icons.policy_outlined, size: 12, color: ApexColors.neutral400),
                              const SizedBox(width: 4),
                              Text('Grace: ${t.graceMinutes}m', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    t.isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (v) {
                        if (v == 'delete') _confirmDelete(t);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Center(
            child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          ),
        ),
      ),
    );
  }
}
