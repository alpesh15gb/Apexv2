import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final adminFeaturesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/admin/features/');
  return res.data is List ? res.data : [];
});

class AdminFeatureScreen extends ConsumerStatefulWidget {
  const AdminFeatureScreen({super.key});

  @override
  ConsumerState<AdminFeatureScreen> createState() => _AdminFeatureScreenState();
}

class _AdminFeatureScreenState extends ConsumerState<AdminFeatureScreen> {
  String _search = '';
  String _categoryFilter = 'All';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(adminFeaturesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Feature Management', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
        actions: [
          if (_selected.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () => _bulkToggle(true),
              icon: const Icon(Icons.check, size: 16, color: _success),
              label: Text('Enable (${_selected.length})', style: const TextStyle(color: _success)),
            ),
            TextButton.icon(
              onPressed: () => _bulkToggle(false),
              icon: const Icon(Icons.close, size: 16, color: _danger),
              label: Text('Disable (${_selected.length})', style: const TextStyle(color: _danger)),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: featuresAsync.when(
        data: (features) {
          final categories = ['All', ...{...features.map((f) => f['category'] as String)}];
          final filtered = features.where((f) {
            if (_categoryFilter != 'All' && f['category'] != _categoryFilter) return false;
            if (_search.isNotEmpty && !(f['name'] as String).toLowerCase().contains(_search.toLowerCase())) return false;
            return true;
          }).toList();

          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search features...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                )),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _categoryFilter,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _surface,
              child: Row(children: [
                Checkbox(
                  value: _selected.length == filtered.length && filtered.isNotEmpty,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.addAll(filtered.map((f) => f['code'] as String));
                    } else {
                      _selected.clear();
                    }
                  }),
                ),
                const SizedBox(width: 40),
                const Expanded(flex: 2, child: Text('FEATURE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                const Expanded(child: Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                const SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                const SizedBox(width: 60),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final f = filtered[i];
                  final code = f['code'] as String;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: i.isEven ? _surface : _bg,
                    child: Row(children: [
                      Checkbox(
                        value: _selected.contains(code),
                        onChanged: (v) => setState(() {
                          if (v == true) _selected.add(code);
                          else _selected.remove(code);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
                        Text(code, style: const TextStyle(fontSize: 11, color: _muted)),
                      ])),
                      Expanded(child: Text(f['category'] ?? '', style: const TextStyle(fontSize: 12, color: _muted))),
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (f['is_active'] == true ? _success : _muted).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(f['is_active'] == true ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: f['is_active'] == true ? _success : _muted)),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Switch(
                          value: f['is_active'] == true,
                          activeColor: _primary,
                          onChanged: (v) => _toggleFeature(code, v),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _toggleFeature(String code, bool active) async {
    final dio = ref.read(dioProvider);
    await dio.put('/admin/features/$code', data: {'is_active': active});
    ref.invalidate(adminFeaturesProvider);
  }

  void _bulkToggle(bool enabled) async {
    final dio = ref.read(dioProvider);
    for (final code in _selected) {
      await dio.put('/admin/features/$code', data: {'is_active': enabled});
    }
    setState(() => _selected.clear());
    ref.invalidate(adminFeaturesProvider);
  }
}
