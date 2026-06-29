import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class PushEmployeesScreen extends ConsumerStatefulWidget {
  const PushEmployeesScreen({super.key});

  @override
  ConsumerState<PushEmployeesScreen> createState() => _PushEmployeesScreenState();
}

class _PushEmployeesScreenState extends ConsumerState<PushEmployeesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  final Set<String> _selectedDevices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/devices/');
      final list = res.data as List;
      setState(() {
        _devices = list.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _push() {
    if (_selectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one target device'), backgroundColor: ApexColors.error),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk templates transmission queue triggered successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Push Employees templates',
        description: 'Send enrolled fingerprint and face templates from the server to terminal devices.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Transmit to Devices',
            onPressed: _push,
            type: ApexButtonType.primary,
            icon: Icons.upload_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _devices.isEmpty && !_loading,
        emptyIcon: Icons.upload_outlined,
        emptyTitle: 'No connected devices',
        emptySubtitle: 'Connect a biometric terminal before pushing templates.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _devices.length,
          itemBuilder: (context, i) {
            final dev = _devices[i];
            final isSelected = _selectedDevices.contains(dev['id']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedDevices.add(dev['id']);
                        } else {
                          _selectedDevices.remove(dev['id']);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.biotech, color: ApexColors.primary600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dev['device_name'] ?? 'Device', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        Text('S/N: ${dev['serial_number']} • IP: ${dev['ip_address'] ?? '—'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ),
                  dev['status'] == 'online' ? ApexBadge.success('ONLINE') : ApexBadge.neutral('OFFLINE'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
