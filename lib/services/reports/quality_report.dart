import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/services/quality_check_service.dart';

class QualityReport {
  static Future<void> generate({
    required String projectName,
    required List<QualityCheck> qualityChecks,
  }) async {
    final doc = pw.Document();

    final open = qualityChecks.where((c) => c.status.toUpperCase() == 'OPEN').toList();
    final inProgress = qualityChecks.where((c) => c.status.toUpperCase() == 'IN_PROGRESS').toList();
    final closed = qualityChecks.where((c) => c.status.toUpperCase() == 'CLOSED').toList();
    final passed = qualityChecks.where((c) => c.result?.toUpperCase() == 'PASSED').length;
    final total = qualityChecks.length;
    final passRate = total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';

    pw.Widget section(String label, List<QualityCheck> checks) {
      if (checks.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ReportService.buildTable(
            headers: const ['Title', 'Status', 'Result', 'Date', 'Inspector', 'Remarks'],
            rows: checks
                .map((c) => [
                      c.title,
                      c.status,
                      c.result ?? '',
                      ReportService.fmtDate(c.checkDate),
                      c.inspectedByName ?? '',
                      c.remarks ?? '',
                    ])
                .toList(),
          ),
        ],
      );
    }

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Quality Check Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        ReportService.buildTable(
          headers: const ['Metric', 'Value'],
          rows: [
            ['Total Checks', total.toString()],
            ['Pass Rate', '$passRate%'],
            ['Open', open.length.toString()],
            ['In Progress', inProgress.length.toString()],
            ['Closed', closed.length.toString()],
          ],
        ),
        section('Open', open),
        section('In Progress', inProgress),
        section('Closed', closed),
      ],
    ));

    await ReportService.sharePdf(doc, 'quality_checks_$projectName.pdf');
  }
}
