import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_provider.dart';
import '../../services/access_control_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

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
          title: const Text('Add Access Zone'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Zone Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                branchesAsync.maybeWhen(
                  data: (list) => DropdownButtonFormField<String>(
                    value: _selectedBranchId,
                    decoration: const InputDecoration(labelText: 'Branch *'),
                    items: list.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
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
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
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
      appBar: AppBar(title: const Text('Security Access Zones')),
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
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.security)),
                  title: Text(z['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(z['description'] ?? 'No description'),
                  trailing: Chip(
                    label: Text('Level ${z['access_level_required'] ?? 1}'),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
