import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_model.dart';
import 'app_helpers.dart';
import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart'
    as csv_platform;

class ReportExporter {
  static Future<bool> exportCsv(List<ReportModel> reports) async {
    final csv = _csvForReports(reports);
    final downloaded = await csv_platform.downloadCsv(
      _fileName('campusfix_reports', 'csv'),
      csv,
    );
    if (!downloaded) {
      await Clipboard.setData(ClipboardData(text: csv));
    }
    return downloaded;
  }

  static Future<void> exportPdf(List<ReportModel> reports) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('CampusFix Reports Summary'),
          ),
          pw.Text('Generated: ${AppHelpers.formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const [
              'ID',
              'Title',
              'Reporter',
              'Category',
              'Priority',
              'Status',
              'Assigned',
              'SLA',
            ],
            data: [
              for (final report in reports)
                [
                  report.id,
                  report.title,
                  report.reporterName,
                  report.category,
                  report.priority,
                  report.status,
                  report.assignedTo?.isNotEmpty == true
                      ? report.assignedTo!
                      : 'Unassigned',
                  AppHelpers.slaLabel(
                    report.createdAt,
                    report.priority,
                    report.status,
                  ),
                ],
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: _fileName('campusfix_reports', 'pdf'),
    );
  }

  static String _csvForReports(List<ReportModel> reports) {
    final rows = [
      [
        'ID',
        'Title',
        'Description',
        'Reporter',
        'Role',
        'Category',
        'Location',
        'Priority',
        'Status',
        'Assigned To',
        'SLA',
        'Created',
        'Updated',
      ],
      for (final report in reports)
        [
          report.id,
          report.title,
          report.description,
          report.reporterName,
          report.reporterRole,
          report.category,
          report.location,
          report.priority,
          report.status,
          report.assignedTo ?? '',
          AppHelpers.slaLabel(report.createdAt, report.priority, report.status),
          AppHelpers.formatDateTime(report.createdAt),
          AppHelpers.formatDateTime(report.updatedAt),
        ],
    ];

    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _fileName(String prefix, String extension) {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .split('T')
        .join('_');
    return '${prefix}_$stamp.$extension';
  }
}
