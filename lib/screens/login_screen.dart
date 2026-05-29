import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.selectedRole});

  final String selectedRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _role;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
    _prefillForRole();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _prefillForRole() {
    switch (_role) {
      case UserRoles.teacher:
        _emailController.text = DemoCredentials.teacherEmail;
        _passwordController.text = DemoCredentials.teacherPassword;
        break;
      case UserRoles.admin:
        _emailController.text = DemoCredentials.adminEmail;
        _passwordController.text = DemoCredentials.adminPassword;
        break;
      case UserRoles.student:
      default:
        _emailController.text = DemoCredentials.studentEmail;
        _passwordController.text = DemoCredentials.studentPassword;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final state = AppStateScope.read(context);
    final success = await state.login(
      role: _role,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.apiError ?? 'Invalid account for the selected role.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(CampusFixRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 14, color: AppColors.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 128,
                                height: 128,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    'assets/images/campusfix_logo.png',
                                    fit: BoxFit.contain,
                                    semanticLabel: 'CampusFix logo',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Login to CampusFix',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Secure access for campus administration',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 28),
                              CustomTextField(
                                label: 'Email Address',
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                label: 'Password',
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select Role',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<String>(
                                segments: [
                                  for (final role in UserRoles.all)
                                    ButtonSegment(
                                      value: role,
                                      icon: Icon(AppHelpers.roleIcon(role)),
                                      label: Text(role),
                                    ),
                                ],
                                selected: {_role},
                                onSelectionChanged: (roles) {
                                  setState(() {
                                    _role = roles.first;
                                    _prefillForRole();
                                  });
                                },
                              ),
                              const SizedBox(height: 26),
                              PrimaryButton(
                                label:
                                    _isSubmitting ? 'Signing in...' : 'Login',
                                icon: Icons.arrow_forward,
                                onPressed: _isSubmitting ? null : _login,
                              ),
                              const SizedBox(height: 26),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Demo account: ${DemoCredentials.helperForRole(_role)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    CampusFixRoutes.register,
                                    arguments: _role,
                                  );
                                },
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('Create a new account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
