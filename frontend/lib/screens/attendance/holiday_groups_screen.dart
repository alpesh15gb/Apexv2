import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class HolidayGroupsScreen extends ConsumerStatefulWidget {
  const HolidayGroupsScreen({super.key});

  @override
  ConsumerState<HolidayGroupsScreen> createState() => _HolidayGroupsScreenState();
}

class _HolidayGroupsScreenState extends ConsumerState<HolidayGroupsScreen> {
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
          'id': 'HG001',
          'name': 'Karnataka State Holidays',
          'code': 'KA-HOL',
          'holidays_count': 14,
          'mapped_branches': 'HO (Bangalore), Branch East',
          'is_active': true,
        },
        {
          'id': 'HG002',
          'name': 'Maharashtra State Holidays',
          'code': 'MH-HOL',
          'holidays_count': 12,
          'mapped_branches': 'Mumbai Plant, Pune Warehouse',
          'is_active': true,
        },
        {
          'id': 'HG003',
          'name': 'National Holiday List',
          'code': 'NAT-HOL',
          'holidays_count': 8,
          'mapped_branches': 'All locations standard default',
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Holiday Group'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Group Name *', controller: nameCtrl, required: true),
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
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
              setState(() {
                _groups.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'holidays_count': 0,
                  'mapped_branches': 'None',
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
        title: 'Holiday Groups',
        description: 'Organize and map regional or state-specific holiday calendars to branches.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Group',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.group_work_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _groups.isEmpty && !_loading,
        emptyIcon: Icons.group_work_outlined,
        emptyTitle: 'No Holiday Groups',
        emptySubtitle: 'Create holiday groups for location-specific calendars.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _groups.length,
          itemBuilder: (context, i) {
            final g = _groups[i];
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
                    child: const Icon(Icons.group_work, color: ApexColors.primary600, size: 20),
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
                            Icon(Icons.event_note, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('${g['holidays_count']} Holidays', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            const SizedBox(width: 12),
                            Icon(Icons.store, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Mapped: ${g['mapped_branches']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
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
