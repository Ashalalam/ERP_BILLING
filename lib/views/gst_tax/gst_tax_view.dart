import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/utils/gstin_validator.dart';
import '../../core/utils/gstr_exporter.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/date_range_filter.dart';

class GstTaxView extends StatefulWidget {
  const GstTaxView({super.key});

  @override
  State<GstTaxView> createState() => _GstTaxViewState();
}

class _GstTaxViewState extends State<GstTaxView> with SingleTickerProviderStateMixin {
  final _gstinController = TextEditingController(text: '27AAAAA0000A1Z5');
  final _db = SupabaseService.instance;
  late TabController _tabController;
  String _validationResult = 'Press Validate to check GSTIN format';

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  void _validateGstin() {
    final isValid = GstinValidator.validate(_gstinController.text);
    setState(() {
      _validationResult = isValid
          ? 'VALID GSTIN Structure (15-Character Checksum Verified)'
          : 'INVALID GSTIN Format! Please enter a valid 15-character GSTIN.';
    });
  }

  Future<void> _exportGstr1Csv() async {
    final bytes = GstrExporter.buildGstr1Csv(
      _db.invoices, _db.invoiceItems, _db.parties, _db.products, _db.activeCompany!,
      from: _fromDate, to: _toDate,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'GSTR1.csv');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GSTR-1 CSV exported.'), backgroundColor: Colors.green));
    }
  }

  Future<void> _exportGstr1Pdf() async {
    await GstrExporter.shareGstr1Pdf(
      _db.invoices, _db.invoiceItems, _db.parties, _db.products, _db.activeCompany!,
      from: _fromDate, to: _toDate,
    );
  }

  Future<void> _exportGstr3bCsv() async {
    final bytes = GstrExporter.buildGstr3bCsv(_db.invoices, from: _fromDate, to: _toDate);
    await Printing.sharePdf(bytes: bytes, filename: 'GSTR3B.csv');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GSTR-3B CSV exported.'), backgroundColor: Colors.green));
    }
  }

  Future<void> _exportHsnCsv() async {
    final bytes = GstrExporter.buildHsnSummaryCsv(
      _db.invoices, _db.invoiceItems, _db.products, from: _fromDate, to: _toDate,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'HSN_Summary.csv');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HSN Summary CSV exported.'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTax = _db.invoices
        .where((i) {
          if (_fromDate != null && i.createdAt.isBefore(_fromDate!)) return false;
          if (_toDate != null && i.createdAt.isAfter(_toDate!)) return false;
          return true;
        })
        .fold(0.0, (sum, i) => sum + i.taxAmount);

    final gstr3b = GstrExporter.buildGstr3bSummary(_db.invoices, from: _fromDate, to: _toDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST & Tax Compliance Module'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'GSTIN Validator'),
            Tab(text: 'GSTR-1 (Outward)'),
            Tab(text: 'GSTR-3B (Summary)'),
            Tab(text: 'HSN Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range filter bar
          DateRangeFilterBar(
            fromDate: _fromDate,
            toDate: _toDate,
            onChanged: (from, to) => setState(() {
              _fromDate = from;
              _toDate = to;
            }),
          ),
          // Tax summary chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _taxChip('Output Tax Liability', '₹${totalTax.toStringAsFixed(2)}', Colors.red),
                const SizedBox(width: 12),
                _taxChip('ITC Available', '₹${(gstr3b['input_tax_credit'] as double).toStringAsFixed(2)}', Colors.green),
                const SizedBox(width: 12),
                _taxChip('Net GST Payable', '₹${(gstr3b['net_gst_payable'] as double).toStringAsFixed(2)}', Colors.blue),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGstinTab(),
                _buildGstr1Tab(),
                _buildGstr3bTab(gstr3b),
                _buildHsnTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxChip(String label, String value, Color color) => Chip(
        backgroundColor: color.withOpacity(0.1),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );

  Widget _buildGstinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GSTIN Structure Validator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gstinController,
                      decoration: const InputDecoration(labelText: 'Enter 15-Character GSTIN'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _validateGstin, child: const Text('Validate GSTIN')),
                ],
              ),
              const SizedBox(height: 8),
              Text(_validationResult, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGstr1Tab() {
    final rows = GstrExporter.buildGstr1Json(
      _db.invoices, _db.invoiceItems, _db.parties, _db.products, _db.activeCompany!,
      from: _fromDate, to: _toDate,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GSTR-1: ${rows.length} invoices', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  OutlinedButton.icon(onPressed: _exportGstr1Csv, icon: const Icon(Icons.table_chart), label: const Text('Export CSV')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: _exportGstr1Pdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('No sales invoices in selected period.'))
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: r['invoice_type'] == 'B2B' ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            child: Text(r['invoice_type'] == 'B2B' ? 'B2B' : 'B2C', style: const TextStyle(fontSize: 10)),
                          ),
                          title: Text('${r['invoice_number']} — ${r['customer_name']}'),
                          subtitle: Text('Date: ${r['invoice_date']} | GSTIN: ${r['customer_gstin'].isEmpty ? 'Unregistered' : r['customer_gstin']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Taxable: ₹${(r['taxable_value'] as double).toStringAsFixed(2)}'),
                              Text('Tax: ₹${(r['total_tax'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstr3bTab(Map<String, dynamic> summary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(onPressed: _exportGstr3bCsv, icon: const Icon(Icons.table_chart), label: const Text('Export GSTR-3B CSV')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('3.1 Outward Taxable Supplies (Section 3.1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  _summaryTile('Taxable Turnover', '₹${(summary['total_outward_taxable_value'] as double).toStringAsFixed(2)}', Colors.blue),
                  _summaryTile('Output GST Tax', '₹${(summary['total_outward_tax'] as double).toStringAsFixed(2)}', Colors.red),
                  const Divider(),
                  const Text('4. Input Tax Credit (ITC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  _summaryTile('ITC on Purchases', '₹${(summary['input_tax_credit'] as double).toStringAsFixed(2)}', Colors.green),
                  const Divider(),
                  _summaryTile('NET GST PAYABLE', '₹${(summary['net_gst_payable'] as double).toStringAsFixed(2)}', Colors.orange, bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color, {bool bold = false}) => ListTile(
        title: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        trailing: Text(value, style: TextStyle(fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
      );

  Widget _buildHsnTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(onPressed: _exportHsnCsv, icon: const Icon(Icons.table_chart), label: const Text('Export HSN CSV')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(builder: (context) {
              final List<Product> products = _db.products;
              final hsnMap = <String, Map<String, dynamic>>{};
              for (final inv in _db.invoices) {
                if (inv.invoiceType != 'sales' || inv.isCancelled) continue;
                if (_fromDate != null && inv.createdAt.isBefore(_fromDate!)) continue;
                if (_toDate != null && inv.createdAt.isAfter(_toDate!)) continue;
                for (final item in _db.invoiceItems.where((i) => i.invoiceId == inv.id)) {
                  final prod = products.cast<Product?>().firstWhere((p) => p!.id == item.productId, orElse: () => null);
                  if (prod == null) continue;
                  final hsn = prod.hsnCode;
                  hsnMap.putIfAbsent(hsn, () => {'hsn': hsn, 'desc': prod.category ?? '', 'qty': 0, 'taxable': 0.0, 'tax': 0.0});
                  hsnMap[hsn]!['qty'] += item.quantity;
                  hsnMap[hsn]!['taxable'] += item.unitPrice * item.quantity;
                  hsnMap[hsn]!['tax'] += item.taxAmount;
                }
              }
              final entries = hsnMap.values.toList();
              if (entries.isEmpty) return const Center(child: Text('No data for selected period.'));
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.tag, color: Colors.purple),
                      title: Text('HSN: ${e['hsn']}  ${e['desc']}'),
                      subtitle: Text('Total Quantity: ${e['qty']}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Taxable: ₹${(e['taxable'] as double).toStringAsFixed(2)}'),
                          Text('Tax: ₹${(e['tax'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
