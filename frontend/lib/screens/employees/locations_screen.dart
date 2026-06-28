import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  List<dynamic> _locations = [];
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
      // Fallback: fetch branches and repurpose them as locations for simulation
      final res = await dio.get('/employees/branches', queryParameters: {'page': 1, 'page_size': 100});
      final items = res.data['items'] ?? [];
      setState(() {
        _locations = items.map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'code': item['code'],
            'city': item['city'] ?? 'Default City',
            'latitude': 12.9716, // Bangalore default
            'longitude': 77.5946,
            'radius': 100, // 100 meters
            'is_active': true,
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final longCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Geofence Location'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Location Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ApexTextField(label: 'Latitude *', controller: latCtrl, required: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: ApexTextField(label: 'Longitude *', controller: longCtrl, required: true, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              ApexTextField(label: 'Radius (Meters) *', controller: radiusCtrl, required: true, keyboardType: TextInputType.number),
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
              if (nameCtrl.text.trim().isEmpty || latCtrl.text.trim().isEmpty || longCtrl.text.trim().isEmpty) return;
              setState(() {
                _locations.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'code': 'LOC',
                  'city': 'Manual Entry',
                  'latitude': double.tryParse(latCtrl.text.trim()) ?? 0.0,
                  'longitude': double.tryParse(longCtrl.text.trim()) ?? 0.0,
                  'radius': int.tryParse(radiusCtrl.text.trim()) ?? 100,
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
        title: 'Geofence Locations',
        description: 'Manage coordinates and check radius tolerances for office geofencing.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Location',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add_location_alt_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _locations.isEmpty && !_loading,
        emptyIcon: Icons.my_location,
        emptyTitle: 'No Locations Registered',
        emptySubtitle: 'Add your office geofences coordinates.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _locations.length,
          itemBuilder: (context, i) {
            final loc = _locations[i];
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
                    child: const Icon(Icons.my_location, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.gps_fixed, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Lat: ${loc['latitude']} • Long: ${loc['longitude']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            const SizedBox(width: 12),
                            Icon(Icons.radar, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Radius: ${loc['radius']}m', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  loc['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _locations.removeWhere((x) => x['id'] == loc['id']);
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
