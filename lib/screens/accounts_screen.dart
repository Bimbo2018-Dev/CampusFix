import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/empty_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final user = state.currentUser;

    if (user?.role != UserRoles.admin) {
      return const AppShell(
        selectedIndex: 0,
        title: 'Accounts',
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'Admin access required',
          message: 'Only admins can view registered accounts.',
        ),
      );
    }

    final filteredUsers = state.getFilteredUsers();
    final students = filteredUsers
        .where((account) => account.role == UserRoles.student)
        .toList(growable: false);
    final teachers = filteredUsers
        .where((account) => account.role == UserRoles.teacher)
        .toList(growable: false);
    final admins = filteredUsers
        .where((account) => account.role == UserRoles.admin)
        .toList(growable: false);

    return AppShell(
      selectedIndex: 5,
      title: 'Accounts',
      actions: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: TextField(
            onChanged: state.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search accounts...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.outlined(
          tooltip: 'Sync accounts',
          onPressed: () => state.refreshFromApi(),
          icon: const Icon(Icons.sync),
        ),
        const SizedBox(width: 12),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 920 ? 4 : 2;
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    final cards = [
                      DashboardStatCard(
                        icon: Icons.group_outlined,
                        title: 'Total Accounts',
                        value: state.users.length.toString(),
                        color: AppColors.primary,
                      ),
                      DashboardStatCard(
                        icon: Icons.school_outlined,
                        title: 'Students',
                        value: state
                            .countUsersByRole(UserRoles.student)
                            .toString(),
                        color: AppColors.primaryContainer,
                      ),
                      DashboardStatCard(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Teachers',
                        value: state
                            .countUsersByRole(UserRoles.teacher)
                            .toString(),
                        color: AppColors.reviewed,
                      ),
                      DashboardStatCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admins',
                        value:
                            state.countUsersByRole(UserRoles.admin).toString(),
                        color: AppColors.pending,
                      ),
                      DashboardStatCard(
                        icon: Icons.verified_user_outlined,
                        title: 'Active',
                        value: state.users
                            .where((account) => account.isActive)
                            .length
                            .toString(),
                        color: AppColors.resolved,
                      ),
                    ];

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final card in cards)
                          SizedBox(width: width, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (filteredUsers.isEmpty)
                  EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'No accounts found',
                    message: 'No registered accounts match the current search.',
                    action: TextButton.icon(
                      onPressed: state.clearFilters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear Search'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final groups = [
                        (
                          title: 'Student Accounts',
                          users: students,
                          color: AppColors.primary,
                          icon: Icons.school_outlined,
                        ),
                        (
                          title: 'Teacher Accounts',
                          users: teachers,
                          color: AppColors.reviewed,
                          icon: Icons.workspace_premium_outlined,
                        ),
                        (
                          title: 'Admin Accounts',
                          users: admins,
                          color: AppColors.pending,
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                      ];

                      if (!wide) {
                        return Column(
                          children: [
                            for (final group in groups) ...[
                              _AccountGroupCard(
                                title: group.title,
                                users: group.users,
                                color: group.color,
                                icon: group.icon,
                                state: state,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final group in groups) ...[
                            Expanded(
                              child: _AccountGroupCard(
                                title: group.title,
                                users: group.users,
                                color: group.color,
                                icon: group.icon,
                                state: state,
                              ),
                            ),
                            if (group.title != groups.last.title)
                              const SizedBox(width: 14),
                          ],
                        ],
                      );
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

class _AccountGroupCard extends StatelessWidget {
  const _AccountGroupCard({
    required this.title,
    required this.users,
    required this.color,
    required this.icon,
    required this.state,
  });

  final String title;
  final List<AppUser> users;
  final Color color;
  final IconData icon;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$title (${users.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (users.isEmpty)
              Text(
                'No registered accounts.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final user in users) ...[
                _AccountTile(user: user, color: color, state: state),
                if (user != users.last) const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.user,
    required this.color,
    required this.state,
  });

  final AppUser user;
  final Color color;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        child: Text(
          user.avatarText,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${user.email}\n${user.department} - ${user.isActive ? 'Active' : 'Inactive'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Account actions',
        onSelected: (value) => _handleAction(context, value),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: user.isActive ? 'deactivate' : 'activate',
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
          const PopupMenuItem(
            value: 'role',
            child: Text('Change role'),
          ),
          const PopupMenuItem(
            value: 'department',
            child: Text('Edit department'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    try {
      if (value == 'activate' || value == 'deactivate') {
        await state.updateUserAccount(
          user,
          isActive: value == 'activate',
        );
      } else if (value == 'role') {
        final role = await _pickRole(context);
        if (role == null) {
          return;
        }
        await state.updateUserAccount(user, role: role);
      } else if (value == 'department') {
        final department = await _editDepartment(context);
        if (department == null || department.trim().isEmpty) {
          return;
        }
        await state.updateUserAccount(user, department: department);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.apiError ?? 'Could not update account.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _pickRole(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change role'),
        children: [
          for (final role in UserRoles.all)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(role),
              child: Text(role),
            ),
        ],
      ),
    );
  }

  Future<String?> _editDepartment(BuildContext context) {
    final controller = TextEditingController(text: user.department);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit department'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Department'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
