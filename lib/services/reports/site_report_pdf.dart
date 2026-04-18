import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/models/site_report_models.dart';

class SiteReportPdf {
  static Future<void> generate({
    required String projectName,
    required List<SiteReport> reports,
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Site Reports',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        if (reports.isEmpty)
          pw.Text('No site reports found.',
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              'Date',
              'Type',
              'Title',
              'Photos',
              'Author',
            ],
            rows: reports
                .map((r) => [
                      ReportService.fmtDate(r.reportDate),
                      r.reportType.label,
                      r.title,
                      r.photos.length.toString(),
                      r.submittedByName ?? '',
                    ])
                .toList(),
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'site_reports_$projectName.pdf');
  }
}
