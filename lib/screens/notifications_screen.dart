import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = AppStateScope.watch(context).generatedNotifications();

    return AppShell(
      selectedIndex: 3,
      title: 'Notifications',
      child: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              message: 'Report activity updates will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(22),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      foregroundColor: AppColors.primary,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    title: Text(
                      item['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${item['message']}\n${item['date']}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(
                      CampusFixRoutes.reportDetails,
                      arguments: item['reportId']!,
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: notifications.length,
            ),
    );
  }
}
