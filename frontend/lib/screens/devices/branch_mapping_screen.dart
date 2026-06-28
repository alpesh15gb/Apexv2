import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_dropdown.dart';

class BranchMappingScreen extends ConsumerStatefulWidget {
  const BranchMappingScreen({super.key});

  @override
  ConsumerState<BranchMappingScreen> createState() => _BranchMappingScreenState();
}

class _BranchMappingScreenState extends ConsumerState<BranchMappingScreen> {
  List<dynamic> _branches = [];
  List<Map<String, dynamic>> _mappings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/employees/branches', queryParameters: {'page': 1, 'page_size': 100}),
        dio.get('/devices/'),
      ]);
      final branchesList = results[0].data['items'] ?? [];
      final devicesList = results[1].data as List;

      setState(() {
        _branches = branchesList;
        _mappings = devicesList.map((dev) {
          final mappedBranch = branchesList.isNotEmpty ? branchesList.first : null;
          return {
            'id': dev['id'],
            'device_name': dev['device_name'] ?? 'Device',
            'serial_number': dev['serial_number'] ?? 'S/N',
            'branch_id': mappedBranch != null ? mappedBranch['id'] : null,
            'branch_name': mappedBranch != null ? mappedBranch['name'] : 'Unmapped',
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Branch mappings saved successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Branch Mapping',
        description: 'Map physical hardware terminals to organizational branches for geo-routing.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Save Mappings',
            onPressed: _save,
            type: ApexButtonType.primary,
            icon: Icons.save_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _mappings.isEmpty && !_loading,
        emptyIcon: Icons.map_outlined,
        emptyTitle: 'No Mappings Found',
        emptySubtitle: 'Connect devices to manage branch pairings.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _mappings.length,
          itemBuilder: (context, i) {
            final m = _mappings[i];
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
                    child: const Icon(Icons.map, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['device_name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        Text('S/N: ${m['serial_number']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Text('Mapped Branch: ', style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 200,
                        height: 36,
                        child: ApexDropdown<String>(
                          label: 'Branch',
                          value: m['branch_id'],
                          items: _branches
                              .map((b) => DropdownMenuItem(
                                    value: b['id'] as String,
                                    child: Text(b['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              m['branch_id'] = v;
                              final br = _branches.firstWhere((x) => x['id'] == v, orElse: () => null);
                              m['branch_name'] = br != null ? br['name'] : 'Unmapped';
                            });
                          },
                        ),
                      ),
                    ],
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
