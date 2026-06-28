import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class VisitorBlacklistScreen extends ConsumerStatefulWidget {
  const VisitorBlacklistScreen({super.key});

  @override
  ConsumerState<VisitorBlacklistScreen> createState() => _VisitorBlacklistScreenState();
}

class _VisitorBlacklistScreenState extends ConsumerState<VisitorBlacklistScreen> {
  List<Map<String, dynamic>> _blacklist = [];
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
      _blacklist = [
        {
          'id': 'VBL001',
          'name': 'Ramesh Kumar',
          'phone': '9876543210',
          'reason': 'Disrupted security checkpoint operations',
          'added_on': '2026-06-15',
        },
        {
          'id': 'VBL002',
          'name': 'Suresh Mehta',
          'phone': '9812345678',
          'reason': 'Unauthorized entry attempt at server room',
          'added_on': '2026-06-10',
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blacklist Visitor'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Visitor Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Phone Number', controller: phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              ApexTextField(label: 'Reason *', controller: reasonCtrl, required: true, maxLines: 2),
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
            label: 'Add to Blacklist',
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || reasonCtrl.text.trim().isEmpty) return;
              setState(() {
                _blacklist.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty ? '—' : phoneCtrl.text.trim(),
                  'reason': reasonCtrl.text.trim(),
                  'added_on': DateTime.now().toIso8601String().substring(0, 10),
                });
              });
              Navigator.pop(ctx);
            },
            type: ApexButtonType.danger,
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
        title: 'Visitor Blacklist',
        description: 'Manage blocked guest profiles to prevent unauthorized access check-in.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Blacklist Guest',
            onPressed: _showAddDialog,
            type: ApexButtonType.danger,
            icon: Icons.block,
          ),
        ],
        isLoading: _loading,
        isEmpty: _blacklist.isEmpty && !_loading,
        emptyIcon: Icons.block_outlined,
        emptyTitle: 'Blacklist Empty',
        emptySubtitle: 'No visitors are currently blacklisted from entering the workspace.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _blacklist.length,
          itemBuilder: (context, i) {
            final b = _blacklist[i];
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
                      color: ApexColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block, color: ApexColors.error, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Phone: ${b['phone']} • Added on: ${b['added_on']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                        const SizedBox(height: 6),
                        Text('Reason: "${b['reason']}"', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral600, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  ApexBadge.danger('BLOCKED'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'remove', child: Text('Remove Block')),
                    ],
                    onSelected: (v) {
                      if (v == 'remove') {
                        setState(() {
                          _blacklist.removeWhere((x) => x['id'] == b['id']);
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
