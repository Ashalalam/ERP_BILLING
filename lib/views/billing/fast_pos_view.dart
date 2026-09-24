import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/utils/industry_config.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/utils/fefo_selector.dart';
import '../../core/utils/barcode_parser.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/share_service.dart';
import '../../widgets/pharmacist_pin_dialog.dart';
import '../../widgets/split_payment_dialog.dart';

class FastPosView extends StatefulWidget {
  const FastPosView({super.key});

  @override
  State<FastPosView> createState() => _FastPosViewState();
}

class _FastPosViewState extends State<FastPosView> {
  final _db = SupabaseService.instance;
  final _cfg = IndustryState.instance;
  final _barcodeController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedPricingTier = 'retail';
  String _selectedPaymentMethod = 'cash';
  Party? _selectedParty;
  Prescription? _selectedPrescription;
  bool _showScanner = false;
  MobileScannerController? _scannerController;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    if (_db.parties.isNotEmpty) {
      _selectedParty = _db.parties.where((p) => p.partyType == 'customer').firstOrNull ?? _db.parties.first;
    }
    if (_db.prescriptions.isNotEmpty) {
      _selectedPrescription = _db.prescriptions.first;
    }
    // Auto-select pricing tier from customer
    if (_selectedParty != null) {
      _selectedPricingTier = _selectedParty!.pricingTier;
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _barcodeController.dispose();
    _patientNameController.dispose();
    _doctorNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _db.products;
    final q = _searchQuery.toLowerCase();
    return _db.products.where((p) =>
      p.name.toLowerCase().contains(q) ||
      (p.genericName?.toLowerCase().contains(q) ?? false) ||
      (p.barcode?.contains(q) ?? false)
    ).toList();
  }

  void _addProductToCart(Product product) {
    final availableBatches = _db.batches.where((b) => b.productId == product.id).toList();
    final fefoBatch = FefoSelector.selectFefoBatch(availableBatches, DateTime.now());

    if (fefoBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active, non-expired stock for ${product.name}.')),
      );
      return;
    }

    final unitPrice = fefoBatch.getPriceForTier(_selectedPricingTier);

