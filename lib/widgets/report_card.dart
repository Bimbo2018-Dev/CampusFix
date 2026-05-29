import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_helpers.dart';
import 'category_chip.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.trailing,
  });

  final ReportModel report;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accentColor = report.priority == 'Urgent'
        ? AppColors.priorityColor(report.priority)
        : AppColors.statusColor(report.status);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              AppHelpers.categoryIcon(report.category),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${report.location} - ${report.reporterRole}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CategoryChip(
                              category: report.category, compact: true),
                          PriorityBadge(
                              priority: report.priority, compact: true),
                          StatusBadge(status: report.status, compact: true),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              report.isOfflineQueued
                                  ? Icons.cloud_off_outlined
                                  : AppHelpers.isReportOverdue(
                                      createdAt: report.createdAt,
                                      priority: report.priority,
                                      status: report.status,
                                    )
                                      ? Icons.timer_off_outlined
                                      : Icons.timer_outlined,
                              size: 16,
                            ),
                            label: Text(
                              report.isOfflineQueued
                                  ? 'Queued'
                                  : AppHelpers.slaLabel(
                                      report.createdAt,
                                      report.priority,
                                      report.status,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Created ${AppHelpers.formatDate(report.createdAt)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
