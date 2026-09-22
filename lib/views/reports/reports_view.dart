import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/gstr_exporter.dart';
import '../../widgets/date_range_filter.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView>
    with SingleTickerProviderStateMixin {
  final _db = SupabaseService.instance;
  late TabController _tabController;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  List<Invoice> get _filteredInvoices => _db.invoices.where((inv) {
        if (_fromDate != null && inv.createdAt.isBefore(_fromDate!))
          return false;
        if (_toDate != null && inv.createdAt.isAfter(_toDate!)) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sales Reports'),
            Tab(text: 'Purchase Reports'),
            Tab(text: 'Inventory Reports'),
            Tab(text: 'Restricted Drug Reports'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          DateRangeFilterBar(
            fromDate: _fromDate,
            toDate: _toDate,
            onChanged: (from, to) =>
                setState(() {
                  _fromDate = from;
                  _toDate = to;
                }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildPurchaseTab(),
                _buildInventoryTab(),
                _buildRestrictedDrugTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sales reports ────────────────────────────────────────────────────────

  Widget _buildSalesTab() {
    final sales = _filteredInvoices
        .where((i) => i.invoiceType == 'sales' && !i.isCancelled)
        .toList();
    final totalRevenue =
        sales.fold(0.0, (s, i) => s + i.totalAmount);
    final totalTax = sales.fold(0.0, (s, i) => s + i.taxAmount);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _summaryCard('Total Sales', '₹${totalRevenue.toStringAsFixed(2)}', Colors.green, Icons.monetization_on),
              const SizedBox(width: 12),
              _summaryCard('Total Tax Collected', '₹${totalTax.toStringAsFixed(2)}', Colors.blue, Icons.receipt_long),
              const SizedBox(width: 12),
              _summaryCard('Invoice Count', '${sales.length}', Colors.teal, Icons.receipt),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes = GstrExporter.buildGstr1Csv(
                      _db.invoices, _db.invoiceItems, _db.parties,
                      _db.products, _db.activeCompany!,
                      from: _fromDate, to: _toDate);
                  await Printing.sharePdf(
                      bytes: bytes, filename: 'Sales_Report.csv');
                },
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await GstrExporter.shareGstr1Pdf(
                      _db.invoices, _db.invoiceItems, _db.parties,
                      _db.products, _db.activeCompany!,
                      from: _fromDate, to: _toDate);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sales.isEmpty
                ? const Center(
                    child: Text('No sales in selected period.'))
                : ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, i) {
                      final inv = sales[i];
                      final party = _db.parties
                          .cast<Party?>()
                          .firstWhere((p) => p!.id == inv.partyId,
                              orElse: () => null);
                      return ListTile(
                        leading: const Icon(Icons.receipt,
                            color: Colors.green),
                        title: Text('#${inv.invoiceNumber} — ${party?.name ?? 'Cash Customer'}'),
                        subtitle: Text(
                            '${inv.createdAt.toString().split(' ')[0]} | ${inv.paymentMethod.toUpperCase()}'),
                        trailing: Text(
                            '₹${inv.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Purchase reports ─────────────────────────────────────────────────────

  Widget _buildPurchaseTab() {
    final purchases = _filteredInvoices
        .where((i) => i.invoiceType == 'purchase' && !i.isCancelled)
        .toList();
    final totalCost =
        purchases.fold(0.0, (s, i) => s + i.totalAmount);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _summaryCard('Total Purchases', '₹${totalCost.toStringAsFixed(2)}', Colors.red, Icons.shopping_cart),
              const SizedBox(width: 12),
              _summaryCard('Purchase Count', '${purchases.length}', Colors.orange, Icons.inventory),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  // Build purchase CSV
                  final rows = purchases
                      .map((inv) {
                        final party = _db.parties
                            .cast<Party?>()
                            .firstWhere(
                                (p) => p!.id == inv.partyId,
                                orElse: () => null);
                        return '${inv.invoiceNumber},${inv.createdAt.toString().split(' ')[0]},${party?.name ?? ''},${inv.subtotal},${inv.taxAmount},${inv.totalAmount}';
                      })
                      .join('\n');
                  final csv =
                      'Invoice#,Date,Supplier,Subtotal,Tax,Total\n$rows';
                  await Printing.sharePdf(
                      bytes: csv.codeUnits
                          .map((c) => c)
                          .toList()
                          .fold<List<int>>(
                              [],
                              (list, c) => list..add(c))
                          .map((b) => b)
                          .toList() as dynamic,
                      filename: 'Purchases.csv');
                },
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: purchases.isEmpty
                ? const Center(
                    child: Text('No purchases in selected period.'))
                : ListView.builder(
                    itemCount: purchases.length,
                    itemBuilder: (context, i) {
                      final inv = purchases[i];
                      final party = _db.parties
                          .cast<Party?>()
                          .firstWhere((p) => p!.id == inv.partyId,
                              orElse: () => null);
                      return ListTile(
                        leading: const Icon(Icons.shopping_cart,
                            color: Colors.orange),
                        title: Text('#${inv.invoiceNumber} — ${party?.name ?? 'Supplier'}'),
                        subtitle: Text(
                            inv.createdAt.toString().split(' ')[0]),
                        trailing: Text(
                            '₹${inv.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Inventory reports ────────────────────────────────────────────────────

  Widget _buildInventoryTab() {
    final now = DateTime.now();
    final totalStockValue = _db.batches.fold(
        0.0,
        (s, b) =>
            s + b.currentStock * b.purchasePrice);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _summaryCard('Stock Valuation (Cost)', '₹${totalStockValue.toStringAsFixed(0)}', Colors.blue, Icons.inventory_2),
              const SizedBox(width: 12),
              _summaryCard('Total Products', '${_db.products.length}', Colors.teal, Icons.medication),
              const SizedBox(width: 12),
              _summaryCard('Expiry Alerts', '${_db.batches.where((b) => b.expiryDate.isBefore(now.add(const Duration(days: 30)))).length}', Colors.orange, Icons.warning),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes = await PdfGenerator.buildExpiryReportPdf(
                      _db.batches, _db.products, _db.activeCompany!);
                  await Printing.sharePdf(
                      bytes: bytes, filename: 'Expiry_Report.pdf');
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Expiry PDF'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes = GstrExporter.buildHsnSummaryCsv(
                      _db.invoices, _db.invoiceItems, _db.products,
                      from: _fromDate, to: _toDate);
                  await Printing.sharePdf(
                      bytes: bytes, filename: 'HSN_Summary.csv');
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('HSN CSV'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _db.products.length,
              itemBuilder: (context, i) {
                final p = _db.products[i];
                final batches = _db.batches
                    .where((b) => b.productId == p.id)
                    .toList();
                final stock = batches.fold(
                    0, (s, b) => s + b.currentStock);
                final value = batches.fold(
                    0.0,
                    (s, b) =>
                        s + b.currentStock * b.purchasePrice);
                return ListTile(
                  leading: const Icon(Icons.medication,
                      color: Colors.blue),
                  title: Text(p.name),
                  subtitle: Text(
                      'HSN: ${p.hsnCode} | GST: ${p.gstRate}% | Schedule: ${p.scheduleType}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Stock: $stock units',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: stock <= p.reorderLevel
                                  ? Colors.orange
                                  : null)),
                      Text(
                          'Value: ₹${value.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Restricted drug reports ──────────────────────────────────────────────

  Widget _buildRestrictedDrugTab() {
    final logs = _db.restrictedLogs.where((log) {
      if (_fromDate != null && log.createdAt.isBefore(_fromDate!))
        return false;
      if (_toDate != null && log.createdAt.isAfter(_toDate!))
        return false;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Restricted Drug Transactions: ${logs.length}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes =
                      await PdfGenerator.buildRestrictedDrugRegisterPdf(
                          logs, _db.activeCompany!);
                  await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'DrugRegister.pdf');
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF Register'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text('No restricted drug transactions.'))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final log = logs[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            log.scheduleType == 'Narcotics'
                                ? Icons.warning
                                : Icons.security,
                            color: log.scheduleType == 'Narcotics'
                                ? Colors.red
                                : Colors.purple,
                          ),
                          title: Text(
                              '${log.scheduleType} | Patient: ${log.patientName}'),
                          subtitle: Text(
                              'Doctor: ${log.doctorName} | Qty: ${log.quantity}'),
                          trailing: Text(
                              log.createdAt
                                  .toString()
                                  .split(' ')[0],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Analytics (fast/slow moving) ─────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    // Build sales velocity map
    final velocityMap = <String, int>{};
    for (final inv in _db.invoices.where((i) =>
        i.invoiceType == 'sales' && !i.isCancelled)) {
      if (_fromDate != null && inv.createdAt.isBefore(_fromDate!))
        continue;
      if (_toDate != null && inv.createdAt.isAfter(_toDate!)) continue;
      for (final item in _db.invoiceItems
          .where((i) => i.invoiceId == inv.id)) {
        velocityMap[item.productId] =
            (velocityMap[item.productId] ?? 0) + item.quantity;
      }
    }

    final sorted = _db.products.toList()
      ..sort((a, b) =>
          (velocityMap[b.id] ?? 0)
              .compareTo(velocityMap[a.id] ?? 0));

    final fastMoving = sorted.take(5).toList();
    final slowMoving = sorted.reversed.take(5).toList();

    final totalRevenue = _filteredInvoices
        .where((i) => i.invoiceType == 'sales' && !i.isCancelled)
        .fold(0.0, (s, i) => s + i.totalAmount);
    final totalCost = _filteredInvoices
        .where((i) => i.invoiceType == 'purchase' && !i.isCancelled)
        .fold(0.0, (s, i) => s + i.subtotal);
    final grossProfit = totalRevenue - totalCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L summary
          Row(
            children: [
              _summaryCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Colors.green, Icons.trending_up),
              const SizedBox(width: 12),
              _summaryCard('Total COGS', '₹${totalCost.toStringAsFixed(0)}', Colors.red, Icons.trending_down),
              const SizedBox(width: 12),
              _summaryCard('Gross Profit', '₹${grossProfit.toStringAsFixed(0)}', grossProfit >= 0 ? Colors.teal : Colors.red, Icons.account_balance),
            ],
          ),
          const SizedBox(height: 24),
          // Fast moving
          const Text('Top 5 Fast-Moving Medicines',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...fastMoving.map((p) {
            final qty = velocityMap[p.id] ?? 0;
            return ListTile(
              leading: const Icon(Icons.trending_up,
                  color: Colors.green),
              title: Text(p.name),
              subtitle: Text('Schedule: ${p.scheduleType}'),
              trailing: Chip(
                label: Text('$qty units sold'),
                backgroundColor: Colors.green.withOpacity(0.15),
              ),
            );
          }),
          const SizedBox(height: 24),
          // Slow moving
          const Text('Slow / Non-Moving Medicines',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...slowMoving.map((p) {
            final qty = velocityMap[p.id] ?? 0;
            final stock = _db.batches
                .where((b) => b.productId == p.id)
                .fold(0, (s, b) => s + b.currentStock);
            return ListTile(
              leading: const Icon(Icons.trending_flat,
                  color: Colors.orange),
              title: Text(p.name),
              subtitle:
                  Text('Current Stock: $stock units'),
              trailing: Chip(
                label: Text('$qty units sold'),
                backgroundColor: Colors.orange.withOpacity(0.15),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(
          String title, String value, Color color, IconData icon) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ],
          ),
        ),
      );
}
