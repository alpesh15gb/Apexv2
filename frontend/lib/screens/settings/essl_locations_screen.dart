import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class EsslLocationsScreen extends ConsumerWidget {
  final String serverId;
  const EsslLocationsScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(esslLocationProvider(serverId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Locations'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Add Location',
            onPressed: () => _showLocationDialog(context, ref),
          ),
        ],
      ),
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No Locations Configured', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text(
                    'Add locations from your eBioserverNew to sync devices and employees per location.',
                    style: ApexTypography.body.copyWith(color: _muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showLocationDialog(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
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
        error: (e, _) => Center(child: Text('Error: $e')),
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
        title: Text(location != null ? 'Edit Location' : 'Add Location'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Location Code *',
                  hintText: 'e.g. OFFICE, WAREHOUSE',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name *',
                  hintText: 'e.g. Main Office',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: Text(location != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EsslLocation location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${location.name}" (${location.code})? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(esslLocationProvider(serverId).notifier).deleteLocation(location.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
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
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: location.isActive ? _primary.withOpacity(0.1) : _muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: location.isActive ? _primary : _muted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                Text('Code: ${location.code}', style: ApexTypography.caption.copyWith(color: _muted)),
                if (location.description != null && location.description!.isNotEmpty)
                  Text(location.description!, style: ApexTypography.captionSmall.copyWith(color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: location.isActive,
            onChanged: onToggle,
            activeColor: _primary,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger))),
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
