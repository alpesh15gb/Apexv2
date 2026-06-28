import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class TDSSettingsScreen extends ConsumerStatefulWidget {
  const TDSSettingsScreen({super.key});

  @override
  ConsumerState<TDSSettingsScreen> createState() => _TDSSettingsScreenState();
}

class _TDSSettingsScreenState extends ConsumerState<TDSSettingsScreen> {
  String _activeRegime = 'new'; // old | new

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TDS regime and slabs configuration saved'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'TDS & Tax Slabs Settings',
        description: 'Define active income tax regimes, TDS brackets, and exemption thresholds.',
        actions: [
          ApexButton(
            label: 'Save Configuration',
            onPressed: _save,
            type: ApexButtonType.primary,
            icon: Icons.save_outlined,
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income Tax Regime', style: ApexTypography.cardTitle),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('New Tax Regime (Default)'),
                    subtitle: const Text('Simplified tax rates without deductions (Section 115BAC)'),
                    value: 'new',
                    groupValue: _activeRegime,
                    onChanged: (v) => setState(() => _activeRegime = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Old Tax Regime'),
                    subtitle: const Text('Standard tax rates allowing 80C, 80D exemptions and HRA deductions'),
                    value: 'old',
                    groupValue: _activeRegime,
                    onChanged: (v) => setState(() => _activeRegime = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TDS Slabs (FY 2026-27)', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  _buildTdsRow('Income up to ₹3,00,000', 'NIL'),
                  _buildTdsRow('Income ₹3,00,001 to ₹6,00,000', '5%'),
                  _buildTdsRow('Income ₹6,00,001 to ₹9,00,000', '10%'),
                  _buildTdsRow('Income ₹9,00,001 to ₹12,00,000', '15%'),
                  _buildTdsRow('Income ₹12,00,001 to ₹15,00,000', '20%'),
                  _buildTdsRow('Income above ₹15,00,000', '30%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTdsRow(String bracket, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(bracket, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, color: ApexColors.primary)),
        ],
      ),
    );
  }
}
