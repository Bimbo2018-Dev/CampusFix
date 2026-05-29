import 'package:flutter/material.dart';

import 'app_constants.dart';

class AppColors {
  static const primary = Color(0xFF000666);
  static const primaryContainer = Color(0xFF1A237E);
  static const secondary = Color(0xFF005FAF);
  static const accent = Color(0xFFD32F2F);
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF3F4F5);
  static const surfaceHigh = Color(0xFFE7E8E9);
  static const outline = Color(0xFFC6C5D4);
  static const text = Color(0xFF191C1D);
  static const mutedText = Color(0xFF454652);

  static const pending = Color(0xFFF8BD2A);
  static const reviewed = Color(0xFF4C56AF);
  static const inProgress = Color(0xFF1976D2);
  static const resolved = Color(0xFF388E3C);
  static const rejected = Color(0xFFBA1A1A);
  static const urgent = Color(0xFFD32F2F);
  static const high = Color(0xFFF57C00);
  static const medium = Color(0xFF1565C0);
  static const low = Color(0xFF607D6D);

  static Color statusColor(String status) {
    switch (status) {
      case ReportStatuses.reviewed:
        return reviewed;
      case ReportStatuses.inProgress:
        return inProgress;
      case ReportStatuses.resolved:
        return resolved;
      case ReportStatuses.rejected:
        return rejected;
      case ReportStatuses.pending:
      default:
        return pending;
    }
  }

  static Color statusBackground(String status) {
    switch (status) {
      case ReportStatuses.reviewed:
        return const Color(0xFFE0E0FF);
      case ReportStatuses.inProgress:
        return const Color(0xFFD4E3FF);
      case ReportStatuses.resolved:
        return const Color(0xFFDFF4E5);
      case ReportStatuses.rejected:
        return const Color(0xFFFFDAD6);
      case ReportStatuses.pending:
      default:
        return const Color(0xFFFFF4D6);
    }
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case ReportPriorities.urgent:
        return urgent;
      case ReportPriorities.high:
        return high;
      case ReportPriorities.medium:
        return medium;
      case ReportPriorities.low:
      default:
        return low;
    }
  }

  static Color priorityBackground(String priority) {
    switch (priority) {
      case ReportPriorities.urgent:
        return const Color(0xFFFFDAD6);
      case ReportPriorities.high:
        return const Color(0xFFFFE4C2);
      case ReportPriorities.medium:
        return const Color(0xFFD4E3FF);
      case ReportPriorities.low:
      default:
        return const Color(0xFFE7F2EA);
    }
  }
}
