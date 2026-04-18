import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/models/stage_payment_models.dart';

class PaymentReport {
  static Future<void> generate({
    required String projectName,
    required List<StageTimelineSummary> stages,
  }) async {
    final doc = pw.Document();

    final rows = stages
        .map((s) => [
              s.stageNumber.toString(),
              s.stageName,
              ReportService.fmtNum(s.stageAmountInclGst),
              ReportService.fmtNum(s.retentionHeld),
              ReportService.fmtNum(s.netPayableAmount),
              s.status,
              s.dueDate ?? '',
              s.certified ? 'Yes' : 'No',
            ])
        .toList();

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('Payment Schedule',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        if (rows.isEmpty)
          pw.Text('No payment stages found.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              '#',
              'Stage Name',
              'Amount (incl GST)',
              'Retention Held',
              'Net Payable',
              'Status',
              'Due Date',
              'Certified',
            ],
            rows: rows,
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'payment_schedule_$projectName.pdf');
  }
}
