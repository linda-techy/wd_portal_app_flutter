import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared helpers for PDF report generation across all portal modules.
class ReportService {
  ReportService._();

  static pw.Widget buildHeader(String title,
      {String? subtitle, String? projectName}) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Walldot Builders',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#D84940'))),
          pw.SizedBox(height: 4),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (projectName != null)
            pw.Text('Project: $projectName',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey700)),
          if (subtitle != null)
            pw.Text(subtitle,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey500)),
          pw.SizedBox(height: 4),
          pw.Text(
              'Generated: ${DateTime.now().toString().split('.').first}',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey500)),
          pw.Divider(),
          pw.SizedBox(height: 8),
        ]);
  }

  static pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500)));
  }

  static Future<void> sharePdf(pw.Document doc, String filename) async {
    await Printing.sharePdf(
        bytes: await doc.save(), filename: filename);
  }

  static pw.Table buildTable(
      {required List<String> headers,
      required List<List<String>> rows}) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle:
          pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.grey200),
      border: pw.TableBorder.all(
          color: PdfColors.grey400, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 4, vertical: 3),
    );
  }

  /// Formats a nullable DateTime to a readable date string.
  static String fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Formats a number to 2 decimal places.
  static String fmtNum(num? n) {
    if (n == null) return '';
    return n.toStringAsFixed(2);
  }
}
