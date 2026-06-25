import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../services/employee_service.dart';

class DepartmentScreen extends ConsumerStatefulWidget {
  const DepartmentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends ConsumerState<DepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _addDepartment() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Department'),
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
                    await service.createDepartment({
                      'name': _nameController.text.trim(),
                      'code': _codeController.text.trim().toUpperCase(),
                      'is_active': true,
                    });
                    ref.invalidate(departmentsProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                      _codeController.clear();
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
    final depsAsync = ref.watch(departmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
      ),
      body: depsAsync.when(
        data: (deps) {
          if (deps.isEmpty) {
            return EmptyState(
              title: 'No Departments',
              description: 'Create departments to categorize your employees.',
              actionLabel: 'Add Department',
              onActionPressed: _addDepartment,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deps.length,
            itemBuilder: (context, idx) {
              final d = deps[idx];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.domain)),
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Code: ${d.code}'),
                  trailing: Icon(
                    Icons.circle,
                    color: d.isActive ? Colors.green : Colors.grey,
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
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDepartment,
        tooltip: 'Add Department',
        child: const Icon(Icons.add),
      ),
    );
  }
}
