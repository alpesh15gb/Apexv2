import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class VisitorCardsScreen extends ConsumerStatefulWidget {
  const VisitorCardsScreen({super.key});

  @override
  ConsumerState<VisitorCardsScreen> createState() => _VisitorCardsScreenState();
}

class _VisitorCardsScreenState extends ConsumerState<VisitorCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
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
      _cards = [
        {
          'id': 'VCD001',
          'card_number': 'CARD_29013A',
          'status': 'assigned',
          'visitor_name': 'Rahul Sharma',
        },
        {
          'id': 'VCD002',
          'card_number': 'CARD_38129B',
          'status': 'available',
          'visitor_name': null,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final cardCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Visitor Card'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Card Number / ID *', controller: cardCtrl, required: true),
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
              if (cardCtrl.text.trim().isEmpty) return;
              setState(() {
                _cards.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'card_number': cardCtrl.text.trim().toUpperCase(),
                  'status': 'available',
                  'visitor_name': null,
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
        title: 'Visitor Cards',
        description: 'Manage guest credentials, temporary RFID tags, and QR barcodes allocation.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Card',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _cards.isEmpty && !_loading,
        emptyIcon: Icons.credit_card_outlined,
        emptyTitle: 'No Cards Configured',
        emptySubtitle: 'Add guest cards to allocate credentials during registrations.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _cards.length,
          itemBuilder: (context, i) {
            final c = _cards[i];
            final badge = c['status'] == 'assigned' ? ApexBadge.success('ASSIGNED') : ApexBadge.neutral('AVAILABLE');
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
                    child: const Icon(Icons.credit_card, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['card_number'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        if (c['visitor_name'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Holder: ${c['visitor_name']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                        ],
                      ],
                    ),
                  ),
                  badge,
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _cards.removeWhere((x) => x['id'] == c['id']);
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
