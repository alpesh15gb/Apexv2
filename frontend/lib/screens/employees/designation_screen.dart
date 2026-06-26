import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class DesignationScreen extends ConsumerWidget {
  const DesignationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desgsAsync = ref.watch(designationsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Designations'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: desgsAsync.when(
        data: (desgs) {
          if (desgs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No Designations', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text('Create designations for job roles', style: ApexTypography.bodySmall.copyWith(color: _muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context, ref),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                    child: const Text('Add Designation'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: desgs.length,
            itemBuilder: (context, i) {
              final d = desgs[i];
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
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work_outline, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                          Text('Code: ${d.code}', style: ApexTypography.captionMedium.copyWith(color: _muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: d.isActive ? _success.withOpacity(0.1) : _muted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        d.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: ApexTypography.captionSmall.copyWith(color: d.isActive ? _success : _muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _showEditDialog(context, ref, d);
                        if (v == 'delete') _confirmDelete(context, ref, d.id, d.name);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Designation'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder(), hintText: 'e.g. MGR, DEV')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              if (name.isEmpty || code.isEmpty) return;
              try {
                await ref.read(designationsProvider.notifier).addDesignation({'name': name, 'code': code});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic desg) {
    final nameCtrl = TextEditingController(text: desg.name);
    final codeCtrl = TextEditingController(text: desg.code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Designation'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              if (name.isEmpty || code.isEmpty) return;
              try {
                await ref.read(designationsProvider.notifier).updateDesignation(desg.id, {'name': name, 'code': code});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Designation'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(designationsProvider.notifier).deleteDesignation(id);
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