    setState(() {
      final existingIndex = _cartItems.indexWhere((i) => i['batch'].id == fefoBatch.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['qty'] += 1;
      } else {
        _cartItems.add({
          'product': product,
          'batch': fefoBatch,
          'qty': 1,
          'price': unitPrice,
          'discount': 0.0,
        });
      }
    });
  }

  void _handleBarcodeText() {
    final parsed = BarcodeParser.parse(_barcodeController.text.trim());
    _barcodeController.clear();
    final match = _db.products.cast<Product?>().firstWhere(
      (p) => p!.barcode == parsed.gtin || p.barcode == parsed.rawData,
      orElse: () => null,
    );
    if (match != null) {
      _addProductToCart(match);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product found for this barcode.')),
      );
    }
  }

  void _toggleCameraScanner() {
    setState(() {
      _showScanner = !_showScanner;
      if (_showScanner) {
        _scannerController = MobileScannerController();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _barcodeController.text = barcode!.rawValue!;
    _handleBarcodeText();
    setState(() {
      _showScanner = false;
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  void _openSubstituteSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generic / Substitute Medicine Search'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Matches by Salt Composition:'),
              const SizedBox(height: 12),
              ..._db.products.map((p) {
                final stock = _db.batches
                    .where((b) => b.productId == p.id)
                    .fold(0, (s, b) => s + b.currentStock);
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('Salt: ${p.genericName ?? 'N/A'} | Schedule: ${p.scheduleType} | Stock: $stock'),
                  trailing: Text('₹${_db.batches.cast<Batch?>().firstWhere((b) => b!.productId == p.id, orElse: () => null)?.getPriceForTier(_selectedPricingTier).toStringAsFixed(2) ?? 'N/A'}'),
                  onTap: () {
                    Navigator.pop(context);
                    _addProductToCart(p);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _finalizeInvoice() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!')),
      );
      return;
    }

    final hasRestricted = _cartItems.any((i) => (i['product'] as Product).scheduleType != 'OTC');

    // Pharmacist PIN gate for controlled substances
    if (hasRestricted) {
      final approved = await showPharmacistPinDialog(context);
      if (!approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pharmacist authorization denied. Invoice cancelled.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Payment dialog
    double cartTotal = 0;
    for (final item in _cartItems) {
      final qty = item['qty'] as int;
      final price = item['price'] as double;
      final disc = item['discount'] as double;
      final prod = item['product'] as Product;
      final sub = qty * price * (1 - disc / 100);
      cartTotal += sub + sub * (prod.gstRate / 100);
    }

    final paymentResult = await showPaymentDialog(context, totalAmount: cartTotal);
    if (paymentResult == null) return;

    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final invoice = await _db.createInvoice(
      invoiceNumber: invoiceNumber,
      partyId: _selectedParty?.id ?? '',
      prescriptionId: _selectedPrescription?.id,
      invoiceType: 'sales',
      paymentMethod: paymentResult.method,
      itemsData: _cartItems,
      patientName: _patientNameController.text,
      doctorName: _doctorNameController.text,
      pharmacistApproved: hasRestricted,
      cashAmount: paymentResult.cashAmount,
      cardAmount: paymentResult.cardAmount,
      upiAmount: paymentResult.upiAmount,
    );

    final items = _cartItems.map((i) => InvoiceItem(
      invoiceId: invoice.id,
      productId: (i['product'] as Product).id,
      batchId: (i['batch'] as Batch).id,
      productName: (i['product'] as Product).name,
      quantity: i['qty'],
      unitPrice: i['price'],
      taxAmount: 0.0,
      totalPrice: i['qty'] * (i['price'] as double),
      discountPercent: i['discount'] ?? 0.0,
    )).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.invoiceNumber} Created'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRestricted)
                const Chip(
                  avatar: Icon(Icons.verified, color: Colors.green),
                  label: Text('Pharmacist Authorization Verified'),
                ),
              const SizedBox(height: 8),
              _invoiceSummaryCard(invoice, paymentResult),
            ],
          ),
        ),
        actions: [
          // ── Share & communicate ──────────────────────────────
          TextButton.icon(
            onPressed: () {
              final waUrl = ShareService.buildWhatsAppInvoiceUrl(
                  invoice, _selectedParty?.phone ?? '+919876543210');
              ShareService.launchWhatsApp(context, waUrl);
            },
            icon: const Icon(Icons.message, color: Colors.green),
            label: const Text('WhatsApp'),
          ),
          TextButton.icon(
            onPressed: () {
              if (_selectedParty?.email != null) {
                final mailUrl = ShareService.buildEmailInvoiceUrl(
                    invoice, _selectedParty!.email!);
                ShareService.launchEmail(context, mailUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No email on file for this customer.')),
                );
              }
            },
            icon: const Icon(Icons.email),
            label: const Text('Email'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await PdfGenerator.printInvoice(context, invoice,
                  _db.activeCompany!, _selectedParty, items);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await PdfGenerator.sharePdf(
                  invoice, _db.activeCompany!, _selectedParty, items);
            },
            icon: const Icon(Icons.share),
            label: const Text('PDF'),
          ),
          const SizedBox(width: 16),
          // ── Close actions ─────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Keep cart — useful if billing same customer again
            },
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cartItems.clear());
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('New Order'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _invoiceSummaryCard(Invoice invoice, SplitPaymentResult payment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row2('Invoice #', invoice.invoiceNumber),
          _row2('Payment', payment.method.toUpperCase()),
          if (payment.cashAmount > 0) _row2('Cash', '₹${payment.cashAmount.toStringAsFixed(2)}'),
          if (payment.cardAmount > 0) _row2('Card', '₹${payment.cardAmount.toStringAsFixed(2)}'),
          if (payment.upiAmount > 0) _row2('UPI', '₹${payment.upiAmount.toStringAsFixed(2)}'),
          const Divider(),
          _row2('Subtotal', '₹${invoice.subtotal.toStringAsFixed(2)}'),
          _row2('GST Tax', '₹${invoice.taxAmount.toStringAsFixed(2)}'),
          _row2('TOTAL', '₹${invoice.totalAmount.toStringAsFixed(2)}', bold: true),
          if (invoice.eInvoiceIrn != null)
            Text('IRN: ${invoice.eInvoiceIrn}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _row2(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double cartSubtotal = 0.0;
    double cartTax = 0.0;

    for (final item in _cartItems) {
      final qty = item['qty'] as int;
      final price = item['price'] as double;
      final disc = item['discount'] as double? ?? 0.0;
      final prod = item['product'] as Product;
      final sub = qty * price * (1 - disc / 100);
      cartSubtotal += sub;
      cartTax += sub * (prod.gstRate / 100.0);
    }
    final cartTotal = cartSubtotal + cartTax;

    final customers = _db.parties.where((p) => p.partyType == 'customer').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Product catalog & scanner
          Expanded(
            flex: 3,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeController,
                            onSubmitted: (_) => _handleBarcodeText(),
                            decoration: const InputDecoration(
                              hintText: 'Scan barcode or type / enter',
                              prefixIcon: Icon(Icons.qr_code_scanner),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Camera Scanner',
                          icon: Icon(_showScanner ? Icons.close : Icons.camera_alt),
                          onPressed: _toggleCameraScanner,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _openSubstituteSearchDialog,
                          icon: const Icon(Icons.science),
                          label: const Text('Generic Search'),
                        ),
                      ],
                    ),
                    if (_showScanner && _scannerController != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: MobileScanner(
                            controller: _scannerController!,
                            onDetect: _onBarcodeDetected,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search medicines by name, salt, barcode...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Text('${_cfg.config.productLabel} Catalog (${_cfg.config.batchLabel} Auto-Select):', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          final stock = _db.batches
                              .where((b) => b.productId == p.id)
                              .fold(0, (s, b) => s + b.currentStock);
                          final isLowStock = stock <= p.reorderLevel;

                          return InkWell(
                            onTap: () => _addProductToCart(p),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: isLowStock ? Colors.orange : theme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                  Text(p.genericName ?? 'N/A',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(p.scheduleType, style: const TextStyle(fontSize: 9)),
                                        backgroundColor: p.scheduleType == 'OTC'
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        padding: EdgeInsets.zero,
                                        side: BorderSide.none,
                                      ),
                                      Text('Stk: $stock', style: TextStyle(fontSize: 11, color: isLowStock ? Colors.orange : null)),
                                    ],
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
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: Cart & checkout
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_cfg.config.posLabel} — Cart', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Customer selector
                    DropdownButtonFormField<Party>(
                      value: _selectedParty,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: _cfg.config.customerLabel, prefixIcon: const Icon(Icons.person), isDense: true),
                      items: customers.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedParty = v;
                          if (v != null) {
                            _selectedPricingTier = v.pricingTier;
                            // Auto-fill patient name from customer name
                            if (_patientNameController.text.isEmpty) {
                              _patientNameController.text = v.name;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Patient / doctor names
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _patientNameController,
                            decoration: const InputDecoration(labelText: 'Patient Name', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _doctorNameController,
                            decoration: const InputDecoration(labelText: 'Doctor', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPricingTier,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Pricing Tier'),
                      items: const [
                        DropdownMenuItem(value: 'retail', child: Text('Retail')),
                        DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                        DropdownMenuItem(value: 'distributor', child: Text('Distributor')),
                        DropdownMenuItem(value: 'loyalty', child: Text('Loyalty')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPricingTier = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Cart items
                    Expanded(
                      child: _cartItems.isEmpty
                          ? const Center(child: Text('Cart empty — add items', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                final prod = item['product'] as Product;
                                final batch = item['batch'] as Batch;
                                final qty = item['qty'] as int;
                                final price = item['price'] as double;
                                final disc = item['discount'] as double? ?? 0.0;
                                final lineTotal = qty * price * (1 - disc / 100);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(prod.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                              onPressed: () => setState(() => _cartItems.removeAt(index)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        Text('Batch: ${batch.batchNumber} | Exp: ${batch.expiryDate.toString().split(' ')[0]}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        Row(
                                          children: [
                                            // Qty stepper
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  if (qty > 1) {
                                                    _cartItems[index]['qty'] = qty - 1;
                                                  } else {
                                                    _cartItems.removeAt(index);
                                                  }
                                                });
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            Text(' $qty ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 18),
                                              onPressed: () => setState(() => _cartItems[index]['qty'] = qty + 1),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const Spacer(),
                                            // Discount
                                            SizedBox(
                                              width: 60,
                                              child: TextField(
                                                decoration: const InputDecoration(labelText: 'Disc%', isDense: true),
                                                keyboardType: TextInputType.number,
                                                controller: TextEditingController(text: disc.toString()),
                                                onChanged: (v) => setState(() => _cartItems[index]['discount'] = double.tryParse(v) ?? 0.0),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('₹${lineTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Subtotal:'),
                      Text('₹${cartSubtotal.toStringAsFixed(2)}'),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('GST Tax:'),
                      Text('₹${cartTax.toStringAsFixed(2)}'),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('TOTAL PAYABLE:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _finalizeInvoice,
                        icon: const Icon(Icons.receipt_long),
                        label: Text('FINALIZE ${_cfg.config.invoiceLabel.toUpperCase()}'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
