import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/access_control_service.dart';
import './zone_list_screen.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
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
          title: Text('Add Access Door', style: ApexTypography.sectionTitle),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(
                  label: 'Door Name',
                  controller: _nameController,
                  required: true,
                ),
                const SizedBox(height: 12),
                zonesAsync.maybeWhen(
                  data: (list) => ApexDropdown<String>(
                    label: 'Access Zone',
                    value: _selectedZoneId,
                    required: true,
                    items: list.map((z) => DropdownMenuItem<String>(value: z['id'], child: Text(z['name']))).toList(),
                    onChanged: (v) => setState(() => _selectedZoneId = v),
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
    final doorsAsync = ref.watch(doorsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Access Doors'),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ApexColors.primary100,
                        child: Icon(Icons.sensor_door, color: ApexColors.primary600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['name'], style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                            Text('Status: ${d['is_active'] ? 'Active' : 'Inactive'}', style: ApexTypography.captionSmall.copyWith(color: d['is_active'] ? ApexColors.success : ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.lock_open, color: ApexColors.success),
                        tooltip: 'Remote Unlock',
                        onPressed: () async {
                          try {
                            final deviceId = d['device_id'];
                            if (deviceId != null) {
                              await ref.read(dioProvider).post('/commands/', data: {
                                'device_id': deviceId,
                                'command_type': 'unlock_door',
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unlock command transmitted'), backgroundColor: ApexColors.success),
                                );
                              }
                            } else {
                              throw Exception('No device linked to this door.');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: ApexColors.error),
                            );
                          }
                        },
                      ),
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
          onRetry: () => ref.invalidate(doorsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDoor,
        backgroundColor: ApexColors.primary600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
