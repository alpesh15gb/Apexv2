import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_dropdown.dart';

class PayslipsBulkDownloadScreen extends ConsumerStatefulWidget {
  const PayslipsBulkDownloadScreen({super.key});

  @override
  ConsumerState<PayslipsBulkDownloadScreen> createState() => _PayslipsBulkDownloadScreenState();
}

class _PayslipsBulkDownloadScreenState extends ConsumerState<PayslipsBulkDownloadScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _format = 'pdf'; // pdf | zip
  bool _downloading = false;

  void _download() async {
    setState(() => _downloading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing bulk export ZIP file...')),
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ZIP package downloaded successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Bulk Download Payslips',
        description: 'Batch export generated payslip PDFs for local records or distribution.',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_for_offline_outlined, size: 48, color: ApexColors.primary600),
                  const SizedBox(height: 16),
                  Text('Bulk Payslips Export', style: ApexTypography.cardTitle),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                          items: [for (int i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(months[i - 1]))],
                          onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                          items: [for (int y = 2024; y <= 2030; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                          onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ApexDropdown<String>(
                    label: 'Export Format',
                    value: _format,
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('Single Merged PDF')),
                      DropdownMenuItem(value: 'zip', child: Text('ZIP Archive of Individual PDFs')),
                    ],
                    onChanged: (v) => setState(() => _format = v ?? 'pdf'),
                  ),
                  const SizedBox(height: 24),
                  ApexButton(
                    label: _downloading ? 'Downloading...' : 'Download Batch',
                    onPressed: _downloading ? null : _download,
                    expanded: true,
                    loading: _downloading,
                    icon: _downloading ? null : Icons.download_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
