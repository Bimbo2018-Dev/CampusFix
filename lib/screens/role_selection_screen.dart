import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_download.dart';
import '../utils/app_helpers.dart';
import '../widgets/primary_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _installApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await installCampusFixApp();

    messenger.showSnackBar(
      SnackBar(
        content: Text(_messageForInstallResult(result)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _messageForInstallResult(AppInstallResult result) {
    return switch (result) {
      AppInstallResult.pwaInstall => 'Opening CampusFix app installer...',
      AppInstallResult.androidDownload =>
        'Downloading CampusFix Android APK...',
      AppInstallResult.alreadyInstalled =>
        'CampusFix is already installed as an app.',
      AppInstallResult.cancelled => 'CampusFix app install was cancelled.',
      AppInstallResult.unavailable =>
        'Install prompt is not available yet. Use the browser install icon or open the built PWA version.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      (
        role: UserRoles.student,
        title: 'Student',
        description: 'Report campus issues and track your requests.',
        color: AppColors.primary,
      ),
      (
        role: UserRoles.teacher,
        title: 'Teacher',
        description: 'Submit classroom concerns and validate student reports.',
        color: AppColors.reviewed,
      ),
      (
        role: UserRoles.admin,
        title: 'Admin',
        description:
            'Manage reports, update status, and monitor campus issues.',
        color: AppColors.pending,
      ),
    ];

    return Scaffold(
      body: CustomPaint(
        painter: _DotGridPainter(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final horizontalPadding = viewport.maxWidth < 420 ? 16.0 : 24.0;
              final availableWidth =
                  viewport.maxWidth - (horizontalPadding * 2);
              final contentWidth =
                  availableWidth > 980 ? 980.0 : availableWidth;

              return SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Center(
                  child: SizedBox(
                    width: contentWidth < 0 ? 0 : contentWidth,
                    child: Column(
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
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
                        const SizedBox(height: 28),
                        Text(
                          'Welcome to\nCampusFix',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 48,
                                height: 1.06,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Please select your role to continue',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 24),
                          _DownloadAppPanel(onPressed: _installApp),
                        ],
                        const SizedBox(height: 40),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 820;
                            return Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              children: [
                                for (final item in roles)
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth - 36) / 3
                                        : constraints.maxWidth,
                                    child: _RoleCard(
                                      role: item.role,
                                      title: item.title,
                                      description: item.description,
                                      color: item.color,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 34),
                        Text.rich(
                          const TextSpan(
                            text: 'Need help? Contact ',
                            children: [
                              TextSpan(
                                text: 'IT Support',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DownloadAppPanel extends StatelessWidget {
  const _DownloadAppPanel({required this.onPressed});

  final Future<void> Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            final text = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'Install CampusFix as an app',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On laptop, install the PWA. On Android, download the APK.',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final button = PrimaryButton(
              label: 'Install App',
              icon: Icons.install_desktop_rounded,
              fullWidth: compact,
              onPressed: () => onPressed(context),
            );

            if (compact) {
              return Column(
                children: [
                  text,
                  const SizedBox(height: 12),
                  button,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 14),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.description,
    required this.color,
  });

  final String role;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppStateScope.read(context).setSelectedRole(role);
          Navigator.of(context).pushNamed(
            CampusFixRoutes.login,
            arguments: role,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppHelpers.roleIcon(role), color: color, size: 30),
              ),
              const SizedBox(height: 28),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4E3FF)
      ..strokeWidth = 1;

    for (double x = 16; x < size.width; x += 36) {
      for (double y = 16; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
