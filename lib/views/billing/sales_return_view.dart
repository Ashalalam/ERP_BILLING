import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/utils/fefo_selector.dart';

class SalesReturnView extends StatefulWidget {
  const SalesReturnView({super.key});

  @override
  State<SalesReturnView> createState() => _SalesReturnViewState();
}

class _SalesReturnViewState extends State<SalesReturnView>
    with SingleTickerProviderStateMixin {
  final _db = SupabaseService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Returns & Invoice Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Process Return / Refund'),
            Tab(text: 'Invoice History & Cancellation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReturnTab(),
          _buildInvoiceHistoryTab(),
        ],
      ),
    );
  }

  // ── Sales Return tab ─────────────────────────────────────────────────────

  Widget _buildReturnTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Process Customer Return / Refund',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Select an original invoice to process a return. Stock will be restored automatically.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _db.invoices
                  .where((i) =>
                      i.invoiceType == 'sales' && !i.isCancelled)
                  .length,
              itemBuilder: (context, index) {
                final salesInvoices = _db.invoices
                    .where((i) =>
                        i.invoiceType == 'sales' && !i.isCancelled)
                    .toList();
                final inv = salesInvoices[index];
                final party = _db.parties
                    .cast<Party?>()
                    .firstWhere((p) => p!.id == inv.partyId,
                        orElse: () => null);
                final items = _db.invoiceItems
                    .where((i) => i.invoiceId == inv.id)
                    .toList();

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt, color: Colors.blue),
                    title: Text('Invoice #${inv.invoiceNumber}'),
                    subtitle: Text(
                        'Customer: ${party?.name ?? 'Unknown'} | '
                        'Date: ${inv.createdAt.toString().split(' ')[0]} | '
                        '${items.length} items'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${inv.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        ElevatedButton(
                          onPressed: () =>
                              _showReturnDialog(inv, party, items),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4)),
                          child: const Text('Process Return',
                              style: TextStyle(fontSize: 12)),
                        ),
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

  void _showReturnDialog(
      Invoice invoice, Party? party, List<InvoiceItem> items) {
    final selectedItems = <String, bool>{
      for (final i in items) i.id: false
    };
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Return from Invoice #${invoice.invoiceNumber}'),
        content: StatefulBuilder(
          builder: (context, setS) => SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${party?.name ?? 'Unknown'}'),
                const SizedBox(height: 12),
                const Text('Select items to return:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) => CheckboxListTile(
                      value: selectedItems[item.id],
                      onChanged: (v) =>
                          setS(() => selectedItems[item.id] = v!),
                      title: Text(item.productName),
                      subtitle: Text(
                          'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.totalPrice.toStringAsFixed(2)}'),
                    )),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Return Reason *'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) return;
              final returnItems = <Map<String, dynamic>>[];
              for (final item in items) {
                if (selectedItems[item.id] != true) continue;
                final batch = _db.batches.cast<Batch?>().firstWhere(
                    (b) => b!.id == item.batchId,
                    orElse: () => null);
                final product = _db.products.cast<Product?>().firstWhere(
                    (p) => p!.id == item.productId,
                    orElse: () => null);
                if (batch != null && product != null) {
                  returnItems.add({
                    'batch': batch,
                    'qty': item.quantity,
                    'price': item.unitPrice,
                    'product': product,
                  });
                }
              }
              if (returnItems.isEmpty) return;
              await _db.createSalesReturn(
                originalInvoiceId: invoice.id,
                partyId: invoice.partyId ?? '',
                reason: reasonCtrl.text.trim(),
                returnItems: returnItems,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sales return processed. Stock restored.'),
                    backgroundColor: Colors.green));
              }
            },
            child: const Text('Process Return'),
          ),
        ],
      ),
    );
  }

  // ── Invoice History & Cancellation tab ──────────────────────────────────

  Widget _buildInvoiceHistoryTab() {
    final allInvoices = _db.invoices.reversed.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All Invoices (${allInvoices.length})',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: allInvoices.isEmpty
                ? const Center(child: Text('No invoices yet.'))
                : ListView.builder(
                    itemCount: allInvoices.length,
                    itemBuilder: (context, index) {
                      final inv = allInvoices[index];
                      final party = _db.parties
                          .cast<Party?>()
                          .firstWhere((p) => p!.id == inv.partyId,
                              orElse: () => null);
                      return Card(
                        color: inv.isCancelled
                            ? Colors.red.withOpacity(0.06)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            inv.invoiceType == 'sales'
                                ? Icons.sell
                                : Icons.shopping_cart,
                            color: inv.isCancelled
                                ? Colors.red
                                : (inv.invoiceType == 'sales'
                                    ? Colors.green
                                    : Colors.blue),
                          ),
                          title: Row(
                            children: [
                              Text('#${inv.invoiceNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (inv.isCancelled)
                                const Chip(
                                  label: Text('CANCELLED',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white)),
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          subtitle: Text(
                              '${party?.name ?? 'Unknown'} | '
                              '${inv.createdAt.toString().split(' ')[0]} | '
                              '${inv.invoiceType.toUpperCase()} | '
                              '${inv.paymentMethod.toUpperCase()}'
                              '${inv.cancelReason != null ? '\nCancelled: ${inv.cancelReason}' : ''}'),
                          isThreeLine: inv.cancelReason != null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '₹${inv.totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: inv.isCancelled
                                          ? Colors.red
                                          : null)),
                              if (!inv.isCancelled &&
                                  inv.invoiceType == 'sales')
                                TextButton(
                                  onPressed: () =>
                                      _showCancelDialog(inv),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: EdgeInsets.zero),
                                  child: const Text('Cancel Invoice',
                                      style: TextStyle(fontSize: 11)),
                                ),
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

  void _showCancelDialog(Invoice invoice) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Invoice #${invoice.invoiceNumber}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This will reverse stock levels and ledger entries. '
                'This action cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Cancellation Reason *'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Invoice')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) return;
              await _db.cancelInvoice(
                  invoice.id, reasonCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invoice cancelled. Stock reversed.'),
                    backgroundColor: Colors.orange));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );
  }
}
