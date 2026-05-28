import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';

class FinancialReport {
  static Future<void> generate({
    required String projectName,
    Map<String, dynamic>? summaryData,
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Financial Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        pw.Text(
          'See detailed financial view in app',
          style: const pw.TextStyle(
              fontSize: 11, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 12),
        if (summaryData != null && summaryData.isNotEmpty)
          ReportService.buildTable(
            headers: const ['Metric', 'Value'],
            rows: summaryData.entries
                .map((e) => [e.key.toString(), e.value.toString()])
                .toList(),
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'financial_$projectName.pdf');
  }
}
