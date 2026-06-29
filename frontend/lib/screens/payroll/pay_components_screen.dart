import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayComponentsScreen extends ConsumerStatefulWidget {
  const PayComponentsScreen({super.key});

  @override
  ConsumerState<PayComponentsScreen> createState() => _PayComponentsScreenState();
}

class _PayComponentsScreenState extends ConsumerState<PayComponentsScreen> {
  List<Map<String, dynamic>> _components = [];
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
      // TODO: Connect to backend pay components API when available
      setState(() {
        _components = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pay components';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Pay Components',
        description: 'Define and configure salary earnings, allowances, pre-tax deductions, and bonuses.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _components.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.extension_outlined,
        emptyTitle: 'Pay Components Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
