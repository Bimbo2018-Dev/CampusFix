import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'responsive_layout.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton = false,
  });

  final int selectedIndex;
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;

  static const _routes = [
    CampusFixRoutes.dashboard,
    CampusFixRoutes.reports,
    CampusFixRoutes.addReport,
    CampusFixRoutes.notifications,
    CampusFixRoutes.profile,
    CampusFixRoutes.accounts,
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(
        selectedIndex: selectedIndex,
        title: title,
        child: child,
      ),
      tablet: _TabletShell(
        selectedIndex: selectedIndex,
        title: title,
        actions: actions,
        child: child,
      ),
      desktop: _DesktopShell(
        selectedIndex: selectedIndex,
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }

  static void navigate(BuildContext context, int index) {
    if (index < 0 || index >= _routes.length) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(_routes[index]);
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.title,
    required this.child,
  });

  final int selectedIndex;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        AppStateScope.watch(context).currentUser?.role == UserRoles.admin;
    final effectiveSelectedIndex =
        selectedIndex >= 0 && selectedIndex < (isAdmin ? 6 : 5)
            ? selectedIndex
            : 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/campusfix_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: effectiveSelectedIndex,
        onDestinationSelected: (index) => AppShell.navigate(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'New',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Accounts',
            ),
        ],
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.selectedIndex,
    required this.title,
    required this.child,
    this.actions,
  });

  final int selectedIndex;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        AppStateScope.watch(context).currentUser?.role == UserRoles.admin;
    final effectiveSelectedIndex =
        selectedIndex >= 0 && selectedIndex < (isAdmin ? 6 : 5)
            ? selectedIndex
            : 0;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: effectiveSelectedIndex,
              onDestinationSelected: (index) =>
                  AppShell.navigate(context, index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: IconButton.filled(
                  tooltip: 'Report new issue',
                  onPressed: () => AppShell.navigate(context, 2),
                  icon: const Icon(Icons.add),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Reports'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('New'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: Text('Alerts'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
                if (isAdmin)
                  const NavigationRailDestination(
                    icon: Icon(Icons.manage_accounts_outlined),
                    selectedIcon: Icon(Icons.manage_accounts),
                    label: Text('Accounts'),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: title, actions: actions),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.selectedIndex,
    required this.title,
    required this.child,
    this.actions,
  });

  final int selectedIndex;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final user = state.currentUser;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 288,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              border: Border(right: BorderSide(color: AppColors.outline)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.asset(
                              'assets/images/campusfix_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maintenance Portal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text('Campus Administration'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => AppShell.navigate(context, 2),
                        icon: const Icon(Icons.add),
                        label: const Text('Report New Issue'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DesktopDestination(
                      index: 0,
                      selectedIndex: selectedIndex,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      label: 'Dashboard',
                    ),
                    _DesktopDestination(
                      index: 1,
                      selectedIndex: selectedIndex,
                      icon: Icons.list_alt_outlined,
                      selectedIcon: Icons.list_alt,
                      label: 'All Reports',
                    ),
                    _DesktopDestination(
                      index: 2,
                      selectedIndex: selectedIndex,
                      icon: Icons.add_circle_outline,
                      selectedIcon: Icons.add_circle,
                      label: 'New Issue',
                    ),
                    if (user?.role == UserRoles.admin)
                      _DesktopDestination(
                        index: 5,
                        selectedIndex: selectedIndex,
                        icon: Icons.manage_accounts_outlined,
                        selectedIcon: Icons.manage_accounts,
                        label: 'Accounts',
                      ),
                    _DesktopDestination(
                      index: 3,
                      selectedIndex: selectedIndex,
                      icon: Icons.notifications_outlined,
                      selectedIcon: Icons.notifications,
                      label: 'Notifications',
                    ),
                    _DesktopDestination(
                      index: 4,
                      selectedIndex: selectedIndex,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Account Settings',
                    ),
                    const Spacer(),
                    if (user != null)
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            child: Text(
                              user.avatarText,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Logout',
                            onPressed: () {
                              state.logout();
                              Navigator.of(context)
                                  .pushReplacementNamed(CampusFixRoutes.roles);
                            },
                            icon: const Icon(Icons.logout),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title, actions: actions),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopDestination extends StatelessWidget {
  const _DesktopDestination({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.primaryContainer,
        selectedColor: Colors.white,
        iconColor: AppColors.mutedText,
        textColor: AppColors.mutedText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => AppShell.navigate(context, index),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => AppShell.navigate(context, 3),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }
}
