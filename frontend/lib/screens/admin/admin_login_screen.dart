import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/dio_client.dart';
import '../../core/secure_storage.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@apexhrms.com');
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/admin/auth/login', data: {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });
      final token = res.data['access_token'];
      await secureStorage.write(StorageKeys.accessToken, token);
      await secureStorage.write('is_admin', 'true');
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      setState(() => _error = 'Invalid credentials or not a super admin');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.darkBackground,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ApexColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ApexColors.darkSurfaceVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text('Super Admin Portal', style: ApexTypography.pageTitle.copyWith(color: ApexColors.darkOnSurface)),
              const SizedBox(height: 4),
              Text('Apex HRMS Platform Management', style: ApexTypography.caption.copyWith(color: ApexColors.darkOnSurfaceVariant)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant),
                  prefixIcon: Icon(Icons.email, color: ApexColors.darkOnSurfaceVariant, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.primary500)),
                  filled: true,
                  fillColor: ApexColors.darkBackground,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: ApexTypography.body.copyWith(color: ApexColors.darkOnSurfaceVariant),
                  prefixIcon: Icon(Icons.lock, color: ApexColors.darkOnSurfaceVariant, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.darkSurfaceVariant)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.primary500)),
                  filled: true,
                  fillColor: ApexColors.darkBackground,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: ApexTypography.caption.copyWith(color: ApexColors.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ApexColors.primary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Sign In', style: ApexTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

