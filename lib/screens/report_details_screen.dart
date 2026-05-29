import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import '../utils/report_image_helper.dart';
import '../widgets/app_shell.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_badge.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final report = state.findReport(reportId);

    if (report == null) {
      return AppShell(
        selectedIndex: 1,
        title: 'Report Details',
        showBackButton: true,
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Report not found',
          message: 'This report may have been deleted.',
          action: PrimaryButton(
            label: 'Back to Reports',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(CampusFixRoutes.reports),
          ),
        ),
      );
    }

    return AppShell(
      selectedIndex: 1,
      title: 'Report Details',
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                final main = Column(
                  children: [
                    _SummaryCard(report: report),
                    const SizedBox(height: 16),
                    _EvidenceCard(report: report),
                    const SizedBox(height: 16),
                    _TimelineCard(report: report),
                  ],
                );
                final side = Column(
                  children: [
                    _ActionsCard(report: report, state: state),
                    const SizedBox(height: 16),
                    _NotesCard(report: report),
                  ],
                );

                if (!wide) {
                  return Column(
                      children: [main, const SizedBox(height: 16), side]);
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: side),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final accent = report.priority == ReportPriorities.urgent
        ? AppColors.urgent
        : AppColors.statusColor(report.status);

    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${report.id}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PriorityBadge(priority: report.priority),
                        StatusBadge(status: report.status),
                        CategoryChip(category: report.category),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Reporter',
                            value:
                                '${report.reporterName}\n${report.reporterRole}',
                          ),
                          const Divider(height: 22),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: report.location,
                          ),
                          const Divider(height: 22),
                          _InfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Created',
                            value: AppHelpers.formatDateTime(report.createdAt),
                          ),
                          const Divider(height: 22),
                          _InfoRow(
                            icon: Icons.update_outlined,
                            label: 'Updated',
                            value: AppHelpers.formatDateTime(report.updatedAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (report.assignedTo != null) ...[
                      const SizedBox(height: 18),
                      Chip(
                        avatar:
                            const Icon(Icons.engineering_outlined, size: 18),
                        label: Text('Assigned to ${report.assignedTo}'),
                      ),
                    ],
                    if (report.isValidatedByTeacher) ...[
                      const SizedBox(height: 8),
                      const Chip(
                        avatar: Icon(Icons.verified_outlined, size: 18),
                        label: Text('Validated by teacher'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final imageBytes = ReportImageHelper.bytesFromDataUrl(report.imagePath);
    final imageUrl = ReportImageHelper.networkImageUrl(report.imagePath);
    final resolvedImageBytes =
        ReportImageHelper.bytesFromDataUrl(report.resolvedImagePath);
    final resolvedImageUrl =
        ReportImageHelper.networkImageUrl(report.resolvedImagePath);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Before and After Photos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final before = _EvidencePhotoPanel(
                  label: 'Problem Photo',
                  emptyText: 'No problem photo attached.',
                  category: report.category,
                  imageBytes: imageBytes,
                  imageUrl: imageUrl,
                  onView: _photoAction(
                    context: context,
                    imageBytes: imageBytes,
                    imageUrl: imageUrl,
                  ),
                );
                final after = _EvidencePhotoPanel(
                  label: 'Resolution Photo',
                  emptyText: 'No resolution photo uploaded yet.',
                  category: report.category,
                  imageBytes: resolvedImageBytes,
                  imageUrl: resolvedImageUrl,
                  onView: _photoAction(
                    context: context,
                    imageBytes: resolvedImageBytes,
                    imageUrl: resolvedImageUrl,
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      before,
                      const SizedBox(height: 12),
                      after,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: before),
                    const SizedBox(width: 12),
                    Expanded(child: after),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _photoAction({
    required BuildContext context,
    Uint8List? imageBytes,
    String? imageUrl,
  }) {
    if (imageBytes != null) {
      return () => _showFullSizeImage(context, imageBytes);
    }
    if (imageUrl != null) {
      return () => _showFullSizeNetworkImage(context, imageUrl);
    }
    return null;
  }

  void _showFullSizeImage(BuildContext context, Uint8List imageBytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullSizeNetworkImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Could not load that photo.'),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidencePhotoPanel extends StatelessWidget {
  const _EvidencePhotoPanel({
    required this.label,
    required this.emptyText,
    required this.category,
    required this.imageBytes,
    required this.imageUrl,
    required this.onView,
  });

  final String label;
  final String emptyText;
  final String category;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final url = imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (onView != null)
              TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
          ],
        ),
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4E3FF), Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: switch ((bytes, url)) {
            (final Uint8List imageBytes, _) => Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            (_, final String imageUrl) => Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  AppHelpers.categoryIcon(category),
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            _ => Icon(
                AppHelpers.categoryIcon(category),
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
          },
        ),
        if (bytes == null && url == null) ...[
          const SizedBox(height: 8),
          Text(emptyText, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Submitted', true),
      ('Reviewed', report.status != ReportStatuses.pending),
      (
        'Assigned',
        report.assignedTo != null && report.assignedTo!.isNotEmpty,
      ),
      (
        'In Progress',
        report.status == ReportStatuses.inProgress ||
            report.status == ReportStatuses.resolved,
      ),
      ('Resolved', report.status == ReportStatuses.resolved),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Timeline',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                AppHelpers.isReportOverdue(
                  createdAt: report.createdAt,
                  priority: report.priority,
                  status: report.status,
                )
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
                size: 18,
              ),
              label: Text(
                'SLA: ${AppHelpers.slaLabel(report.createdAt, report.priority, report.status)}',
              ),
            ),
            const SizedBox(height: 18),
            for (final step in steps)
              _TimelineStep(
                label: step.$1,
                active: step.$2,
                report: report,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.active,
    required this.report,
  });

  final String label;
  final bool active;
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: active ? AppColors.primary : AppColors.surfaceHigh,
            foregroundColor: active ? Colors.white : AppColors.mutedText,
            child: Icon(active ? Icons.check : Icons.flag_outlined, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.text : AppColors.mutedText,
                  ),
                ),
                Text(
                  active
                      ? AppHelpers.formatDateTime(report.updatedAt)
                      : 'Pending',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatefulWidget {
  const _ActionsCard({required this.report, required this.state});

  final ReportModel report;
  final AppState state;

  @override
  State<_ActionsCard> createState() => _ActionsCardState();
}

class _ActionsCardState extends State<_ActionsCard> {
  bool _isUploadingResolution = false;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final state = widget.state;
    final user = state.currentUser;
    final isOwner = user?.id == report.reporterId;
    final canAddNote = user?.role == UserRoles.admin ||
        user?.role == UserRoles.teacher ||
        isOwner;
    final assignedValue = report.assignedTo?.isNotEmpty == true
        ? report.assignedTo!
        : 'Unassigned';
    final assignmentItems = [
      'Unassigned',
      if (assignedValue != 'Unassigned' &&
          !CampusTeams.all.contains(assignedValue))
        assignedValue,
      ...CampusTeams.all,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (user?.role == UserRoles.admin)
              DropdownButtonFormField<String>(
                initialValue: report.status,
                decoration: const InputDecoration(labelText: 'Update Status'),
                items: ReportStatuses.all
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (status) async {
                  if (status != null) {
                    try {
                      await state.updateReportStatus(report.id, status);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.apiError ?? 'Could not update status.',
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
                      SnackBar(
                        content: Text('Status updated to $status.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            if (user?.role == UserRoles.admin) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: assignedValue,
                decoration: const InputDecoration(labelText: 'Assign Team'),
                items: [
                  for (final team in assignmentItems)
                    DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    ),
                ],
                onChanged: (team) async {
                  try {
                    await state.updateReportAssignment(
                      report.id,
                      team == 'Unassigned' ? null : team,
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.apiError ?? 'Could not assign report.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assignment updated.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _isUploadingResolution
                    ? 'Opening Photo...'
                    : 'Upload Resolution Photo',
                icon: Icons.add_photo_alternate_outlined,
                isOutlined: true,
                onPressed: _isUploadingResolution
                    ? null
                    : () => _uploadResolutionPhoto(context, state, report),
              ),
            ],
            if (user?.role == UserRoles.admin) const SizedBox(height: 12),
            if (canAddNote)
              PrimaryButton(
                label: 'Add Note',
                icon: Icons.note_add_outlined,
                isOutlined: true,
                onPressed: () => _showAddNoteDialog(context, state, report.id),
              ),
            if (user?.role == UserRoles.teacher &&
                report.reporterRole == UserRoles.student &&
                !report.isValidatedByTeacher) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Validate',
                icon: Icons.verified_outlined,
                isOutlined: true,
                onPressed: () async {
                  try {
                    await state.validateReportByTeacher(report.id);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.apiError ?? 'Could not validate report.',
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
              ),
            ],
            if (user?.role == UserRoles.admin) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Delete Report',
                icon: Icons.delete_outline,
                isDestructive: true,
                onPressed: () => _confirmDelete(context, state, report),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadResolutionPhoto(
    BuildContext context,
    AppState state,
    ReportModel report,
  ) async {
    setState(() => _isUploadingResolution = true);
    try {
      final image = await ReportImageHelper.pickAndPrepareImage(
        source: ImageSource.gallery,
      );
      if (image == null) {
        return;
      }
      await state.updateResolvedImage(report.id, image.dataUrl);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolution photo uploaded.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ReportImageTooLargeException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That photo is too large. Choose another image.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      debugPrint('Resolution image upload failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.apiError ?? 'Could not upload that photo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingResolution = false);
      }
    }
  }

  Future<void> _showAddNoteDialog(
    BuildContext context,
    AppState state,
    String reportId,
  ) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Write a follow-up note...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (message != null && message.trim().isNotEmpty) {
      try {
        await state.addReportNote(reportId, message);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.apiError ?? 'Could not add note.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        Navigator.of(context).pushReplacementNamed(CampusFixRoutes.reports);
      }
    }
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (report.notes.isEmpty)
              Text(
                'No notes yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final note in report.notes) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    foregroundColor: AppColors.primary,
                    child: Text(AppHelpers.initials(note.authorName)),
                  ),
                  title: Text(note.message),
                  subtitle: Text(
                    '${note.authorName} - ${note.authorRole}\n${AppHelpers.formatDateTime(note.createdAt)}',
                  ),
                ),
                const Divider(),
              ],
          ],
        ),
      ),
    );
  }
}
