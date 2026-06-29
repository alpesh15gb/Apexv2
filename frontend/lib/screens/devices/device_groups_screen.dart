import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class DeviceGroupsScreen extends ConsumerStatefulWidget {
  const DeviceGroupsScreen({super.key});

  @override
  ConsumerState<DeviceGroupsScreen> createState() => _DeviceGroupsScreenState();
}

class _DeviceGroupsScreenState extends ConsumerState<DeviceGroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _groups = [
        {
          'id': 'DG001',
          'name': 'HO Main Readers',
          'code': 'HO-READ',
          'devices_count': 3,
          'description': 'Biometric terminals at Head Office main entrance and reception.',
          'is_active': true,
        },
        {
          'id': 'DG002',
          'name': 'Factory Gate Readers',
          'code': 'FAC-READ',
          'devices_count': 4,
          'description': 'Industrial turnstiles at factory gate 1 and gate 2.',
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Device Group'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Group Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Code *', controller: codeCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Description', controller: descCtrl, maxLines: 2),
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
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
              setState(() {
                _groups.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'devices_count': 0,
                  'description': descCtrl.text.trim(),
                  'is_active': true,
                });
              });
              Navigator.pop(ctx);
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Device Groups',
        description: 'Define groups of terminals to route command queues and sync requests.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Group',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.device_hub_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _groups.isEmpty && !_loading,
        emptyIcon: Icons.device_hub_outlined,
        emptyTitle: 'No Device Groups',
        emptySubtitle: 'Create device groups for regional command routing.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _groups.length,
          itemBuilder: (context, i) {
            final g = _groups[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
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
                    child: const Icon(Icons.device_hub, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.devices, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('${g['devices_count']} Devices', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                        if (g['description'] != null && (g['description'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(g['description'] as String, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  g['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _groups.removeWhere((x) => x['id'] == g['id']);
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
