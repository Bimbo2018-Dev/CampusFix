import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.selectedRole});

  final String selectedRole;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late String _role;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await AppStateScope.read(context).registerUser(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _role,
      department: _departmentController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushReplacementNamed(CampusFixRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 14,
                    child: ColoredBox(color: AppColors.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 30, 30, 30),
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
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
                            'Create CampusFix Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register a local prototype account for this device.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 28),
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
                              setState(() => _role = roles.first);
                            },
                          ),
                          const SizedBox(height: 22),
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Example: Ana Reyes',
                            icon: Icons.badge_outlined,
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (value.trim().length < 3) {
                                return 'Enter a valid name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Email Address',
                            hint: 'you@campusfix.app',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email is required';
                              }
                              if (!email.contains('@') ||
                                  !email.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Department',
                            hint: 'Example: Computer Studies',
                            icon: Icons.apartment_outlined,
                            controller: _departmentController,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Department is required'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 620;
                              final fields = [
                                CustomTextField(
                                  label: 'Password',
                                  hint: 'At least 6 characters',
                                  icon: Icons.lock_outline,
                                  controller: _passwordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Use at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                CustomTextField(
                                  label: 'Confirm Password',
                                  hint: 'Repeat your password',
                                  icon: Icons.lock_reset_outlined,
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ];

                              if (!wide) {
                                return Column(
                                  children: [
                                    fields[0],
                                    const SizedBox(height: 16),
                                    fields[1],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: fields[0]),
                                  const SizedBox(width: 16),
                                  Expanded(child: fields[1]),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 26),
                          PrimaryButton(
                            label: _isSubmitting
                                ? 'Creating Account...'
                                : 'Create Account',
                            icon: Icons.arrow_forward,
                            onPressed: _isSubmitting ? null : _register,
                          ),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.login_outlined),
                            label: const Text('Already have an account? Login'),
                          ),
                        ],
                      ),
                    ),
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
