import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/utils/fefo_selector.dart';
import '../../core/utils/pdf_generator.dart';
import 'product_form.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory, Batch & Expiry Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Product Catalog'),
            Tab(text: 'Batch & Expiry Alerts'),
            Tab(text: 'RTV Drafts'),
            Tab(text: 'Reorder PO Automation'),
            Tab(text: 'Stock Transfers'),
            Tab(text: 'Stock Adjustments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildBatchesTab(),
          _buildRtvTab(),
          _buildReorderTab(),
          _buildStockTransferTab(),
          _buildStockAdjustmentTab(),
        ],
      ),
    );
  }

  // ── Products tab ─────────────────────────────────────────────────────────

  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medicine / Product Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  final added = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ProductFormDialog(),
                  );
                  if (added == true) setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.products.length,
              itemBuilder: (context, index) {
                final p = _db.products[index];
                final totalStock = _db.batches
                    .where((b) => b.productId == p.id)
                    .fold(0, (s, b) => s + b.currentStock);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.scheduleType == 'OTC'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        Icons.medication,
                        color: p.scheduleType == 'OTC' ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Salt: ${p.genericName ?? 'N/A'} | HSN: ${p.hsnCode} | GST: ${p.gstRate}%\n'
                        'Mfr: ${p.manufacturer ?? 'N/A'} | Unit: ${p.unit ?? 'N/A'} | Pack: ${p.packSize ?? 'N/A'}\n'
                        'Location: ${p.rack ?? 'Unassigned'}, ${p.shelf ?? ''}'),
                    isThreeLine: true,
                    trailing: SizedBox(
                      width: 130,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$totalStock units',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: totalStock <= p.reorderLevel
                                        ? Colors.orange
                                        : null,
                                  )),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.scheduleType == 'OTC'
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(p.scheduleType,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: p.scheduleType == 'OTC'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () async {
                              final updated = await showDialog<bool>(
                                context: context,
                                builder: (_) => ProductFormDialog(existing: p),
                              );
                              if (updated == true) setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
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

  // ── Batches tab ──────────────────────────────────────────────────────────

  Widget _buildBatchesTab() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildAlertBadge('< 30D', FefoSelector.getNearExpiryBatches(_db.batches, now, 30).length, Colors.orange),
                  const SizedBox(width: 8),
                  _buildAlertBadge('< 60D', FefoSelector.getNearExpiryBatches(_db.batches, now, 60).length, Colors.amber),
                  const SizedBox(width: 8),
                  _buildAlertBadge('< 90D', FefoSelector.getNearExpiryBatches(_db.batches, now, 90).length, Colors.yellow[700]!),
                  const SizedBox(width: 8),
                  _buildAlertBadge('Expired', FefoSelector.getExpiredBatches(_db.batches, now).length, Colors.red),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes = await PdfGenerator.buildExpiryReportPdf(
                      _db.batches, _db.products, _db.activeCompany!);
                  await Printing.sharePdf(bytes: bytes, filename: 'Expiry_Report.pdf');
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export Expiry PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.batches.length,
              itemBuilder: (context, index) {
                final b = _db.batches[index];
                final prod = _db.products.cast<Product?>().firstWhere(
                    (p) => p!.id == b.productId, orElse: () => null);
                final daysLeft = b.expiryDate.difference(now).inDays;
                final isExpired = daysLeft <= 0;

                return Card(
                  color: isExpired
                      ? Colors.red.withOpacity(0.08)
                      : (daysLeft <= 30 ? Colors.orange.withOpacity(0.08) : null),
                  child: ListTile(
                    leading: Icon(
                      isExpired ? Icons.cancel : Icons.inventory,
                      color: isExpired ? Colors.red : (daysLeft <= 30 ? Colors.orange : Colors.green),
                    ),
                    title: Text('${prod?.name ?? 'Unknown'} — Batch #${b.batchNumber}'),
                    subtitle: Text(
                        'Mfg: ${b.mfgDate.toString().split(' ')[0]} | '
                        'Exp: ${b.expiryDate.toString().split(' ')[0]} ($daysLeft days left)'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Stock: ${b.currentStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('MRP ₹${b.retailPrice.toStringAsFixed(2)}'),
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

  Widget _buildAlertBadge(String label, int count, Color color) => Card(
        color: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );

  // ── RTV tab ──────────────────────────────────────────────────────────────

  Widget _buildRtvTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Return-to-Vendor Draft Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  final count = _db.generateRtvDraftsForExpiredBatches();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Generated $count RTV drafts.')));
                  setState(() {});
                },
                icon: const Icon(Icons.add_task),
                label: const Text('Auto Generate RTV Drafts'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _db.rtvNotes.isEmpty
                ? const Center(child: Text('No RTV notes yet. Click "Auto Generate RTV Drafts" above.'))
                : ListView.builder(
                    itemCount: _db.rtvNotes.length,
                    itemBuilder: (context, index) {
                      final rtv = _db.rtvNotes[index];
                      final batch = _db.batches.cast<Batch?>().firstWhere(
                          (b) => b!.id == rtv.batchId, orElse: () => null);
                      final prod = batch != null
                          ? _db.products.cast<Product?>().firstWhere(
                              (p) => p!.id == batch.productId, orElse: () => null)
                          : null;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.assignment_return, color: Colors.orange),
                          title: Text('${prod?.name ?? 'Unknown'} — Batch #${batch?.batchNumber ?? '?'}'),
                          subtitle: Text('Qty to Return: ${rtv.quantity} | Status: ${rtv.status}'),
                          trailing: const Chip(label: Text('Draft'), backgroundColor: Colors.amber),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Reorder PO tab ───────────────────────────────────────────────────────

  Widget _buildReorderTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auto Purchase Order Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: _db.purchaseOrders.isEmpty
                ? const Center(child: Text('No purchase orders. Stock levels are above reorder thresholds.'))
                : ListView.builder(
                    itemCount: _db.purchaseOrders.length,
                    itemBuilder: (context, index) {
                      final po = _db.purchaseOrders[index];
                      final prod = _db.products.cast<Product?>().firstWhere(
                          (p) => p!.id == po.productId, orElse: () => null);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                          title: Text('Auto PO: ${prod?.name ?? 'Unknown'}'),
                          subtitle: Text('Suggested Qty: ${po.quantity} | Reorder Level: ${prod?.reorderLevel ?? '?'}'),
                          trailing: const Chip(label: Text('Auto Generated'), backgroundColor: Colors.blueAccent),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Stock transfer tab ───────────────────────────────────────────────────

  Widget _buildStockTransferTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inter-Store Stock Transfers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showTransferDialog(),
                icon: const Icon(Icons.sync_alt),
                label: const Text('New Transfer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _db.storeTransfers.isEmpty
                ? const Center(child: Text('No transfers yet.'))
                : ListView.builder(
                    itemCount: _db.storeTransfers.length,
                    itemBuilder: (context, index) {
                      final st = _db.storeTransfers[index];
                      final prod = _db.products.cast<Product?>().firstWhere(
                          (p) => p!.id == st.productId, orElse: () => null);
                      final fromStore = _db.stores.cast<Store?>().firstWhere(
                          (s) => s!.id == st.fromStoreId, orElse: () => null);
                      final toStore = _db.stores.cast<Store?>().firstWhere(
                          (s) => s!.id == st.toStoreId, orElse: () => null);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.sync_alt, color: Colors.teal),
                          title: Text('${prod?.name ?? 'Unknown'} — ${st.quantity} units'),
                          subtitle: Text('From: ${fromStore?.name ?? '?'} → To: ${toStore?.name ?? '?'}'),
                          trailing: const Chip(label: Text('Completed')),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    Store? fromStore = _db.stores.isNotEmpty ? _db.stores.first : null;
    Store? toStore = _db.stores.length > 1 ? _db.stores[1] : null;
    Product? selectedProduct = _db.products.isNotEmpty ? _db.products.first : null;
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Stock Transfer'),
        content: StatefulBuilder(
          builder: (context, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Store>(
                value: fromStore,
                decoration: const InputDecoration(labelText: 'From Store'),
                items: _db.stores.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setS(() => fromStore = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Store>(
                value: toStore,
                decoration: const InputDecoration(labelText: 'To Store'),
                items: _db.stores.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setS(() => toStore = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                value: selectedProduct,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Product'),
                items: _db.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setS(() => selectedProduct = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (fromStore == null || toStore == null || selectedProduct == null) return;
              final batches = _db.batches.where((b) => b.productId == selectedProduct!.id).toList();
              if (batches.isEmpty) return;
              await _db.transferStockBetweenStores(
                fromStore!.id, toStore!.id, selectedProduct!.id,
                batches.first.id, int.tryParse(qtyCtrl.text) ?? 1,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  // ── Stock adjustment tab ─────────────────────────────────────────────────

  Widget _buildStockAdjustmentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stock Adjustments (Damage / Write-off / Manual)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAdjustmentDialog(),
                icon: const Icon(Icons.edit_note),
                label: const Text('New Adjustment'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _db.stockAdjustments.isEmpty
                ? const Center(child: Text('No adjustments yet.'))
                : ListView.builder(
                    itemCount: _db.stockAdjustments.length,
                    itemBuilder: (context, index) {
                      final adj = _db.stockAdjustments[index];
                      final prod = _db.products.cast<Product?>().firstWhere(
                          (p) => p!.id == adj.productId, orElse: () => null);
                      final isNegative = adj.quantityChange < 0;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isNegative ? Icons.remove_circle : Icons.add_circle,
                            color: isNegative ? Colors.red : Colors.green,
                          ),
                          title: Text('${prod?.name ?? 'Unknown'} — ${adj.adjustmentType.toUpperCase()}'),
                          subtitle: Text('Reason: ${adj.reason}\n${adj.createdAt.toString().split('.')[0]}'),
                          trailing: Text(
                            '${adj.quantityChange > 0 ? '+' : ''}${adj.quantityChange}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isNegative ? Colors.red : Colors.green,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog() {
    Batch? selectedBatch;
    Product? selectedProduct;
    String adjType = 'damage';
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Stock Adjustment'),
        content: StatefulBuilder(
          builder: (context, setS) => SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: _db.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (p) {
                    setS(() {
                      selectedProduct = p;
                      selectedBatch = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedProduct != null)
                  DropdownButtonFormField<Batch>(
                    value: selectedBatch,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Batch'),
                    items: _db.batches
                        .where((b) => b.productId == selectedProduct!.id)
                        .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text('${b.batchNumber} (Stock: ${b.currentStock})')))
                        .toList(),
                    onChanged: (b) => setS(() => selectedBatch = b),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: adjType,
                  decoration: const InputDecoration(labelText: 'Adjustment Type'),
                  items: const [
                    DropdownMenuItem(value: 'damage', child: Text('Damage Write-off')),
                    DropdownMenuItem(value: 'theft', child: Text('Theft / Loss')),
                    DropdownMenuItem(value: 'sample', child: Text('Sample Issued')),
                    DropdownMenuItem(value: 'expired_writeoff', child: Text('Expired Write-off')),
                    DropdownMenuItem(value: 'manual', child: Text('Manual Correction')),
                  ],
                  onChanged: (v) => setS(() => adjType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (negative = write-off, positive = addition)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason / Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedBatch == null || selectedProduct == null || reasonCtrl.text.isEmpty) return;
              final adj = StockAdjustment(
                companyId: _db.activeCompany?.id ?? '',
                batchId: selectedBatch!.id,
                productId: selectedProduct!.id,
                quantityChange: int.tryParse(qtyCtrl.text) ?? 0,
                adjustmentType: adjType,
                reason: reasonCtrl.text.trim(),
              );
              await _db.addStockAdjustment(adj);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Adjustment'),
          ),
        ],
      ),
    );
  }
}
