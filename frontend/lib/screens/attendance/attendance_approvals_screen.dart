import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class AttendanceApprovalsScreen extends ConsumerStatefulWidget {
  const AttendanceApprovalsScreen({super.key});

  @override
  ConsumerState<AttendanceApprovalsScreen> createState() => _AttendanceApprovalsScreenState();
}

class _AttendanceApprovalsScreenState extends ConsumerState<AttendanceApprovalsScreen> {
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
      // TODO: Connect to backend attendance approval API when available
      setState(() {
        _requests = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load attendance approvals';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Approvals',
        description: 'Review and act on pending attendance regularization and correction requests.',
        onRefresh: _load,
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _requests.isEmpty && !_loading && _error == null,
        emptyIcon: Icons.how_to_reg_outlined,
        emptyTitle: 'No Pending Approvals',
        emptySubtitle: 'Attendance approval requests will appear here once the feature is enabled.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
