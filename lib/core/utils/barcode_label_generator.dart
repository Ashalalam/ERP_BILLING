import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';

/// Utility to generate printable barcode sticker sheets for medicine inventory batches.
class BarcodeLabelGenerator {
  /// Generates a PDF grid of printable barcode labels for a medicine & batch.
  static Future<void> printBarcodeLabels({
    required Product product,
    required Batch batch,
    int labelCount = 24,
  }) async {
    final pdf = pw.Document();
    final barcodeData = product.barcode ?? batch.batchNumber;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(labelCount, (index) {
              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      product.name,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: barcodeData,
                      width: 100,
                      height: 25,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('B.No: ${batch.batchNumber}', style: const pw.TextStyle(fontSize: 6)),
                        pw.Text('MRP: ₹${batch.retailPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Barcode_Labels_${product.name}_${batch.batchNumber}.pdf',
    );
  }
}
