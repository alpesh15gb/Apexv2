import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class GeofencingScreen extends ConsumerStatefulWidget {
  const GeofencingScreen({super.key});

  @override
  ConsumerState<GeofencingScreen> createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends ConsumerState<GeofencingScreen> {
  final _radiusBufferCtrl = TextEditingController(text: '20');
  bool _mockGpsBlock = true;
  bool _trackLocations = false;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geofencing policies updated successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Geofencing Policies',
        description: 'Define GPS radius buffers, mock-location flags, and mobile check-in permissions.',
        actions: [
          ApexButton(
            label: 'Save Policies',
            onPressed: _save,
            type: ApexButtonType.primary,
            icon: Icons.save_outlined,
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GPS Precision Limits', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Radius Buffer Offset (Meters)',
                    controller: _radiusBufferCtrl,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Block Mock GPS Locations'),
                    subtitle: const Text('Prevent punches when developer options mock coordinates are detected.'),
                    value: _mockGpsBlock,
                    onChanged: (v) => setState(() => _mockGpsBlock = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Continuous Location Tracking'),
                    subtitle: const Text('Track employee coordinates in the background during shift hours.'),
                    value: _trackLocations,
                    onChanged: (v) => setState(() => _trackLocations = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
