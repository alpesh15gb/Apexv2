import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/page_wrapper.dart';
import '../../services/employee_service.dart';

class BranchScreen extends ConsumerStatefulWidget {
  const BranchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends ConsumerState<BranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _addBranch() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Branch'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(
                  label: 'Name',
                  controller: _nameController,
                  required: true,
                ),
                const SizedBox(height: 12),
                ApexTextField(
                  label: 'Code',
                  controller: _codeController,
                  required: true,
                ),
                const SizedBox(height: 12),
                ApexTextField(
                  label: 'City',
                  controller: _cityController,
                ),
              ],
            ),
          ),
          actions: [
            ApexButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
              type: ApexButtonType.outline,
            ),
            ApexButton(
              label: 'Add',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final service = ref.read(employeeServiceProvider);
                    await service.createBranch({
                      'name': _nameController.text.trim(),
                      'code': _codeController.text.trim().toUpperCase(),
                      'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
                      'is_active': true,
                    });
                    ref.invalidate(branchesProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                      _codeController.clear();
                      _cityController.clear();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: ApexColors.error),
                      );
                    }
                  }
                }
              },
              type: ApexButtonType.primary,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Branches',
        description: 'Manage corporate office branches and locations.',
        onRefresh: () => ref.refresh(branchesProvider),
        actions: [
          ApexButton(
            label: 'Add Branch',
            onPressed: _addBranch,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        body: branchesAsync.when(
          data: (branches) {
            if (branches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Branches', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 8),
                    Text('Create branch locations for your offices.', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                    const SizedBox(height: 16),
                    ApexButton(
                      label: 'Add Branch',
                      onPressed: _addBranch,
                      type: ApexButtonType.primary,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              itemBuilder: (context, idx) {
                final b = branches[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ApexColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ApexColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.store, color: ApexColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                            Text('Code: ${b.code} ${b.city != null ? '• ${b.city}' : ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      b.isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $err', style: ApexTypography.body.copyWith(color: ApexColors.error)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(branchesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
