import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_card.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final user = state.currentUser;
    final reports = state.getReportsForCurrentUser();
    final studentReports = reports
        .where((report) => report.reporterRole == UserRoles.student)
        .toList(growable: false);
    final submittedReports = reports
        .where((report) => report.reporterId == user?.id)
        .toList(growable: false);
    final needsValidation =
        studentReports.where((report) => !report.isValidatedByTeacher).toList();

    return AppShell(
      selectedIndex: 0,
      title: 'CampusFix',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeacherHeader(
                  name: user?.name ?? 'Teacher',
                  onAction: () => Navigator.of(context)
                      .pushReplacementNamed(CampusFixRoutes.addReport),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 1000
                        ? 4
                        : width >= 650
                            ? 2
                            : 2;
                    final cardWidth = (width - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: DashboardStatCard(
                            icon: Icons.assignment_outlined,
                            title: 'Submitted Reports',
                            value: submittedReports.length.toString(),
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: DashboardStatCard(
                            icon: Icons.groups_outlined,
                            title: 'Student Reports',
                            value: studentReports.length.toString(),
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: DashboardStatCard(
                            icon: Icons.verified_outlined,
                            title: 'Needs Validation',
                            value: needsValidation.length.toString(),
                            color: AppColors.pending,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: DashboardStatCard(
                            icon: Icons.priority_high_outlined,
                            title: 'Urgent Issues',
                            value: state
                                .countByPriority(
                                  ReportPriorities.urgent,
                                  source: reports,
                                )
                                .toString(),
                            color: AppColors.urgent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  'Needs Validation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                if (needsValidation.isEmpty)
                  const EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'All student reports are validated',
                    message:
                        'New student reports that need teacher review will appear here.',
                  )
                else
                  for (final report in needsValidation.take(4)) ...[
                    ReportCard(
                      report: report,
                      trailing: TextButton.icon(
                        onPressed: () async {
                          try {
                            await state.validateReportByTeacher(report.id);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.apiError ??
                                        'Could not validate report.',
                                  ),
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
                              content: Text('Report validated.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Validate'),
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        CampusFixRoutes.reportDetails,
                        arguments: report.id,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Classroom and Student Reports',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(CampusFixRoutes.reports),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final report in reports.take(5)) ...[
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
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({required this.name, required this.onAction});

  final String name;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 740;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Validate student reports and monitor classroom concerns.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );

        final button = PrimaryButton(
          label: 'Submit Classroom Concern',
          icon: Icons.add,
          onPressed: onAction,
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 20), button],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            const SizedBox(width: 18),
            SizedBox(width: 310, child: button),
          ],
        );
      },
    );
  }
}
