import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_card.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final user = state.currentUser;
    final reports = state.getReportsForCurrentUser();
    final filteredReports = state.getFilteredReports(source: reports);

    return AppShell(
      selectedIndex: 0,
      title: 'CampusFix',
      child: _DashboardCanvas(
        children: [
          _Header(
            greeting: 'Hello, ${user?.name ?? 'Student'}',
            subtitle: 'Here is the status of your campus maintenance reports.',
            actionLabel: 'Report an Issue',
            onAction: () => Navigator.of(context)
                .pushReplacementNamed(CampusFixRoutes.addReport),
          ),
          const SizedBox(height: 22),
          _StatsGrid(
            cards: [
              DashboardStatCard(
                icon: Icons.assignment_outlined,
                title: 'My Reports',
                value: reports.length.toString(),
                color: AppColors.primary,
              ),
              DashboardStatCard(
                icon: Icons.schedule_outlined,
                title: 'Pending',
                value: state
                    .countByStatus(ReportStatuses.pending, source: reports)
                    .toString(),
                color: AppColors.pending,
              ),
              DashboardStatCard(
                icon: Icons.engineering_outlined,
                title: 'In Progress',
                value: state
                    .countByStatus(ReportStatuses.inProgress, source: reports)
                    .toString(),
                color: AppColors.inProgress,
              ),
              DashboardStatCard(
                icon: Icons.check_circle_outline,
                title: 'Resolved',
                value: state
                    .countByStatus(ReportStatuses.resolved, source: reports)
                    .toString(),
                color: AppColors.resolved,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SearchAndStatusFilters(state: state),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Recent Reports',
            actionLabel: 'View All',
            onAction: () => Navigator.of(context)
                .pushReplacementNamed(CampusFixRoutes.reports),
          ),
          const SizedBox(height: 14),
          _ReportsList(reports: filteredReports.take(5).toList()),
        ],
      ),
    );
  }
}

class _DashboardCanvas extends StatelessWidget {
  const _DashboardCanvas({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String greeting;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 740;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 20),
              PrimaryButton(
                label: actionLabel,
                icon: Icons.add,
                onPressed: onAction,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            SizedBox(
              width: 250,
              child: PrimaryButton(
                label: actionLabel,
                icon: Icons.add,
                onPressed: onAction,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000
            ? 4
            : width >= 650
                ? 2
                : 2;
        final spacing = 12.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _SearchAndStatusFilters extends StatelessWidget {
  const _SearchAndStatusFilters({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: state.setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search reports, locations, categories...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in ['All', ...ReportStatuses.all])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: status == 'All'
                        ? state.statusFilter == null
                        : state.statusFilter == status,
                    onSelected: (_) => state.setStatusFilter(status),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({required this.reports});

  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No reports found',
        message: 'Create a report or adjust your search and filters.',
        action: PrimaryButton(
          label: 'Report an Issue',
          icon: Icons.add,
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed(CampusFixRoutes.addReport),
        ),
      );
    }

    return Column(
      children: [
        for (final report in reports) ...[
          ReportCard(
            report: report,
            onTap: () => Navigator.of(context).pushNamed(
              CampusFixRoutes.reportDetails,
              arguments: report.id,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
