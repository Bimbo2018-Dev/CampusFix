import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final user = state.currentUser;
    final submitted = state.totalSubmittedByCurrentUser();
    final resolved = state
        .getReportsForCurrentUser()
        .where((report) => report.status == ReportStatuses.resolved)
        .length;
    final pending = state
        .getReportsForCurrentUser()
        .where((report) => report.status == ReportStatuses.pending)
        .length;

    return AppShell(
      selectedIndex: 4,
      title: 'Profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      foregroundColor: AppColors.primary,
                      child: Text(
                        user?.avatarText ?? '?',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () {},
                        icon: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  user?.name ?? 'CampusFix User',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.school_outlined, size: 18),
                  label: Text(user?.role ?? 'Guest'),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.department ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 34),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 720 ? 3 : 1;
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: DashboardStatCard(
                            icon: Icons.assignment_outlined,
                            title: 'Submitted',
                            value: submitted.toString(),
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: DashboardStatCard(
                            icon: Icons.check_circle_outline,
                            title: 'Resolved',
                            value: resolved.toString(),
                            color: AppColors.resolved,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: DashboardStatCard(
                            icon: Icons.pending_actions_outlined,
                            title: 'Pending',
                            value: pending.toString(),
                            color: AppColors.pending,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 34),
                const Card(
                  child: Column(
                    children: [
                      _ProfileOption(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications Settings',
                        subtitle: 'Manage alerts and emails',
                      ),
                      Divider(height: 1),
                      _ProfileOption(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your security credentials',
                      ),
                      Divider(height: 1),
                      _ProfileOption(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English (US)',
                      ),
                      Divider(height: 1),
                      _ProfileOption(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'FAQs and contact information',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  isDestructive: true,
                  onPressed: () {
                    state.logout();
                    Navigator.of(context)
                        .pushReplacementNamed(CampusFixRoutes.roles);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLow,
        foregroundColor: AppColors.mutedText,
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
