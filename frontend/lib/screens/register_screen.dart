import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/apex_button.dart';
import '../widgets/apex_card.dart';
import '../widgets/apex_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _slugController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyController.dispose();
    _slugController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      try {
        await ref.read(authProvider.notifier).register(
          tenantName: _companyController.text.trim(),
          tenantSlug: _slugController.text.trim(),
          adminEmail: _emailController.text.trim(),
          adminPassword: _passwordController.text,
          adminFullName: _nameController.text.trim(),
        );
        if (mounted) context.go('/login');
      } catch (e) {
        // Error handled by listener
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: ApexColors.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text('Create Account', style: ApexTypography.headingLarge.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 4),
                Text('Set up your company and admin account', style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500)),
                const SizedBox(height: 32),

                // Form
                ApexCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ApexTextField(
                          label: 'Company Name',
                          controller: _companyController,
                          hint: 'Enter company name',
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        ApexTextField(
                          label: 'Company Slug',
                          controller: _slugController,
                          hint: 'e.g., my-company',
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        ApexTextField(
                          label: 'Admin Name',
                          controller: _nameController,
                          hint: 'Enter your full name',
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        ApexTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'Enter your email',
                          required: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        ApexTextField(
                          label: 'Password',
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          hint: 'Create a password',
                          required: true,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ApexButton(
                          label: 'Create Account',
                          onPressed: _register,
                          expanded: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('Sign In', style: ApexTypography.bodySmall.copyWith(color: ApexColors.primary600, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
