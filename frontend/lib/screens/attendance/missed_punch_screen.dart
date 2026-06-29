import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class MissedPunchScreen extends ConsumerStatefulWidget {
  const MissedPunchScreen({super.key});

  @override
  ConsumerState<MissedPunchScreen> createState() => _MissedPunchScreenState();
}

class _MissedPunchScreenState extends ConsumerState<MissedPunchScreen> {
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
      // TODO: Connect to backend missed punch API when available
      setState(() {
        _requests = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load missed punch requests';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Missed Punch Queue',
        description: 'Review and approve missed check-in and check-out requests from biometric terminals.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _requests.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.fingerprint,
        emptyTitle: 'No Missed Punches',
        emptySubtitle: 'Missed punch requests will appear here once the feature is enabled.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
