import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/page_wrapper.dart';

class EsslLocationsScreen extends ConsumerWidget {
  final String serverId;
  const EsslLocationsScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(esslLocationProvider(serverId));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Location List',
        description: 'Verify connected hardware statistics, sync events, and trigger commands.',
        onRefresh: () => ref.invalidate(esslLocationProvider(serverId)),
        actions: [
          ApexButton(
            label: 'Add Location',
            onPressed: () => _showLocationDialog(context, ref),
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        body: locationsAsync.when(
          data: (locations) {
            if (locations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Locations Configured', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 8),
                    Text(
                      'Add locations from your eBioserverNew to sync devices and employees per location.',
                      style: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ApexButton(
                      label: 'Add Location',
                      onPressed: () => _showLocationDialog(context, ref),
                      type: ApexButtonType.primary,
                      icon: Icons.add,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, i) {
                final loc = locations[i];
                return _LocationCard(
                  location: loc,
                  serverId: serverId,
                  onEdit: () => _showLocationDialog(context, ref, location: loc),
                  onDelete: () => _confirmDelete(context, ref, loc),
                  onToggle: (v) => ref.read(esslLocationProvider(serverId).notifier).updateLocation(loc.id, {'is_active': v}),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref, {EsslLocation? location}) {
    final codeController = TextEditingController(text: location?.code ?? '');
    final nameController = TextEditingController(text: location?.name ?? '');
    final descController = TextEditingController(text: location?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(location != null ? 'Edit Location' : 'Add Location', style: ApexTypography.cardTitle),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(
                label: 'Location Code',
                hint: 'e.g. OFFICE, WAREHOUSE',
                controller: codeController,
                required: true,
              ),
              const SizedBox(height: 12),
              ApexTextField(
                label: 'Display Name',
                hint: 'e.g. Main Office',
                controller: nameController,
                required: true,
              ),
              const SizedBox(height: 12),
              ApexTextField(
                label: 'Description',
                controller: descController,
                maxLines: 2,
              ),
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
            label: location != null ? 'Update' : 'Add',
            onPressed: () async {
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              if (code.isEmpty || name.isEmpty) return;

              final data = {
                'code': code,
                'name': name,
                'description': descController.text.trim(),
              };

              final notifier = ref.read(esslLocationProvider(serverId).notifier);
              if (location != null) {
                await notifier.updateLocation(location.id, data);
              } else {
                await notifier.addLocation(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EsslLocation location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Location', style: ApexTypography.cardTitle),
        content: Text('Delete "${location.name}" (${location.code})? This cannot be undone.', style: ApexTypography.body),
        actions: [
          ApexButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            type: ApexButtonType.outline,
          ),
          ApexButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(esslLocationProvider(serverId).notifier).deleteLocation(location.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            type: ApexButtonType.danger,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final EsslLocation location;
  final String serverId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _LocationCard({
    required this.location,
    required this.serverId,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: location.isActive ? ApexColors.primary.withOpacity(0.1) : ApexColors.neutral500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: location.isActive ? ApexColors.primary : ApexColors.neutral500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                Text('Code: ${location.code}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                if (location.description != null && location.description!.isNotEmpty)
                  Text(location.description!, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: location.isActive,
            onChanged: onToggle,
            activeColor: ApexColors.primary,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: ApexColors.error))),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}
