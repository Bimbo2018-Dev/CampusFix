import 'package:flutter/material.dart';

import 'app_constants.dart';

class AppHelpers {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDate(DateTime value) {
    return '${_months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String formatDateTime(DateTime value) {
    final hour = value.hour > 12
        ? value.hour - 12
        : value.hour == 0
            ? 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${formatDate(value)}, $hour:$minute $suffix';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case ReportCategories.facility:
        return Icons.business_outlined;
      case ReportCategories.itConcern:
        return Icons.wifi_tethering_error_rounded;
      case ReportCategories.classroom:
        return Icons.meeting_room_outlined;
      case ReportCategories.comfortRoom:
        return Icons.water_drop_outlined;
      case ReportCategories.lostAndFound:
        return Icons.badge_outlined;
      case ReportCategories.clinic:
        return Icons.medical_services_outlined;
      case ReportCategories.maintenance:
        return Icons.construction_outlined;
      case ReportCategories.other:
      default:
        return Icons.help_outline;
    }
  }

  static IconData roleIcon(String role) {
    switch (role) {
      case UserRoles.teacher:
        return Icons.person_pin_outlined;
      case UserRoles.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRoles.student:
      default:
        return Icons.school_outlined;
    }
  }

  static bool containsQuery(String value, String query) {
    return value.toLowerCase().contains(query.trim().toLowerCase());
  }

  static Duration slaForPriority(String priority) {
    switch (priority) {
      case ReportPriorities.urgent:
        return const Duration(hours: 8);
      case ReportPriorities.high:
        return const Duration(hours: 24);
      case ReportPriorities.medium:
        return const Duration(days: 3);
      case ReportPriorities.low:
      default:
        return const Duration(days: 5);
    }
  }

  static DateTime slaDeadline(DateTime createdAt, String priority) {
    return createdAt.add(slaForPriority(priority));
  }

  static bool isReportOverdue({
    required DateTime createdAt,
    required String priority,
    required String status,
  }) {
    if (status == ReportStatuses.resolved ||
        status == ReportStatuses.rejected) {
      return false;
    }
    return DateTime.now().isAfter(slaDeadline(createdAt, priority));
  }

  static String slaLabel(DateTime createdAt, String priority, String status) {
    final deadline = slaDeadline(createdAt, priority);
    if (status == ReportStatuses.resolved) {
      return 'Resolved';
    }
    if (status == ReportStatuses.rejected) {
      return 'Closed';
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      final overdue = remaining.abs();
      if (overdue.inDays > 0) {
        return 'Overdue ${overdue.inDays}d';
      }
      return 'Overdue ${overdue.inHours.clamp(1, 999)}h';
    }

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d left';
    }
    return '${remaining.inHours.clamp(1, 999)}h left';
  }
}
