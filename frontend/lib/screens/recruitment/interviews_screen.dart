import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

final interviewsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/recruitment/interviews');
    return res.data['items'] ?? [];
  } catch (e) {
    return [];
  }
});

class InterviewsScreen extends ConsumerWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interviewsAsync = ref.watch(interviewsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: const Text('Interviews', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showScheduleDialog(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Schedule'),
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: interviewsAsync.when(
        data: (interviews) {
          if (interviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 64, color: ApexColors.neutral500.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No Interviews Scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  const SizedBox(height: 8),
                  const Text('Schedule interviews for your candidates', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interviews.length,
            itemBuilder: (context, i) => _InterviewCard(interview: interviews[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    final candidateIdCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String interviewType = 'hr';
    DateTime scheduledAt = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Interview'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: candidateIdCtrl, decoration: const InputDecoration(labelText: 'Candidate ID *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: interviewType,
                  decoration: const InputDecoration(labelText: 'Interview Type', border: OutlineInputBorder()),
                  items: ['hr', 'technical', 'manager', 'final'].map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                  onChanged: (v) => setDialogState(() => interviewType = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date & Time', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
                  subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(scheduledAt), style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: scheduledAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                    if (date != null) {
                      final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(scheduledAt));
                      if (time != null) setDialogState(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Meeting Link', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/recruitment/interviews', data: {
                    'candidate_id': candidateIdCtrl.text.trim(),
                    'interview_type': interviewType,
                    'scheduled_at': scheduledAt.toIso8601String(),
                    'duration_minutes': 60,
                    'location': locationCtrl.text.trim(),
                    'meeting_link': linkCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(interviewsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interview scheduled'), backgroundColor: ApexColors.successDark));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  final Map<String, dynamic> interview;
  const _InterviewCard({required this.interview});

  @override
  Widget build(BuildContext context) {
    final type = interview['interview_type'] ?? 'hr';
    final status = interview['status'] ?? 'scheduled';
    final scheduledAt = interview['scheduled_at'] ?? '';
    final location = interview['location'] ?? '';
    final rating = interview['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), size: 22, color: _statusColor(status)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_typeName(type), style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  const SizedBox(width: 8),
                  _statusBadge(status),
                  if (rating != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 14, color: ApexColors.warning),
                    Text('$rating', style: ApexTypography.captionMedium.copyWith(color: ApexColors.warning, fontWeight: FontWeight.w600)),
                  ],
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 12, color: ApexColors.neutral500),
                  const SizedBox(width: 4),
                  Text(_formatDateTime(scheduledAt), style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                  if (location.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 12, color: ApexColors.neutral500),
                    const SizedBox(width: 4),
                    Text(location, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                  ],
                ]),
              ],
            ),
          ),
          if (status == 'scheduled')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: ApexColors.neutral500),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'feedback', child: Text('Submit Feedback')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
              ],
              onSelected: (v) {
                if (v == 'feedback') _showFeedbackDialog(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackCtrl = TextEditingController();
    int rating = 3;
    String recommendation = 'hire';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Interview Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rating', style: TextStyle(fontSize: 13, color: ApexColors.neutral500)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(i < rating ? Icons.star : Icons.star_border, color: ApexColors.warning, size: 28),
                    onPressed: () => setDialogState(() => rating = i + 1),
                  )),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: recommendation,
                  decoration: const InputDecoration(labelText: 'Recommendation', border: OutlineInputBorder()),
                  items: ['hire', 'maybe', 'no_hire'].map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' ').toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => recommendation = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: feedbackCtrl, decoration: const InputDecoration(labelText: 'Feedback', border: OutlineInputBorder()), maxLines: 4),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted'), backgroundColor: ApexColors.successDark));
              },
              style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dt) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return dt?.toString() ?? '—';
    }
  }

  String _typeName(String type) {
    switch (type) {
      case 'hr': return 'HR Interview';
      case 'technical': return 'Technical Interview';
      case 'manager': return 'Manager Interview';
      case 'final': return 'Final Round';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'hr': return Icons.person;
      case 'technical': return Icons.code;
      case 'manager': return Icons.supervisor_account;
      case 'final': return Icons.gavel;
      default: return Icons.event;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled': return ApexColors.primary600;
      case 'completed': return ApexColors.successDark;
      case 'cancelled': return ApexColors.error;
      case 'no_show': return ApexColors.warning;
      default: return ApexColors.neutral500;
    }
  }
}

