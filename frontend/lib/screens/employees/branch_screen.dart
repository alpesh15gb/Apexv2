import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
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
      appBar: AppBar(
        title: const Text('Branches'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return EmptyState(
              title: 'No Branches',
              description: 'Create branch locations for your offices.',
              actionLabel: 'Add Branch',
              onActionPressed: _addBranch,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (context, idx) {
              final b = branches[idx];
              return ApexCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ApexColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.store, color: ApexColors.primary),
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
        loading: () => const LoadingWidget(count: 4),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(branchesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBranch,
        backgroundColor: ApexColors.primary,
        tooltip: 'Add Branch',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
