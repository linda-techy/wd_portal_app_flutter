import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';

class DelayReport {
  static Future<void> generate({
    required String projectName,
    required List<DelayLog> delays,
  }) async {
    final doc = pw.Document();

    // Category breakdown
    final Map<String, int> byCategory = {};
    int totalDays = 0;
    for (final d in delays) {
      final cat = d.categoryLabel;
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
      totalDays += d.durationDays;
    }

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Delay Log Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        // Summary
        ReportService.buildTable(
          headers: const ['Metric', 'Value'],
          rows: [
            ['Total Delays', delays.length.toString()],
            ['Total Days Lost', totalDays.toString()],
            ...byCategory.entries
                .map((e) => ['Category: ${e.key}', '${e.value} events']),
          ],
        ),
        pw.SizedBox(height: 12),
        if (delays.isNotEmpty)
          ReportService.buildTable(
            headers: const [
              'Date',
              'Category',
              'Duration (days)',
              'Responsible Party',
              'Impact',
            ],
            rows: delays
                .map((d) => [
                      ReportService.fmtDate(d.fromDate),
                      d.categoryLabel,
                      d.durationDays.toString(),
                      d.responsibleParty ?? '',
                      d.impactDescription ?? '',
                    ])
                .toList(),
          )
        else
          pw.Text('No delay logs recorded.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
      ],
    ));

    await ReportService.sharePdf(doc, 'delays_$projectName.pdf');
  }
}
