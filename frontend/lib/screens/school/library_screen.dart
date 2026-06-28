import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';

final booksProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/library/books', queryParameters: {'page': 1, 'page_size': 100});
  return Map<String, dynamic>.from(res.data);
});

final transactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/library/transactions');
  return res.data is List ? res.data : [];
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

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
                    Text('Library', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 4),
                    Text('Manage books, issue, and returns', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                  ])),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBookDialog(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                  ),
                ]),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: ApexColors.primary600,
                  unselectedLabelColor: ApexColors.neutral500,
                  indicatorColor: ApexColors.primary600,
                  tabs: const [Tab(text: 'Books'), Tab(text: 'Transactions')],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                booksAsync.when(
                  data: (data) {
                    final books = data['items'] ?? [];
                    if (books.isEmpty) return Center(child: Text('No books in library', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      itemBuilder: (context, i) {
                        final b = books[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.book, color: ApexColors.primary600),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b['title'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('${b['author'] ?? '-'} • ${b['category'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${b['available_copies'] ?? 0}/${b['total_copies'] ?? 0}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: (b['available_copies'] ?? 0) > 0 ? ApexColors.success : ApexColors.error)),
                              Text('available', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ]),
                          ]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) return Center(child: Text('No transactions', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        final t = transactions[i];
                        final isIssued = t['status'] == 'issued';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(6)),
                          child: Row(children: [
                            Icon(isIssued ? Icons.arrow_forward : Icons.arrow_back, size: 16, color: isIssued ? ApexColors.error : ApexColors.success),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${t['borrower_type'] ?? ''} • ${t['issue_date'] ?? ''}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900))),
                            Text(t['status'] ?? '', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: isIssued ? ApexColors.error : ApexColors.success)),
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

  void _showAddBookDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final isbnCtrl = TextEditingController();
    final copiesCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Book'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
          const SizedBox(height: 8),
          TextField(controller: isbnCtrl, decoration: const InputDecoration(labelText: 'ISBN')),
          const SizedBox(height: 8),
          TextField(controller: copiesCtrl, decoration: const InputDecoration(labelText: 'Total Copies'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post('/school/library/books', data: {
                'title': titleCtrl.text, 'author': authorCtrl.text, 'isbn': isbnCtrl.text, 'total_copies': int.tryParse(copiesCtrl.text) ?? 1,
              });
              Navigator.pop(ctx);
              ref.invalidate(booksProvider);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
