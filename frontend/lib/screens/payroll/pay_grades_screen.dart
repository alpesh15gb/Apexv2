import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayGradesScreen extends ConsumerStatefulWidget {
  const PayGradesScreen({super.key});

  @override
  ConsumerState<PayGradesScreen> createState() => _PayGradesScreenState();
}

class _PayGradesScreenState extends ConsumerState<PayGradesScreen> {
  List<Map<String, dynamic>> _grades = [];
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
      // TODO: Connect to backend pay grades API when available
      setState(() {
        _grades = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pay grades';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Pay Grades',
        description: 'Define and manage salary grade brackets, minimum and maximum ranges, and designations links.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _grades.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.leaderboard_outlined,
        emptyTitle: 'Pay Grades Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
