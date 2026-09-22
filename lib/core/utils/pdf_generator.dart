import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';

/// PDF & Print utilities for invoices, GSTR exports, and regulatory registers.
class PdfGenerator {
  // ── Invoice PDF ──────────────────────────────────────────────────────────

  static Future<Uint8List> buildInvoicePdf(
    Invoice invoice,
    Company company,
    Party? party,
    List<InvoiceItem> items,
  ) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd-MM-yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company.name.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(company.address ?? '', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('GSTIN: ${company.gstin ?? 'N/A'} | Ph: ${company.phone ?? ''}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Invoice #: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Date: ${fmt.format(invoice.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(),
            // Customer
            if (party != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(party.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    if (party.gstin != null && party.gstin!.isNotEmpty)
                      pw.Text('GSTIN: ${party.gstin}', style: const pw.TextStyle(fontSize: 10)),
                    if (party.phone != null) pw.Text('Ph: ${party.phone}', style: const pw.TextStyle(fontSize: 10)),
                    if (party.address != null) pw.Text(party.address!, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            pw.SizedBox(height: 12),
            // Items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Item Description', bold: true),
                    _cell('Qty', bold: true),
                    _cell('Rate ₹', bold: true),
                    _cell('Disc%', bold: true),
                    _cell('Tax ₹', bold: true),
                    _cell('Total ₹', bold: true),
                  ],
                ),
                // Item rows
                ...items.map((item) => pw.TableRow(children: [
                  _cell(item.productName),
                  _cell('${item.quantity}'),
                  _cell(item.unitPrice.toStringAsFixed(2)),
                  _cell('${item.discountPercent.toStringAsFixed(1)}%'),
                  _cell(item.taxAmount.toStringAsFixed(2)),
                  _cell(item.totalPrice.toStringAsFixed(2)),
                ])),
              ],
            ),
            pw.SizedBox(height: 8),
            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _summaryRow('Subtotal:', '₹${invoice.subtotal.toStringAsFixed(2)}'),
                    _summaryRow('GST Tax:', '₹${invoice.taxAmount.toStringAsFixed(2)}'),
                    pw.Divider(),
                    _summaryRow('TOTAL PAYABLE:', '₹${invoice.totalAmount.toStringAsFixed(2)}', bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            // IRN
            if (invoice.eInvoiceIrn != null)
              pw.Text('IRN: ${invoice.eInvoiceIrn}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
            pw.Center(child: pw.Text('Thank you for your business! Get Well Soon.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10))),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
      );

  static pw.Widget _summaryRow(String label, String value, {bool bold = false}) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      );

  // ── Print invoice ────────────────────────────────────────────────────────

  static Future<void> printInvoice(
    BuildContext context,
    Invoice invoice,
    Company company,
    Party? party,
    List<InvoiceItem> items,
  ) async {
    final bytes = await buildInvoicePdf(invoice, company, party, items);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  // ── Share / download PDF ─────────────────────────────────────────────────

  static Future<void> sharePdf(
    Invoice invoice,
    Company company,
    Party? party,
    List<InvoiceItem> items,
  ) async {
    final bytes = await buildInvoicePdf(invoice, company, party, items);
    await Printing.sharePdf(bytes: bytes, filename: 'invoice_${invoice.invoiceNumber}.pdf');
  }

  // ── Expiry report PDF ────────────────────────────────────────────────────

  static Future<Uint8List> buildExpiryReportPdf(
    List<Batch> batches,
    List<Product> products,
    Company company,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fmt = DateFormat('dd-MM-yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Expiry Report — ${company.name}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: ${fmt.format(now)}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('Product', bold: true),
                  _cell('Batch #', bold: true),
                  _cell('Mfg Date', bold: true),
                  _cell('Expiry Date', bold: true),
                  _cell('Days Left', bold: true),
                  _cell('Stock', bold: true),
                ],
              ),
              ...batches.map((b) {
                final prod = products.firstWhere((p) => p.id == b.productId, orElse: () => products.first);
                final daysLeft = b.expiryDate.difference(now).inDays;
                final color = daysLeft <= 0 ? PdfColors.red100 : (daysLeft <= 30 ? PdfColors.orange100 : PdfColors.white);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: color),
                  children: [
                    _cell(prod.name),
                    _cell(b.batchNumber),
                    _cell(fmt.format(b.mfgDate)),
                    _cell(fmt.format(b.expiryDate)),
                    _cell('$daysLeft days'),
                    _cell('${b.currentStock}'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // ── Restricted drug register PDF ─────────────────────────────────────────

  static Future<Uint8List> buildRestrictedDrugRegisterPdf(
    List<RestrictedDrugLog> logs,
    Company company,
  ) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd-MM-yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Schedule H / H1 / Narcotics Drug Register',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('${company.name} | GSTIN: ${company.gstin ?? 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Schedule', 'Patient', 'Doctor', 'Qty', 'Invoice', 'Date']
                    .map((h) => _cell(h, bold: true))
                    .toList(),
              ),
              ...logs.map((log) => pw.TableRow(children: [
                _cell(log.scheduleType),
                _cell(log.patientName),
                _cell(log.doctorName),
                _cell('${log.quantity}'),
                _cell(log.invoiceId.substring(0, 8)),
                _cell(fmt.format(log.createdAt)),
              ])),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // ── Legacy plain-text fallback (kept for compatibility) ──────────────────

  static String generatePrintableInvoiceText(
    Invoice invoice,
    Company company,
    Party? party,
    List<InvoiceItem> items,
  ) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd-MM-yyyy HH:mm').format(invoice.createdAt);
    buffer.writeln('==================================================');
    buffer.writeln('            ${company.name.toUpperCase()}');
    buffer.writeln('   ${company.address ?? ''}');
    buffer.writeln('   GSTIN: ${company.gstin ?? 'N/A'} | Ph: ${company.phone ?? ''}');
    buffer.writeln('==================================================');
    buffer.writeln('INVOICE NO: ${invoice.invoiceNumber}');
    buffer.writeln('DATE      : $dateStr');
    buffer.writeln('CUSTOMER  : ${party?.name ?? 'Cash Customer'}');
    if (party?.gstin != null && party!.gstin!.isNotEmpty) {
      buffer.writeln('CUST GSTIN: ${party.gstin}');
    }
    buffer.writeln('PAYMENT   : ${invoice.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('ITEM                        QTY   RATE     TOTAL');
    buffer.writeln('--------------------------------------------------');
    for (final item in items) {
      final name = item.productName.length > 25
          ? item.productName.substring(0, 25)
          : item.productName.padRight(25);
      final qty = item.quantity.toString().padLeft(4);
      final rate = item.unitPrice.toStringAsFixed(2).padLeft(7);
      final total = item.totalPrice.toStringAsFixed(2).padLeft(9);
      buffer.writeln('$name $qty $rate $total');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('SUBTOTAL:                      ₹${invoice.subtotal.toStringAsFixed(2)}');
    buffer.writeln('TAX:                           ₹${invoice.taxAmount.toStringAsFixed(2)}');
    buffer.writeln('TOTAL AMOUNT:                  ₹${invoice.totalAmount.toStringAsFixed(2)}');
    if (invoice.eInvoiceIrn != null && invoice.eInvoiceIrn!.isNotEmpty) {
      buffer.writeln('IRN: ${invoice.eInvoiceIrn}');
    }
    buffer.writeln('==================================================');
    buffer.writeln('       Thank you! Get Well Soon!');
    buffer.writeln('==================================================');
    return buffer.toString();
  }
}
