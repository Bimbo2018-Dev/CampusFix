import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../utils/report_exporter.dart';
import '../widgets/app_shell.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_card.dart';
import '../widgets/report_table.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final reports = state.getFilteredReports();

    return AppShell(
      selectedIndex: 1,
      title: 'All Reports',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Search, filter, and open reports based on your role access.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (state.currentUser?.role == UserRoles.admin) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportCsv(context, reports),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Export CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportPdf(context, reports),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _Filters(state: state),
                const SizedBox(height: 20),
                if (reports.isEmpty)
                  EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No reports found',
                    message: 'Try a different search or clear the filters.',
                    action: PrimaryButton(
                      label: 'Clear Filters',
                      icon: Icons.refresh,
                      onPressed: () => state.clearFilters(),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return ReportTable(
                          reports: reports,
                          onView: (report) => _openDetails(context, report),
                          onStatusChanged: state.currentUser?.role ==
                                  UserRoles.admin
                              ? (report, status) async {
                                  try {
                                    await state.updateReportStatus(
                                      report.id,
                                      status,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            state.apiError ??
                                                'Could not update report.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          onDelete: state.currentUser?.role == UserRoles.admin
                              ? (report) =>
                                  _confirmDelete(context, state, report)
                              : null,
                        );
                      }

                      return Column(
                        children: [
                          for (final report in reports) ...[
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
        content: Text('This will remove "${report.title}".'),
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

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final search = TextField(
              onChanged: state.setSearchQuery,
              decoration: const InputDecoration(
                labelText: 'Search reports',
                prefixIcon: Icon(Icons.search),
              ),
            );
            final status = CustomDropdown(
              label: 'Status',
              items: ReportStatuses.all,
              value: state.statusFilter ?? 'All',
              includeAllOption: true,
              onChanged: state.setStatusFilter,
            );
            final priority = CustomDropdown(
              label: 'Priority',
              items: ReportPriorities.all,
              value: state.priorityFilter ?? 'All',
              includeAllOption: true,
              onChanged: state.setPriorityFilter,
            );
            final category = CustomDropdown(
              label: 'Category',
              items: ReportCategories.all,
              value: state.categoryFilter ?? 'All',
              includeAllOption: true,
              onChanged: state.setCategoryFilter,
            );

            if (!wide) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 12),
                  status,
                  const SizedBox(height: 12),
                  priority,
                  const SizedBox(height: 12),
                  category,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => state.clearFilters(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: status),
                const SizedBox(width: 12),
                Expanded(child: priority),
                const SizedBox(width: 12),
                Expanded(child: category),
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: 'Clear filters',
                  onPressed: () => state.clearFilters(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
