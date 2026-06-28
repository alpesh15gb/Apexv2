import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';

class LiveAttendanceScreen extends ConsumerStatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  ConsumerState<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends ConsumerState<LiveAttendanceScreen> {
  final List<Map<String, dynamic>> _punches = [];
  Timer? _timer;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate with mock records
    _punches.addAll([
      {
        'time': '10:04:12 AM',
        'name': 'Rahul Sharma',
        'code': 'EMP001',
        'type': 'Check-In',
        'device': 'HO main entrance',
        'status': 'success',
      },
      {
        'time': '10:02:44 AM',
        'name': 'Priya Patel',
        'code': 'EMP002',
        'type': 'Check-In',
        'device': 'Factory gate 1',
        'status': 'success',
      },
      {
        'time': '10:01:05 AM',
        'name': 'Amit Verma',
        'code': 'EMP003',
        'type': 'Check-In',
        'device': 'HO main entrance',
        'status': 'late',
      },
    ]);

    // Setup simulated websocket timer to add new checkins live
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_active) return;
      final names = ['Vikram Singh', 'Siddharth Rao', 'Neha Gupta', 'Ananya Sen', 'Rajesh Kumar'];
      final codes = ['EMP004', 'EMP005', 'EMP006', 'EMP007', 'EMP008'];
      final devices = ['HO Main Entrance', 'Factory Gate 1', 'Warehouse 2', 'Branch East'];
      final rand = DateTime.now().millisecondsSinceEpoch;
      final idx = rand % names.length;
      final devIdx = rand % devices.length;

      setState(() {
        _punches.insert(0, {
          'time': DateFormat('hh:mm:ss a').format(DateTime.now()),
          'name': names[idx],
          'code': codes[idx],
          'type': rand.isEven ? 'Check-In' : 'Check-Out',
          'device': devices[devIdx],
          'status': rand % 3 == 0 ? 'late' : 'success',
        });
        if (_punches.length > 20) _punches.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Live Attendance Feed',
        description: 'Real-time monitoring of connected biometric devices punches and checks.',
        actions: [
          Row(
            children: [
              Text('Live feed: ', style: ApexTypography.caption),
              Switch(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeColor: ApexColors.success,
              ),
            ],
          ),
        ],
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _punches.length,
          itemBuilder: (context, i) {
            final p = _punches[i];
            final statusColor = p['status'] == 'late' ? ApexColors.warning : ApexColors.success;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fingerprint, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        Text('${p['code']} • ${p['device']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(p['time'] as String, style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (p['type'] == 'Check-In' ? ApexColors.primary600 : ApexColors.neutral700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (p['type'] as String).toUpperCase(),
                          style: ApexTypography.captionSmall.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: p['type'] == 'Check-In' ? ApexColors.primary600 : ApexColors.neutral700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
