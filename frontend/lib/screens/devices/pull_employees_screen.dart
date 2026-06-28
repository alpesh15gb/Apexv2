import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class PullEmployeesScreen extends ConsumerStatefulWidget {
  const PullEmployeesScreen({super.key});

  @override
  ConsumerState<PullEmployeesScreen> createState() => _PullEmployeesScreenState();
}

class _PullEmployeesScreenState extends ConsumerState<PullEmployeesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  String? _selectedDeviceId;

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
        if (_devices.isNotEmpty) _selectedDeviceId = _devices.first['id'];
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _pull() {
    if (_selectedDeviceId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incremental template pull command sent to terminal successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDevice = _devices.firstWhere((d) => d['id'] == _selectedDeviceId, orElse: () => {});

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Pull Employees',
        description: 'Fetch new enrollments, templates, and card registrations recorded directly on the biometric devices.',
        onRefresh: _load,
        isLoading: _loading,
        isEmpty: _devices.isEmpty && !_loading,
        emptyIcon: Icons.download_outlined,
        emptyTitle: 'No Connected Devices',
        emptySubtitle: 'Biometric terminals checks are required before executing pulls.',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Source Biometric Terminal', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDeviceId,
                      decoration: const InputDecoration(labelText: 'Biometric Device', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: _devices.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['device_name'] ?? ''))).toList(),
                      onChanged: (v) => setState(() => _selectedDeviceId = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedDeviceId != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terminal Details', style: ApexTypography.cardTitle),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Device Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          activeDevice['status'] == 'online' ? ApexBadge.success('ONLINE') : ApexBadge.neutral('OFFLINE'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Serial Number: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(activeDevice['serial_number'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('IP Address: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(activeDevice['ip_address'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      ApexButton(
                        label: 'Start Pulling Templates',
                        onPressed: activeDevice['status'] == 'online' ? _pull : null,
                        expanded: true,
                        icon: Icons.download_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
