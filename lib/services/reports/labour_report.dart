import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/features/labour/data/models/labour_models.dart';

class LabourReport {
  static Future<void> generate({
    required String projectName,
    required WageSheet sheet,
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Labour / Wage Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        ReportService.buildTable(
          headers: const ['Metric', 'Value'],
          rows: [
            ['Sheet Number', sheet.sheetNumber],
            ['Period', '${sheet.periodStart} to ${sheet.periodEnd}'],
            ['Total Amount', ReportService.fmtNum(sheet.totalAmount)],
            ['Status', sheet.status],
            ['Entries', sheet.entries.length.toString()],
          ],
        ),
        pw.SizedBox(height: 12),
        if (sheet.entries.isEmpty)
          pw.Text('No wage entries found.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              'Labour Name',
              'Days Worked',
              'Daily Wage',
              'Total Wage',
              'Advance Deducted',
              'Net Payable',
            ],
            rows: sheet.entries
                .map((e) => [
                      e.labourName,
                      e.daysWorked.toString(),
                      ReportService.fmtNum(e.dailyWage),
                      ReportService.fmtNum(e.totalWage),
                      ReportService.fmtNum(e.advancesDeducted),
                      ReportService.fmtNum(e.netPayable),
                    ])
                .toList(),
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'labour_${sheet.sheetNumber}.pdf');
  }
}
