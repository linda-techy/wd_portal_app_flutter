import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin/services/report_service.dart';
import 'package:admin/services/boq_service.dart';

class BoqReport {
  static Future<void> generate({
    required String projectName,
    required List<BoqItem> items,
  }) async {
    final doc = pw.Document();

    final rows = items
        .map((i) => [
              i.itemCode ?? '',
              i.description,
              i.workTypeName ?? '',
              i.unit,
              ReportService.fmtNum(i.quantity),
              ReportService.fmtNum(i.unitRate),
              ReportService.fmtNum(i.totalAmount),
              ReportService.fmtNum(i.executedQuantity),
              ReportService.fmtNum(i.billedQuantity),
              i.status,
            ])
        .toList();

    doc.addPage(pw.MultiPage(
      header: (ctx) => ReportService.buildHeader('BOQ Report',
          projectName: projectName),
      footer: ReportService.buildFooter,
      build: (ctx) => [
        if (rows.isEmpty)
          pw.Text('No BOQ items found.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600))
        else
          ReportService.buildTable(
            headers: const [
              'Item Code',
              'Description',
              'Work Type',
              'Unit',
              'Qty',
              'Rate',
              'Amount',
              'Exec Qty',
              'Billed Qty',
              'Status'
            ],
            rows: rows,
          ),
      ],
    ));

    await ReportService.sharePdf(doc, 'boq_$projectName.pdf');
  }
}
