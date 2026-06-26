import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'My Profile'),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _primary.withOpacity(0.1),
                  child: Text((profile['first_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _primary)),
                ),
                const SizedBox(height: 12),
                Text('${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
                Text(profile['employee_code'] ?? '', style: const TextStyle(fontSize: 13, color: _muted)),
              ]),
            ),
            const SizedBox(height: 16),
            _section('Personal Information', [
              _row('Email', profile['email'] ?? '—'),
              _row('Phone', profile['phone'] ?? '—'),
              _row('Gender', profile['gender'] ?? '—'),
              _row('Date of Birth', profile['date_of_birth'] ?? '—'),
              _row('Blood Group', profile['blood_group'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            _section('Employment', [
              _row('Employee Code', profile['employee_code'] ?? '—'),
              _row('Joining Date', profile['joining_date'] ?? '—'),
              _row('Status', profile['status'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            _section('Address', [
              _row('Address', profile['address'] ?? '—'),
              _row('City', profile['city'] ?? '—'),
              _row('State', profile['state'] ?? '—'),
              _row('Pincode', profile['pincode'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            _section('Emergency Contact', [
              _row('Name', profile['emergency_contact_name'] ?? '—'),
              _row('Phone', profile['emergency_contact_phone'] ?? '—'),
            ]),
          ]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: _muted))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: _text, fontWeight: FontWeight.w500))),
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
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'My Payslips'),
      body: payslipsAsync.when(
        data: (payslips) {
          if (payslips.isEmpty) return const Center(child: Text('No payslips', style: TextStyle(color: _muted)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payslips.length,
            itemBuilder: (context, i) {
              final p = payslips[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_long, color: _primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Month ${p['month']}/${p['year']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                    Text('Gross: ₹${p['gross_earnings'] ?? 0} • Deductions: ₹${p['total_deductions'] ?? 0}', style: const TextStyle(fontSize: 12, color: _muted)),
                  ])),
                  Text('₹${p['net_pay'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _success)),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'My Documents'),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) return const Center(child: Text('No documents', style: TextStyle(color: _muted)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Row(children: [
                  const Icon(Icons.description, color: _primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    Text('${d['doc_type'] ?? ''} • ${d['file_name'] ?? ''}', style: const TextStyle(fontSize: 11, color: _muted)),
                  ])),
                  IconButton(icon: const Icon(Icons.download, size: 18, color: _muted), onPressed: () {}),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'Notifications'),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) return const Center(child: Text('No notifications', style: TextStyle(color: _muted)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: n['is_read'] == true ? _surface : _primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Row(children: [
                  Icon(n['is_read'] == true ? Icons.notifications_none : Icons.notifications_active, size: 20, color: n['is_read'] == true ? _muted : _primary),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: n['is_read'] == true ? FontWeight.w400 : FontWeight.w600, color: _text)),
                    Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: _muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
