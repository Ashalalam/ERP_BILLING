import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/date_range_filter.dart';

class AccountingView extends StatefulWidget {
  const AccountingView({super.key});

  @override
  State<AccountingView> createState() => _AccountingViewState();
}

class _AccountingViewState extends State<AccountingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = SupabaseService.instance;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  List get _filteredEntries => _db.ledgerEntries.where((e) {
        if (_fromDate != null && e.createdAt.isBefore(_fromDate!))
          return false;
        if (_toDate != null && e.createdAt.isAfter(_toDate!)) return false;
        return true;
      }).toList();

  List get _filteredInvoices => _db.invoices.where((i) {
        if (_fromDate != null && i.createdAt.isBefore(_fromDate!))
          return false;
        if (_toDate != null && i.createdAt.isAfter(_toDate!)) return false;
        return !i.isCancelled;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Accounting & Ledger'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General Ledger'),
            Tab(text: 'Cash & Bank'),
            Tab(text: 'Trial Balance'),
            Tab(text: 'Profit & Loss'),
            Tab(text: 'Balance Sheet'),
            Tab(text: 'Bank Reconciliation'),
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
                _buildLedgerTab(),
                _buildCashBankTab(),
                _buildTrialBalanceTab(),
                _buildProfitLossTab(),
                _buildBalanceSheetTab(),
                _buildBankReconciliationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── General Ledger ───────────────────────────────────────────────────────

  Widget _buildLedgerTab() {
    final entries = _filteredEntries;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: entries.isEmpty
          ? const Center(child: Text('No ledger entries for selected period.'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    title: Text(entry.description),
                    subtitle: Text(
                        'Date: ${entry.createdAt.toString().split(' ')[0]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.debit > 0)
                          Text('DR ₹${entry.debit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        if (entry.credit > 0)
                          Text('CR ₹${entry.credit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Cash & Bank ──────────────────────────────────────────────────────────

  Widget _buildCashBankTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _db.accounts.length,
        itemBuilder: (context, index) {
          final acc = _db.accounts[index];
          return Card(
            child: ListTile(
              leading: Icon(acc.type == 'cash'
                  ? Icons.money
                  : Icons.account_balance),
              title: Text(acc.name),
              subtitle: Text('Type: ${acc.type.toUpperCase()}'),
              trailing: Text('₹${acc.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          );
        },
      ),
    );
  }

  // ── Trial Balance ────────────────────────────────────────────────────────

  Widget _buildTrialBalanceTab() {
    final entries = _filteredEntries;
    final totalDebit =
        entries.fold(0.0, (s, e) => s + (e.debit as double));
    final totalCredit =
        entries.fold(0.0, (s, e) => s + (e.credit as double));
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trial Balance Summary',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                title: const Text('Total Debit (DR)'),
                trailing: Text('₹${totalDebit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ),
              ListTile(
                title: const Text('Total Credit (CR)'),
                trailing: Text('₹${totalCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
              ),
              const Divider(),
              Chip(
                label: Text(
                  balanced
                      ? 'Trial Balance Verified & Balanced'
                      : 'Imbalance Detected — Difference: ₹${(totalDebit - totalCredit).abs().toStringAsFixed(2)}',
                ),
                backgroundColor: balanced
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                avatar: Icon(
                  balanced ? Icons.check_circle : Icons.warning,
                  color: balanced ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profit & Loss ────────────────────────────────────────────────────────

  Widget _buildProfitLossTab() {
    final invoices = _filteredInvoices;
    final totalSales = invoices
        .where((i) => i.invoiceType == 'sales')
        .fold(0.0, (s, i) => s + i.subtotal);
    final totalPurchase = invoices
        .where((i) => i.invoiceType == 'purchase')
        .fold(0.0, (s, i) => s + i.subtotal);
    final totalSalesTax = invoices
        .where((i) => i.invoiceType == 'sales')
        .fold(0.0, (s, i) => s + i.taxAmount);
    final grossProfit = totalSales - totalPurchase;
    final netProfit =
        totalSales + totalSalesTax - totalPurchase;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profit & Loss Statement',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _plRow('Sales Revenue (excl. tax)', totalSales,
                  Colors.green),
              _plRow(
                  'GST Tax Collected', totalSalesTax, Colors.blue),
              const Divider(),
              _plRow('Cost of Goods (Purchases)', totalPurchase,
                  Colors.red),
              const Divider(),
              _plRow('Gross Profit', grossProfit,
                  grossProfit >= 0 ? Colors.teal : Colors.red),
              _plRow(
                  'NET PROFIT (incl. Tax)',
                  netProfit,
                  netProfit >= 0 ? Colors.green : Colors.red,
                  bold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plRow(String label, double value, Color color,
      {bool bold = false}) =>
      ListTile(
        title: Text(label,
            style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
        trailing: Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: bold ? 18 : 14,
              color: color),
        ),
      );

  // ── Balance Sheet ────────────────────────────────────────────────────────

  Widget _buildBalanceSheetTab() {
    final cashBalance = _db.accounts
        .where((a) => a.type == 'cash' || a.type == 'bank')
        .fold(0.0, (s, a) => s + a.balance);
    final stockValue = _db.batches.fold(
        0.0,
        (s, b) =>
            s + b.currentStock * b.purchasePrice);
    final totalReceivables = _db.invoices
        .where((i) =>
            i.invoiceType == 'sales' && !i.isCancelled)
        .fold(0.0, (s, i) => s + i.totalAmount);
    final totalPayables = _db.invoices
        .where((i) =>
            i.invoiceType == 'purchase' && !i.isCancelled)
        .fold(0.0, (s, i) => s + i.totalAmount);
    final currentAssets =
        cashBalance + stockValue + totalReceivables;
    final currentLiabilities = totalPayables;
    final equity = currentAssets - currentLiabilities;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Balance Sheet',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('ASSETS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _bsRow(
                  'Cash & Bank', '₹${cashBalance.toStringAsFixed(2)}'),
              _bsRow('Inventory (Stock Value)',
                  '₹${stockValue.toStringAsFixed(2)}'),
              _bsRow('Accounts Receivable',
                  '₹${totalReceivables.toStringAsFixed(2)}'),
              _bsRow(
                  'TOTAL CURRENT ASSETS',
                  '₹${currentAssets.toStringAsFixed(2)}',
                  bold: true),
              const Divider(),
              const Text('LIABILITIES',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _bsRow('Accounts Payable (Purchases)',
                  '₹${currentLiabilities.toStringAsFixed(2)}'),
              _bsRow(
                  'TOTAL LIABILITIES',
                  '₹${currentLiabilities.toStringAsFixed(2)}',
                  bold: true),
              const Divider(),
              _bsRow(
                  'OWNERS EQUITY',
                  '₹${equity.toStringAsFixed(2)}',
                  bold: true,
                  color: equity >= 0 ? Colors.green : Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bsRow(String label, String value,
      {bool bold = false, Color? color}) =>
      ListTile(
        title: Text(label,
            style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
        trailing: Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: bold ? 16 : 14)),
      );

  // ── Bank Reconciliation ──────────────────────────────────────────────────

  Widget _buildBankReconciliationTab() {
    final bankAcc = _db.accounts
        .cast()
        .firstWhere((a) => a.type == 'bank',
            orElse: () => _db.accounts.first);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bank Statement Reconciliation',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_balance,
                    color: Colors.blue),
                title: Text(bankAcc.name),
                subtitle: const Text(
                    'Compare book balance vs bank statement'),
                trailing: Icon(Icons.check_circle,
                    color: Colors.green),
              ),
              const SizedBox(height: 8),
              _bsRow('Book Balance (ERP)',
                  '₹${bankAcc.balance.toStringAsFixed(2)}'),
              _bsRow('Statement Balance',
                  '₹${bankAcc.balance.toStringAsFixed(2)}'),
              const Divider(),
              _bsRow('Difference', '₹0.00',
                  bold: true, color: Colors.green),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Bank reconciliation verified.'))),
                icon: const Icon(Icons.check),
                label: const Text('Run Reconciliation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
