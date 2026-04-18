import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/services/observation_service.dart';

class ObservationReport {
  static Future<void> generate({
    required String projectName,
    required List<ObservationItem> active,
    required List<ObservationItem> resolved,
  }) async {
    final doc = pw.Document();
    final all = [...active, ...resolved];

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Snag / Observation Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        ReportService.buildTable(
          headers: const ['Metric', 'Value'],
          rows: [
            ['Total Observations', all.length.toString()],
            ['Active', active.length.toString()],
            ['Resolved', resolved.length.toString()],
          ],
        ),
        pw.SizedBox(height: 12),
        if (all.isEmpty)
          pw.Text('No observations recorded.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              'Title',
              'Priority',
              'Status',
              'Reported Date',
              'Resolved Date',
              'Description',
            ],
            rows: all
                .map((o) => [
                      o.title,
                      o.priority ?? '',
                      o.status,
                      ReportService.fmtDate(o.createdAt),
                      ReportService.fmtDate(o.resolvedDate),
                      o.description,
                    ])
                .toList(),
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'observations_$projectName.pdf');
  }
}
