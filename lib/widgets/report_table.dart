import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class ReportTable extends StatefulWidget {
  const ReportTable({
    super.key,
    required this.reports,
    required this.onView,
    this.onStatusChanged,
    this.onDelete,
  });

  final List<ReportModel> reports;
  final ValueChanged<ReportModel> onView;
  final void Function(ReportModel report, String status)? onStatusChanged;
  final ValueChanged<ReportModel>? onDelete;

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_horizontalController.hasClients) {
      return;
    }

    final target = (_horizontalController.offset + delta)
        .clamp(0.0, _horizontalController.position.maxScrollExtent)
        .toDouble();

    _horizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.outlined(
                  tooltip: 'Scroll left',
                  onPressed: () => _scrollBy(-420),
                  icon: const Icon(Icons.keyboard_arrow_left),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Scroll right',
                  onPressed: () => _scrollBy(420),
                  icon: const Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
          ),
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: const EdgeInsets.only(bottom: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1540),
                  child: DataTable(
                    columnSpacing: 38,
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF3F4F5)),
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Reporter')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Priority')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Assigned')),
                      DataColumn(label: Text('SLA')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: widget.reports
                        .map(
                          (report) => DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 260,
                                  child: Text(
                                    report.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () => widget.onView(report),
                              ),
                              DataCell(SizedBox(
                                width: 170,
                                child: Text(
                                  report.reporterName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Text(report.reporterRole)),
                              DataCell(
                                SizedBox(
                                  width: 170,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppHelpers.categoryIcon(
                                            report.category),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          report.category,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(PriorityBadge(
                                  priority: report.priority, compact: true)),
                              DataCell(StatusBadge(
                                  status: report.status, compact: true)),
                              DataCell(SizedBox(
                                width: 170,
                                child: Text(
                                  report.assignedTo?.isNotEmpty == true
                                      ? report.assignedTo!
                                      : 'Unassigned',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(SizedBox(
                                width: 92,
                                child: Text(
                                  report.isOfflineQueued
                                      ? 'Queued'
                                      : AppHelpers.slaLabel(
                                          report.createdAt,
                                          report.priority,
                                          report.status,
                                        ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(SizedBox(
                                width: 116,
                                child: Text(
                                  AppHelpers.formatDate(report.createdAt),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'View report',
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () => widget.onView(report),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Report actions',
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          widget.onDelete?.call(report);
                                          return;
                                        }
                                        widget.onStatusChanged
                                            ?.call(report, value);
                                      },
                                      itemBuilder: (context) => [
                                        for (final status in ReportStatuses.all)
                                          PopupMenuItem(
                                            value: status,
                                            child: Text('Set $status'),
                                          ),
                                        if (widget.onDelete != null)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
