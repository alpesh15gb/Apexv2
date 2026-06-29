import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayCyclesScreen extends ConsumerStatefulWidget {
  const PayCyclesScreen({super.key});

  @override
  ConsumerState<PayCyclesScreen> createState() => _PayCyclesScreenState();
}

class _PayCyclesScreenState extends ConsumerState<PayCyclesScreen> {
  List<Map<String, dynamic>> _cycles = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // TODO: Connect to backend pay cycles API when available
      setState(() {
        _cycles = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pay cycles';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Pay Cycles Settings',
        description: 'Define weekly, bi-weekly, or monthly salary cycle schedules.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _cycles.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.loop_outlined,
        emptyTitle: 'No Pay Cycles',
        emptySubtitle: 'Pay cycle configuration will be available soon.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
