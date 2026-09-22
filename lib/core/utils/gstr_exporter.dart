import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';

/// Generates real GSTR-1 and GSTR-3B JSON/CSV export data.
class GstrExporter {
  // ── GSTR-1: Outward supplies ─────────────────────────────────────────────

  static List<Map<String, dynamic>> buildGstr1Json(
    List<Invoice> invoices,
    List<InvoiceItem> allItems,
    List<Party> parties,
    List<Product> products,
    Company company, {
    DateTime? from,
    DateTime? to,
  }) {
    final filtered = invoices.where((inv) {
      if (inv.invoiceType != 'sales') return false;
      if (inv.isCancelled) return false;
      if (from != null && inv.createdAt.isBefore(from)) return false;
      if (to != null && inv.createdAt.isAfter(to)) return false;
      return true;
    }).toList();

    return filtered.map((inv) {
      final party = parties.cast<Party?>().firstWhere((p) => p!.id == inv.partyId, orElse: () => null);
      final items = allItems.where((i) => i.invoiceId == inv.id).toList();

      // Calculate CGST / SGST / IGST
      // Assume intra-state if party has no GSTIN or same state code
      final isInterState = party?.gstin != null &&
          party!.gstin!.length >= 2 &&
          party.gstin!.substring(0, 2) != (company.gstin?.substring(0, 2) ?? '27');

      final hsnSummary = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final prod = products.cast<Product?>().firstWhere((p) => p!.id == item.productId, orElse: () => null);
        if (prod == null) continue;
        final hsn = prod.hsnCode;
        hsnSummary.putIfAbsent(
          hsn,
          () => {'hsn': hsn, 'taxable': 0.0, 'igst': 0.0, 'cgst': 0.0, 'sgst': 0.0, 'gst_rate': prod.gstRate},
        );
        hsnSummary[hsn]!['taxable'] += item.unitPrice * item.quantity;
        if (isInterState) {
          hsnSummary[hsn]!['igst'] += item.taxAmount;
        } else {
          hsnSummary[hsn]!['cgst'] += item.taxAmount / 2;
          hsnSummary[hsn]!['sgst'] += item.taxAmount / 2;
        }
      }

      return {
        'invoice_number': inv.invoiceNumber,
        'invoice_date': DateFormat('dd-MM-yyyy').format(inv.createdAt),
        'invoice_type': party?.gstin != null ? 'B2B' : 'B2CS',
        'customer_name': party?.name ?? 'Unregistered',
        'customer_gstin': party?.gstin ?? '',
        'taxable_value': inv.subtotal,
        'igst': isInterState ? inv.taxAmount : 0.0,
        'cgst': isInterState ? 0.0 : inv.taxAmount / 2,
        'sgst': isInterState ? 0.0 : inv.taxAmount / 2,
        'total_tax': inv.taxAmount,
        'invoice_value': inv.totalAmount,
        'hsn_summary': hsnSummary.values.toList(),
      };
    }).toList();
  }

  static Uint8List buildGstr1Csv(
    List<Invoice> invoices,
    List<InvoiceItem> allItems,
    List<Party> parties,
    List<Product> products,
    Company company, {
    DateTime? from,
    DateTime? to,
  }) {
    final rows = buildGstr1Json(invoices, allItems, parties, products, company, from: from, to: to);
    final csvRows = <List<dynamic>>[
      ['Invoice No', 'Date', 'Type', 'Customer', 'GSTIN', 'Taxable Value', 'IGST', 'CGST', 'SGST', 'Total Tax', 'Invoice Value'],
      ...rows.map((r) => [
        r['invoice_number'],
        r['invoice_date'],
        r['invoice_type'],
        r['customer_name'],
        r['customer_gstin'],
        r['taxable_value'],
        r['igst'],
        r['cgst'],
        r['sgst'],
        r['total_tax'],
        r['invoice_value'],
      ]),
    ];
    final csvString = const ListToCsvConverter().convert(csvRows);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  // ── GSTR-3B: Summary tax return ──────────────────────────────────────────

  static Map<String, dynamic> buildGstr3bSummary(
    List<Invoice> invoices, {
    DateTime? from,
    DateTime? to,
  }) {
    final sales = invoices.where((i) {
      if (i.invoiceType != 'sales' || i.isCancelled) return false;
      if (from != null && i.createdAt.isBefore(from)) return false;
      if (to != null && i.createdAt.isAfter(to)) return false;
      return true;
    });

    final purchases = invoices.where((i) {
      if (i.invoiceType != 'purchase' || i.isCancelled) return false;
      if (from != null && i.createdAt.isBefore(from)) return false;
      if (to != null && i.createdAt.isAfter(to)) return false;
      return true;
    });

    final outputTax = sales.fold(0.0, (s, i) => s + i.taxAmount);
    final inputTaxCredit = purchases.fold(0.0, (s, i) => s + i.taxAmount);
    final netPayable = (outputTax - inputTaxCredit).clamp(0.0, double.infinity);

    return {
      'total_outward_taxable_value': sales.fold(0.0, (s, i) => s + i.subtotal),
      'total_outward_tax': outputTax,
      'total_inward_taxable_value': purchases.fold(0.0, (s, i) => s + i.subtotal),
      'input_tax_credit': inputTaxCredit,
      'net_gst_payable': netPayable,
      'period_from': from != null ? DateFormat('MM-yyyy').format(from) : 'All',
      'period_to': to != null ? DateFormat('MM-yyyy').format(to) : 'All',
    };
  }

  static Uint8List buildGstr3bCsv(
    List<Invoice> invoices, {
    DateTime? from,
    DateTime? to,
  }) {
    final summary = buildGstr3bSummary(invoices, from: from, to: to);
    final rows = <List<dynamic>>[
      ['GSTR-3B Summary', ''],
      ['Period From', summary['period_from']],
      ['Period To', summary['period_to']],
      ['', ''],
      ['3.1 Outward Taxable Supplies', ''],
      ['Total Taxable Value', summary['total_outward_taxable_value']],
      ['Total Output Tax', summary['total_outward_tax']],
      ['', ''],
      ['4. Input Tax Credit (ITC)', ''],
      ['Total ITC Available (Purchases)', summary['input_tax_credit']],
      ['', ''],
      ['Net GST Payable', summary['net_gst_payable']],
    ];
    final csvString = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  // ── HSN Summary CSV ──────────────────────────────────────────────────────

  static Uint8List buildHsnSummaryCsv(
    List<Invoice> invoices,
    List<InvoiceItem> allItems,
    List<Product> products, {
    DateTime? from,
    DateTime? to,
  }) {
    final hsnMap = <String, Map<String, dynamic>>{};
    for (final inv in invoices) {
      if (inv.invoiceType != 'sales' || inv.isCancelled) continue;
      if (from != null && inv.createdAt.isBefore(from)) continue;
      if (to != null && inv.createdAt.isAfter(to)) continue;
      for (final item in allItems.where((i) => i.invoiceId == inv.id)) {
        final prod = products.cast<Product?>().firstWhere((p) => p!.id == item.productId, orElse: () => null);
        if (prod == null) continue;
        final hsn = prod.hsnCode;
        hsnMap.putIfAbsent(hsn, () => {'hsn': hsn, 'desc': prod.category ?? '', 'qty': 0, 'taxable': 0.0, 'tax': 0.0});
        hsnMap[hsn]!['qty'] += item.quantity;
        hsnMap[hsn]!['taxable'] += item.unitPrice * item.quantity;
        hsnMap[hsn]!['tax'] += item.taxAmount;
      }
    }
    final rows = <List<dynamic>>[
      ['HSN Code', 'Description', 'Total Qty', 'Taxable Value', 'Total Tax'],
      ...hsnMap.values.map((r) => [r['hsn'], r['desc'], r['qty'], r['taxable'], r['tax']]),
    ];
    return Uint8List.fromList(utf8.encode(const ListToCsvConverter().convert(rows)));
  }

  // ── Share helpers ────────────────────────────────────────────────────────

  static Future<void> shareGstr1Pdf(
    List<Invoice> invoices,
    List<InvoiceItem> allItems,
    List<Party> parties,
    List<Product> products,
    Company company, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = buildGstr1Json(invoices, allItems, parties, products, company, from: from, to: to);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('GSTR-1 — Outward Supplies Return',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('${company.name} | GSTIN: ${company.gstin ?? 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: ['Invoice #', 'Date', 'Type', 'Customer', 'GSTIN', 'Taxable', 'CGST', 'SGST', 'IGST', 'Total']
                  .map((h) => _cell(h, bold: true))
                  .toList(),
            ),
            ...rows.map((r) => pw.TableRow(children: [
              _cell(r['invoice_number']),
              _cell(r['invoice_date']),
              _cell(r['invoice_type']),
              _cell(r['customer_name']),
              _cell(r['customer_gstin'] ?? ''),
              _cell('₹${(r['taxable_value'] as double).toStringAsFixed(2)}'),
              _cell('₹${(r['cgst'] as double).toStringAsFixed(2)}'),
              _cell('₹${(r['sgst'] as double).toStringAsFixed(2)}'),
              _cell('₹${(r['igst'] as double).toStringAsFixed(2)}'),
              _cell('₹${(r['invoice_value'] as double).toStringAsFixed(2)}'),
            ])),
          ],
        ),
      ],
    ));
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'GSTR1_${company.name}.pdf');
  }

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
}
