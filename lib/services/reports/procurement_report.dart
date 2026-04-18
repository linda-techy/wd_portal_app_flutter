import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/features/procurement/data/models/material_indent.dart';

class ProcurementReport {
  static Future<void> generate({
    required String projectName,
    required List<MaterialIndent> indents,
  }) async {
    final doc = pw.Document();

    final Map<String, int> byStatus = {};
    for (final i in indents) {
      byStatus[i.status] = (byStatus[i.status] ?? 0) + 1;
    }

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Procurement Summary',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        ReportService.buildTable(
          headers: const ['Metric', 'Value'],
          rows: [
            ['Total Indents', indents.length.toString()],
            ...byStatus.entries
                .map((e) => ['Status: ${e.key}', '${e.value} indents']),
          ],
        ),
        pw.SizedBox(height: 12),
        if (indents.isEmpty)
          pw.Text('No procurement indents found.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              'Indent #',
              'Request Date',
              'Required Date',
              'Priority',
              'Status',
              'Items',
            ],
            rows: indents
                .map((i) => [
                      i.indentNumber ?? '',
                      i.requestDate,
                      i.requiredDate,
                      i.priority,
                      i.status,
                      i.items.length.toString(),
                    ])
                .toList(),
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'procurement_$projectName.pdf');
  }
}
