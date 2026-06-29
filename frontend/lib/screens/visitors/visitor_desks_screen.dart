import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class VisitorDesksScreen extends ConsumerStatefulWidget {
  const VisitorDesksScreen({super.key});

  @override
  ConsumerState<VisitorDesksScreen> createState() => _VisitorDesksScreenState();
}

class _VisitorDesksScreenState extends ConsumerState<VisitorDesksScreen> {
  List<Map<String, dynamic>> _desks = [];
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
      _desks = [
        {
          'id': 'VDS001',
          'name': 'Main Reception Desk',
          'location': 'HO Lobby Ground Floor',
          'operators': 'Riya Sen, John Doe',
          'is_active': true,
        },
        {
          'id': 'VDS002',
          'name': 'Security Gate 1 Desk',
          'location': 'Factory Entrance Gate 1',
          'operators': 'Security Team Alpha',
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final opsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Visitor Desk'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Desk Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Location *', controller: locCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Operators', controller: opsCtrl),
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
              if (nameCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty) return;
              setState(() {
                _desks.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'location': locCtrl.text.trim(),
                  'operators': opsCtrl.text.trim().isEmpty ? 'None' : opsCtrl.text.trim(),
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
        title: 'Visitor Desks',
        description: 'Configure reception check-in desks and security gate portals.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Desk',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _desks.isEmpty && !_loading,
        emptyIcon: Icons.desk_outlined,
        emptyTitle: 'No Desks Registered',
        emptySubtitle: 'Add check-in desks coordinates for operators.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _desks.length,
          itemBuilder: (context, i) {
            final d = _desks[i];
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
                    child: const Icon(Icons.desk, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text(d['location'] as String, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            const SizedBox(width: 12),
                            Icon(Icons.people_outline, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Ops: ${d['operators']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  d['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _desks.removeWhere((x) => x['id'] == d['id']);
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
