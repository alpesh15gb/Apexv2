import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final candidatesProvider = StateNotifierProvider<CandidatesNotifier, CandidatesState>((ref) {
  return CandidatesNotifier(ref.read(dioProvider));
});

class CandidatesState {
  final List<Map<String, dynamic>> candidates;
  final bool loading;
  final String? error;
  final int total;
  final String? stageFilter;
  final String search;

  CandidatesState({
    this.candidates = const [],
    this.loading = false,
    this.error,
    this.total = 0,
    this.stageFilter,
    this.search = '',
  });

  CandidatesState copyWith({
    List<Map<String, dynamic>>? candidates,
    bool? loading,
    String? error,
    int? total,
    String? stageFilter,
    String? search,
  }) {
    return CandidatesState(
      candidates: candidates ?? this.candidates,
      loading: loading ?? this.loading,
      error: error,
      total: total ?? this.total,
      stageFilter: stageFilter ?? this.stageFilter,
      search: search ?? this.search,
    );
  }
}

class CandidatesNotifier extends StateNotifier<CandidatesState> {
  final dynamic _dio;
  CandidatesNotifier(this._dio) : super(CandidatesState()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 50};
      if (state.stageFilter != null) params['stage'] = state.stageFilter;
      if (state.search.isNotEmpty) params['search'] = state.search;

      final res = await _dio.get('/recruitment/candidates', queryParameters: params);
      final data = res.data;
      state = state.copyWith(
        candidates: List<Map<String, dynamic>>.from(data['items'] ?? []),
        loading: false,
        total: data['total'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter({String? stage}) {
    state = state.copyWith(stageFilter: stage);
    fetch();
  }

  void setSearch(String v) {
    state = state.copyWith(search: v);
    fetch();
  }

  Future<void> moveStage(String candidateId, String newStage) async {
    try {
      await _dio.put('/recruitment/candidates/$candidateId/stage', data: {'stage': newStage});
      fetch();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class CandidatesScreen extends ConsumerStatefulWidget {
  const CandidatesScreen({super.key});
  @override
  ConsumerState<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends ConsumerState<CandidatesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final candState = ref.watch(candidatesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Candidates', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddCandidateDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Candidate'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search candidates...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(candidatesProvider.notifier).setSearch(v),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                children: [
                  _stageChip('All', null, candState),
                  _stageChip('Applied', 'applied', candState),
                  _stageChip('Screening', 'screening', candState),
                  _stageChip('Interview', 'hr_interview', candState),
                  _stageChip('Offer', 'offer', candState),
                  _stageChip('Hired', 'joined', candState),
                ],
              ),
            ]),
          ),
          Expanded(
            child: candState.loading && candState.candidates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : candState.candidates.isEmpty
                    ? const Center(child: Text('No candidates found', style: TextStyle(color: _muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: candState.candidates.length,
                        itemBuilder: (context, i) => _CandidateCard(
                          candidate: candState.candidates[i],
                          onMoveStage: (stage) => ref.read(candidatesProvider.notifier).moveStage(candState.candidates[i]['id'], stage),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _stageChip(String label, String? stage, CandidatesState state) {
    final isActive = state.stageFilter == stage;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isActive ? _primary : _muted)),
      selected: isActive,
      onSelected: (_) => ref.read(candidatesProvider.notifier).setFilter(stage: stage),
      selectedColor: _primary.withOpacity(0.1),
      side: BorderSide(color: isActive ? _primary : _border),
    );
  }

  void _showAddCandidateDialog(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    String source = 'direct';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Candidate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: skillsCtrl, decoration: const InputDecoration(labelText: 'Skills', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Expected Salary', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: source,
                    decoration: const InputDecoration(labelText: 'Source', border: OutlineInputBorder()),
                    items: ['direct', 'linkedin', 'referral', 'naukri', 'indeed', 'other'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                    onChanged: (v) => setDialogState(() => source = v!),
                  )),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/recruitment/candidates', data: {
                    'first_name': firstNameCtrl.text.trim(),
                    'last_name': lastNameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'skills': skillsCtrl.text.trim(),
                    'expected_salary': double.tryParse(salaryCtrl.text),
                    'source': source,
                  });
                  Navigator.pop(ctx);
                  ref.read(candidatesProvider.notifier).fetch();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate added'), backgroundColor: _success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final Function(String) onMoveStage;

  const _CandidateCard({required this.candidate, required this.onMoveStage});

  @override
  Widget build(BuildContext context) {
    final name = '${candidate['first_name'] ?? ''} ${candidate['last_name'] ?? ''}'.trim();
    final stage = candidate['stage'] ?? 'applied';
    final email = candidate['email'] ?? '';
    final source = candidate['source'] ?? '';
    final experience = candidate['experience_years'];
    final rating = candidate['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primary.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(width: 8),
                  if (rating != null) ...[
                    Icon(Icons.star, size: 14, color: _warning),
                    const SizedBox(width: 2),
                    Text('$rating', style: const TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600)),
                  ],
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(email, style: const TextStyle(fontSize: 12, color: _muted)),
                  if (experience != null) ...[
                    const SizedBox(width: 12),
                    Text('• $experience yrs exp', style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                  if (source.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text('• $source', style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ]),
              ],
            ),
          ),
          _stageBadge(stage),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: _muted),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'screening', child: Text('Move to Screening')),
              const PopupMenuItem(value: 'hr_interview', child: Text('Move to HR Interview')),
              const PopupMenuItem(value: 'technical_interview', child: Text('Move to Technical')),
              const PopupMenuItem(value: 'offer', child: Text('Move to Offer')),
              const PopupMenuItem(value: 'rejected', child: Text('Reject')),
            ],
            onSelected: (v) => onMoveStage(v),
          ),
        ],
      ),
    );
  }

  Widget _stageBadge(String stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _stageColor(stage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_stageName(stage), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _stageColor(stage))),
    );
  }

  String _stageName(String stage) {
    return stage.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'applied': return _muted;
      case 'screening': return _primary;
      case 'hr_interview':
      case 'technical_interview':
      case 'manager_interview':
      case 'final_round': return _warning;
      case 'offer': return const Color(0xFF6366F1);
      case 'accepted':
      case 'joined': return _success;
      case 'rejected': return _danger;
      default: return _muted;
    }
  }
}
