import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_section.dart';

final essProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/profile');
  return Map<String, dynamic>.from(res.data);
});

final essPayslipsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/payslips');
  return res.data is List ? res.data : [];
});

final essDocumentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/documents');
  return res.data is List ? res.data : [];
});

final essNotificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/notifications');
  return res.data is List ? res.data : [];
});

class EssProfileScreen extends ConsumerWidget {
  const EssProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(essProfileProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'My Profile'),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ApexCard(
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: ApexColors.primary.withValues(alpha: 0.1),
                  child: Text((profile['first_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.displayMedium.copyWith(fontSize: 28, color: ApexColors.primary)),
                ),
                const SizedBox(height: 12),
                Text('${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}', style: ApexTypography.sectionTitle),
                Text(profile['employee_code'] ?? '', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
              ]),
            ),
            const SizedBox(height: 16),
            ApexSection(title: 'Personal Information', children: [
              _row('Email', profile['email'] ?? '—'),
              _row('Phone', profile['phone'] ?? '—'),
              _row('Gender', profile['gender'] ?? '—'),
              _row('Date of Birth', profile['date_of_birth'] ?? '—'),
              _row('Blood Group', profile['blood_group'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            ApexSection(title: 'Employment', children: [
              _row('Employee Code', profile['employee_code'] ?? '—'),
              _row('Joining Date', profile['joining_date'] ?? '—'),
              _row('Status', profile['status'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            ApexSection(title: 'Address', children: [
              _row('Address', profile['address'] ?? '—'),
              _row('City', profile['city'] ?? '—'),
              _row('State', profile['state'] ?? '—'),
              _row('Pincode', profile['pincode'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            ApexSection(title: 'Emergency Contact', children: [
              _row('Name', profile['emergency_contact_name'] ?? '—'),
              _row('Phone', profile['emergency_contact_phone'] ?? '—'),
            ]),
          ]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
        Expanded(child: Text(value, style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class EssPayslipScreen extends ConsumerWidget {
  const EssPayslipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(essPayslipsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'My Payslips'),
      body: payslipsAsync.when(
        data: (payslips) {
          if (payslips.isEmpty) return Center(child: Text('No payslips', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payslips.length,
            itemBuilder: (context, i) {
              final p = payslips[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: ApexColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.receipt_long, color: ApexColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Month ${p['month']}/${p['year']}', style: ApexTypography.titleMedium),
                      Text('Gross: ₹${p['gross_earnings'] ?? 0} • Deductions: ₹${p['total_deductions'] ?? 0}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ])),
                    Text('₹${p['net_pay'] ?? 0}', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.success)),
                  ]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }
}

class EssDocumentScreen extends ConsumerWidget {
  const EssDocumentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(essDocumentsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'My Documents'),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) return Center(child: Text('No documents', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: ApexCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(Icons.description, color: ApexColors.primary, size: 24),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] ?? '', style: ApexTypography.titleMedium),
                      Text('${d['doc_type'] ?? ''} • ${d['file_name'] ?? ''}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ])),
                    IconButton(icon: Icon(Icons.download, size: 18, color: ApexColors.neutral500), onPressed: () {}),
                  ]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }
}

class EssNotificationScreen extends ConsumerWidget {
  const EssNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(essNotificationsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Notifications'),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) return Center(child: Text('No notifications', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: ApexCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(n['is_read'] == true ? Icons.notifications_none : Icons.notifications_active, size: 20, color: n['is_read'] == true ? ApexColors.neutral500 : ApexColors.primary),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['title'] ?? '', style: ApexTypography.titleMedium.copyWith(fontWeight: n['is_read'] == true ? FontWeight.w400 : FontWeight.w600)),
                      Text(n['message'] ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }
}
