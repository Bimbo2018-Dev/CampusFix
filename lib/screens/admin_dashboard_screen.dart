import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/report_model.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import '../utils/report_exporter.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/report_card.dart';
import '../widgets/report_table.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final reports = state.reports;
    final urgentReports = reports
        .where((report) => report.priority == ReportPriorities.urgent)
        .toList(growable: false);

    return AppShell(
      selectedIndex: 0,
      title: 'Overview',
      actions: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: TextField(
            onChanged: state.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search reports, users, or categories...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1180
                        ? 6
                        : constraints.maxWidth >= 760
                            ? 3
                            : 2;
                    final cardWidth =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    final cards = [
                      DashboardStatCard(
                        icon: Icons.assignment_outlined,
                        title: 'Total Reports',
                        value: reports.length.toString(),
                        color: AppColors.primary,
                      ),
                      DashboardStatCard(
                        icon: Icons.schedule_outlined,
                        title: 'Pending',
                        value: state
                            .countByStatus(ReportStatuses.pending)
                            .toString(),
                        color: AppColors.pending,
                      ),
                      DashboardStatCard(
                        icon: Icons.rate_review_outlined,
                        title: 'Reviewed',
                        value: state
                            .countByStatus(ReportStatuses.reviewed)
                            .toString(),
                        color: AppColors.reviewed,
                      ),
                      DashboardStatCard(
                        icon: Icons.engineering_outlined,
                        title: 'In Progress',
                        value: state
                            .countByStatus(ReportStatuses.inProgress)
                            .toString(),
                        color: AppColors.inProgress,
                      ),
                      DashboardStatCard(
                        icon: Icons.check_circle_outline,
                        title: 'Resolved',
                        value: state
                            .countByStatus(ReportStatuses.resolved)
                            .toString(),
                        color: AppColors.resolved,
                      ),
                      DashboardStatCard(
                        icon: Icons.warning_amber_outlined,
                        title: 'Urgent',
                        value: urgentReports.length.toString(),
                        color: AppColors.urgent,
                      ),
                      DashboardStatCard(
                        icon: Icons.group_outlined,
                        title: 'Accounts',
                        value: state.users.length.toString(),
                        color: AppColors.secondary,
                      ),
                    ];

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final card in cards)
                          SizedBox(width: cardWidth, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _ActionCenterPanel(state: state, reports: reports),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 920;
                    final status = _AnalyticsCard(
                      title: 'Reports by Status',
                      child: _StatusRings(reports: reports),
                    );
                    final categories = _AnalyticsCard(
                      title: 'Reports by Category',
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed(CampusFixRoutes.reports),
                        child: const Text('View Report'),
                      ),
                      child: _CategoryBars(reports: reports),
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          status,
                          const SizedBox(height: 14),
                          categories,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: status),
                        const SizedBox(width: 18),
                        Expanded(child: categories),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _UrgentReportsPanel(reports: urgentReports),
                const SizedBox(height: 26),
                _UsersPanel(state: state),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Recent Reports',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportCsv(context, reports),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportPdf(context, reports),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                    IconButton.outlined(
                      tooltip: 'Filters',
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(CampusFixRoutes.reports),
                      icon: const Icon(Icons.filter_list),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(CampusFixRoutes.reports),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final recent = state.getFilteredReports(source: reports);
                    if (recent.isEmpty) {
                      return const EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No reports match your search',
                        message:
                            'Clear your search or open All Reports to adjust filters.',
                      );
                    }

                    if (constraints.maxWidth >= 900) {
                      return ReportTable(
                        reports: recent.take(8).toList(),
                        onView: (report) => _openDetails(context, report),
                        onStatusChanged: (report, status) async {
                          try {
                            await state.updateReportStatus(report.id, status);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.apiError ??
                                        'Could not update report status.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        onDelete: (report) =>
                            _confirmDelete(context, state, report),
                      );
                    }

                    return Column(
                      children: [
                        for (final report in recent.take(6)) ...[
                          ReportCard(
                            report: report,
                            onTap: () => _openDetails(context, report),
                          ),
                          const SizedBox(height: 12),
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

  void _openDetails(BuildContext context, ReportModel report) {
    Navigator.of(context).pushNamed(
      CampusFixRoutes.reportDetails,
      arguments: report.id,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    ReportModel report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('This will remove "${report.title}" from the prototype.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await state.deleteReport(report.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.apiError ?? 'Could not delete report.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<ReportModel> reports,
  ) async {
    late final bool downloaded;
    try {
      downloaded = await ReportExporter.exportCsv(reports);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not export CSV.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded ? 'CSV export downloaded.' : 'CSV copied to clipboard.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<ReportModel> reports,
  ) async {
    try {
      await ReportExporter.exportPdf(reports);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not export PDF.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export prepared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionCenterPanel extends StatelessWidget {
  const _ActionCenterPanel({required this.state, required this.reports});

  final AppState state;
  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    final urgent = reports
        .where((report) => report.priority == ReportPriorities.urgent)
        .toList(growable: false);
    final overdue = state.overdueReports(source: reports);
    final unassigned = state.unassignedReports(source: reports);
    final needsValidation = reports
        .where(
          (report) =>
              report.reporterRole == UserRoles.student &&
              !report.isValidatedByTeacher,
        )
        .toList(growable: false);
    final queued = state.queuedReports();

    final cards = [
      _ActionCenterCard(
        icon: Icons.priority_high_outlined,
        title: 'Urgent',
        value: urgent.length.toString(),
        color: AppColors.urgent,
        reports: urgent,
      ),
      _ActionCenterCard(
        icon: Icons.timer_off_outlined,
        title: 'Overdue SLA',
        value: overdue.length.toString(),
        color: AppColors.rejected,
        reports: overdue,
      ),
      _ActionCenterCard(
        icon: Icons.assignment_ind_outlined,
        title: 'Unassigned',
        value: unassigned.length.toString(),
        color: AppColors.pending,
        reports: unassigned,
      ),
      _ActionCenterCard(
        icon: Icons.verified_outlined,
        title: 'Needs Validation',
        value: needsValidation.length.toString(),
        color: AppColors.reviewed,
        reports: needsValidation,
      ),
      _ActionCenterCard(
        icon: Icons.cloud_sync_outlined,
        title: 'Offline Queue',
        value: queued.length.toString(),
        color: AppColors.inProgress,
        reports: queued,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Admin Action Center',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 5
                    : constraints.maxWidth >= 760
                        ? 3
                        : 1;
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
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
          ],
        ),
      ),
    );
  }
}

class _ActionCenterCard extends StatelessWidget {
  const _ActionCenterCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.reports,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reports.isEmpty)
            Text('Clear', style: Theme.of(context).textTheme.bodySmall)
          else
            for (final report in reports.take(2))
              InkWell(
                onTap: () => Navigator.of(context).pushNamed(
                  CampusFixRoutes.reportDetails,
                  arguments: report.id,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${report.title} - ${AppHelpers.slaLabel(report.createdAt, report.priority, report.status)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusRings extends StatelessWidget {
  const _StatusRings({required this.reports});

  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(
            painter: _DonutPainter(reports),
            child: Center(
              child: Text(
                reports.length.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _Legend(label: 'Resolved', color: AppColors.resolved),
            _Legend(label: 'Progress', color: AppColors.inProgress),
            _Legend(label: 'Pending', color: AppColors.pending),
            _Legend(label: 'Urgent', color: AppColors.urgent),
          ],
        ),
      ],
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.reports});

  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ReportCategories.facility,
      ReportCategories.itConcern,
      ReportCategories.classroom,
      ReportCategories.clinic,
      ReportCategories.other,
    ];
    final maxCount = categories
        .map((category) => reports.where((r) => r.category == category).length)
        .fold<int>(1, (max, count) => count > max ? count : max);

    return Container(
      height: 230,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final category in categories)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: reports
                                .where((r) => r.category == category)
                                .length /
                            maxCount,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _categoryColor(category),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category.replaceAll(' Concern', ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case ReportCategories.itConcern:
        return AppColors.secondary;
      case ReportCategories.classroom:
        return AppColors.pending;
      case ReportCategories.clinic:
        return const Color(0xFF0F9F6E);
      case ReportCategories.other:
        return const Color(0xFFB8B8C8);
      case ReportCategories.facility:
      default:
        return AppColors.primaryContainer;
    }
  }
}

class _UrgentReportsPanel extends StatelessWidget {
  const _UrgentReportsPanel({required this.reports});

  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Urgent Reports',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (reports.isEmpty)
              Text(
                'No urgent reports right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final report in reports)
                    ActionChip(
                      avatar:
                          const Icon(Icons.warning_amber_outlined, size: 18),
                      label: Text(report.title),
                      onPressed: () => Navigator.of(context).pushNamed(
                        CampusFixRoutes.reportDetails,
                        arguments: report.id,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UsersPanel extends StatelessWidget {
  const _UsersPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final users = state.getFilteredUsers();
    final students = users
        .where((user) => user.role == UserRoles.student)
        .toList(growable: false);
    final teachers = users
        .where((user) => user.role == UserRoles.teacher)
        .toList(growable: false);
    final admins = users
        .where((user) => user.role == UserRoles.admin)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'User Accounts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (state.isApiConnected)
                  IconButton.outlined(
                    tooltip: 'Sync user accounts',
                    onPressed: () => state.refreshFromApi(),
                    icon: const Icon(Icons.sync),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Registered students, teachers, and admins are listed here. New accounts sync automatically from the API.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 4 : 2;
                final cardWidth =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                final cards = [
                  _UserAccountStat(
                    icon: Icons.group_outlined,
                    label: 'Total',
                    value: state.users.length.toString(),
                    color: AppColors.primary,
                  ),
                  _UserAccountStat(
                    icon: Icons.school_outlined,
                    label: 'Students',
                    value: state.countUsersByRole(UserRoles.student).toString(),
                    color: AppColors.primaryContainer,
                  ),
                  _UserAccountStat(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Teachers',
                    value: state.countUsersByRole(UserRoles.teacher).toString(),
                    color: AppColors.reviewed,
                  ),
                  _UserAccountStat(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admins',
                    value: state.countUsersByRole(UserRoles.admin).toString(),
                    color: AppColors.pending,
                  ),
                ];

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in cards)
                      SizedBox(width: cardWidth, child: card),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (users.isEmpty)
              const EmptyState(
                icon: Icons.person_search_outlined,
                title: 'No user accounts found',
                message:
                    'Clear the search field to show all registered accounts.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final groups = [
                    (
                      title: 'Students',
                      users: students,
                      color: AppColors.primary
                    ),
                    (
                      title: 'Teachers',
                      users: teachers,
                      color: AppColors.reviewed
                    ),
                    (title: 'Admins', users: admins, color: AppColors.pending),
                  ];

                  if (!wide) {
                    return Column(
                      children: [
                        for (final group in groups)
                          if (group.users.isNotEmpty) ...[
                            _UserAccountGroup(
                              title: group.title,
                              users: group.users,
                              color: group.color,
                            ),
                            const SizedBox(height: 12),
                          ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in groups) ...[
                        Expanded(
                          child: _UserAccountGroup(
                            title: group.title,
                            users: group.users,
                            color: group.color,
                          ),
                        ),
                        if (group.title != groups.last.title)
                          const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _UserAccountStat extends StatelessWidget {
  const _UserAccountStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAccountGroup extends StatelessWidget {
  const _UserAccountGroup({
    required this.title,
    required this.users,
    required this.color,
  });

  final String title;
  final List<AppUser> users;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${users.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.people_alt_outlined, color: color),
            ],
          ),
          const SizedBox(height: 10),
          if (users.isEmpty)
            Text(
              'No registered $title yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final user in users) ...[
              _UserAccountTile(user: user, color: color),
              if (user != users.last) const Divider(height: 14),
            ],
        ],
      ),
    );
  }
}

class _UserAccountTile extends StatelessWidget {
  const _UserAccountTile({
    required this.user,
    required this.color,
  });

  final AppUser user;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        child: Text(user.avatarText),
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
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.reports);

  final List<ReportModel> reports;

  @override
  void paint(Canvas canvas, Size size) {
    final total = reports.isEmpty ? 1 : reports.length;
    final strokeWidth = size.width * 0.16;
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    var start = -90.0;

    final segments = [
      (
        count: reports.where((r) => r.status == ReportStatuses.resolved).length,
        color: AppColors.resolved,
      ),
      (
        count:
            reports.where((r) => r.status == ReportStatuses.inProgress).length,
        color: AppColors.inProgress,
      ),
      (
        count: reports.where((r) => r.status == ReportStatuses.pending).length,
        color: AppColors.pending,
      ),
      (
        count:
            reports.where((r) => r.priority == ReportPriorities.urgent).length,
        color: AppColors.urgent,
      ),
    ];

    final background = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 6.283, false, background);

    for (final segment in segments) {
      if (segment.count == 0) {
        continue;
      }
      final sweep = (segment.count / total) * 360;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, start * 0.0174533, sweep * 0.0174533, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.reports != reports;
  }
}
