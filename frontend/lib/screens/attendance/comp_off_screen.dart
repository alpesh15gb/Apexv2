import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class CompOffScreen extends ConsumerStatefulWidget {
  const CompOffScreen({super.key});

  @override
  ConsumerState<CompOffScreen> createState() => _CompOffScreenState();
}

class _CompOffScreenState extends ConsumerState<CompOffScreen> {
  List<Map<String, dynamic>> _requests = [];
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
      // TODO: Connect to backend comp-off API when available
      setState(() {
        _requests = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load comp off requests';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Comp Off Register',
        description: 'Review compensatory off requests when employees work on weekends or company holidays.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _requests.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.swap_horiz_outlined,
        emptyTitle: 'No Comp Off Requests',
        emptySubtitle: 'Comp off requests will appear here once the feature is enabled.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
