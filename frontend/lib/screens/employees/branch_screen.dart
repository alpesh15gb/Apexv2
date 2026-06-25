import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_provider.dart';
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
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
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
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
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Code: ${b.code} ${b.city != null ? '• ${b.city}' : ''}'),
                  trailing: Icon(
                    Icons.circle,
                    color: b.isActive ? Colors.green : Colors.grey,
                    size: 12,
                  ),
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
        tooltip: 'Add Branch',
        child: const Icon(Icons.add),
      ),
    );
  }
}
