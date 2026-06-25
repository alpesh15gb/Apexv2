import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/access_control_service.dart';
import './zone_list_screen.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../core/dio_client.dart';

final doorsProvider = FutureProvider((ref) async {
  final service = ref.read(accessControlServiceProvider);
  final data = await service.getDoors(page: 1, pageSize: 100);
  return data['items'] as List;
});

class DoorListScreen extends ConsumerStatefulWidget {
  const DoorListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoorListScreen> createState() => _DoorListScreenState();
}

class _DoorListScreenState extends ConsumerState<DoorListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedZoneId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addDoor() {
    showDialog(
      context: context,
      builder: (context) {
        final zonesAsync = ref.watch(zonesProvider);
        return AlertDialog(
          title: const Text('Add Access Door'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Door Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                zonesAsync.maybeWhen(
                  data: (list) => DropdownButtonFormField<String>(
                    value: _selectedZoneId,
                    decoration: const InputDecoration(labelText: 'Access Zone *'),
                    items: list.map((z) => DropdownMenuItem<String>(value: z['id'], child: Text(z['name']))).toList(),
                    onChanged: (v) => setState(() => _selectedZoneId = v),
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
                    await service.createDoor({
                      'name': _nameController.text.trim(),
                      'zone_id': _selectedZoneId,
                      'is_active': true,
                    });
                    ref.invalidate(doorsProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
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
    final doorsAsync = ref.watch(doorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Access Doors')),
      body: doorsAsync.when(
        data: (doors) {
          if (doors.isEmpty) {
            return EmptyState(
              title: 'No Access Doors',
              description: 'Configure doors linked to biometric access control devices.',
              actionLabel: 'Add Door',
              onActionPressed: _addDoor,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doors.length,
            itemBuilder: (context, idx) {
              final d = doors[idx];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.sensor_door)),
                  title: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${d['is_active'] ? 'Active' : 'Inactive'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.lock_open, color: Colors.green),
                    tooltip: 'Remote Unlock',
                    onPressed: () async {
                      try {
                        // Call remote unlock command
                        final deviceId = d['device_id'];
                        if (deviceId != null) {
                          await ref.read(dioProvider).post('/commands/', data: {
                            'device_id': deviceId,
                            'command_type': 'unlock_door',
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unlock command transmitted'), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          throw Exception('No device linked to this door.');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(count: 3),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(doorsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDoor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
