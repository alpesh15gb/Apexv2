import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../services/access_control_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

final zonesProvider = FutureProvider((ref) async {
  final service = ref.read(accessControlServiceProvider);
  final data = await service.getAccessZones(page: 1, pageSize: 100);
  return data['items'] as List;
});

class ZoneListScreen extends ConsumerStatefulWidget {
  const ZoneListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends ConsumerState<ZoneListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedBranchId;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addZone() {
    showDialog(
      context: context,
      builder: (context) {
        final branchesAsync = ref.watch(branchesProvider);
        return AlertDialog(
          title: Text('Add Access Zone', style: ApexTypography.sectionTitle),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(
                  label: 'Zone Name',
                  controller: _nameController,
                  required: true,
                ),
                const SizedBox(height: 12),
                ApexTextField(
                  label: 'Description',
                  controller: _descController,
                ),
                const SizedBox(height: 12),
                branchesAsync.maybeWhen(
                  data: (list) => ApexDropdown<String>(
                    label: 'Branch',
                    value: _selectedBranchId,
                    required: true,
                    items: list.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
          actions: [
            ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(context)),
            ApexButton(
              label: 'Add',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final service = ref.read(accessControlServiceProvider);
                    await service.createAccessZone({
                      'name': _nameController.text.trim(),
                      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      'branch_id': _selectedBranchId,
                      'is_restricted': false,
                      'access_level_required': 1,
                    });
                    ref.invalidate(zonesProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                      _descController.clear();
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
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Security Access Zones'),
      body: zonesAsync.when(
        data: (zones) {
          if (zones.isEmpty) {
            return EmptyState(
              title: 'No Access Zones',
              description: 'Access zones control which doors users can open.',
              actionLabel: 'Add Zone',
              onActionPressed: _addZone,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            itemBuilder: (context, idx) {
              final z = zones[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ApexColors.primary100,
                        child: Icon(Icons.security, color: ApexColors.primary600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(z['name'], style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                            Text(z['description'] ?? 'No description', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      ApexBadge(label: 'Level ${z['access_level_required'] ?? 1}', type: ApexBadgeType.info),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(count: 3),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(zonesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addZone,
        backgroundColor: ApexColors.primary600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
