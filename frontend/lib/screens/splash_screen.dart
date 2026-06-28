import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/secure_storage.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    try {
      final authState = ref.read(authProvider);
      if (authState.value != null) {
        final isAdmin = await secureStorage.read('is_admin') == 'true';
        if (isAdmin) {
          context.go('/admin/dashboard');
        } else {
          context.go('/dashboard');
        }
      } else {
        context.go('/login');
      }
    } catch (_) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'APEX HRMS',
              style: ApexTypography.pageTitle.copyWith(
                color: ApexColors.darkOnSurface,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enterprise HR Management Platform',
              style: ApexTypography.body.copyWith(
                color: ApexColors.darkOnSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: ApexColors.primary500,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
