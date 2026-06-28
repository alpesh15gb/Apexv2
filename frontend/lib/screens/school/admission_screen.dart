import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';

final applicationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/admissions/applications');
  return res.data is List ? res.data : [];
});

final inquiriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/admissions/inquiries');
  return res.data is List ? res.data : [];
});

class AdmissionScreen extends ConsumerStatefulWidget {
  const AdmissionScreen({super.key});

  @override
  ConsumerState<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends ConsumerState<AdmissionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(applicationsProvider);
    final inquiriesAsync = ref.watch(inquiriesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Admissions', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 4),
                    Text('Manage inquiries and applications', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                  ])),
                  ElevatedButton.icon(
                    onPressed: () => _showInquiryDialog(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Inquiry'),
                    style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                  ),
                ]),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: ApexColors.primary600,
                  unselectedLabelColor: ApexColors.neutral500,
                  indicatorColor: ApexColors.primary600,
                  tabs: const [Tab(text: 'Applications'), Tab(text: 'Inquiries')],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                appsAsync.when(
                  data: (apps) {
                    if (apps.isEmpty) return Center(child: Text('No applications', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: apps.length,
                      itemBuilder: (context, i) {
                        final a = apps[i];
                        final status = a['status'] ?? 'submitted';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a['student_name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('${a['application_number'] ?? ''} • ${a['grade_applying'] ?? ''} • ${a['parent_name'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                            ])),
                            ApexBadge(
                              label: status,
                              type: status == 'enrolled' ? ApexBadgeType.success : status == 'selected' ? ApexBadgeType.info : status == 'rejected' ? ApexBadgeType.danger : ApexBadgeType.warning,
                            ),
                          ]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                inquiriesAsync.when(
                  data: (inquiries) {
                    if (inquiries.isEmpty) return Center(child: Text('No inquiries', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: inquiries.length,
                      itemBuilder: (context, i) {
                        final inq = inquiries[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(inq['student_name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('${inq['phone'] ?? ''} • ${inq['grade_applying'] ?? ''} • ${inq['source'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                            ])),
                            ApexBadge(
                              label: inq['status'] ?? 'new',
                              type: inq['status'] == 'admitted' ? ApexBadgeType.success : ApexBadgeType.warning,
                            ),
                          ]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInquiryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Inquiry'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name')),
          const SizedBox(height: 8),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 8),
          TextField(controller: parentCtrl, decoration: const InputDecoration(labelText: 'Parent Name')),
          const SizedBox(height: 8),
          TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade Applying')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post('/school/admissions/inquiries', data: {
                'student_name': nameCtrl.text, 'phone': phoneCtrl.text, 'parent_name': parentCtrl.text, 'grade_applying': gradeCtrl.text,
              });
              Navigator.pop(ctx);
              ref.invalidate(inquiriesProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
