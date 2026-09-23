import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class PurchaseEntryView extends StatefulWidget {
  const PurchaseEntryView({super.key});

  @override
  State<PurchaseEntryView> createState() => _PurchaseEntryViewState();
}

class _PurchaseEntryViewState extends State<PurchaseEntryView> {
  final _db = SupabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  Party? _selectedSupplier;
  final _invoiceNumberCtrl = TextEditingController();
  final List<_PurchaseLineItem> _lines = [];

  @override
  void initState() {
    super.initState();
    final suppliers = _db.parties.where((p) => p.partyType == 'supplier').toList();
    if (suppliers.isNotEmpty) _selectedSupplier = suppliers.first;
    _invoiceNumberCtrl.text = 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _addLine();
  }

  void _addLine() {
    setState(() {
      _lines.add(_PurchaseLineItem(products: _db.products));
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  double get _subtotal => _lines.fold(0.0, (s, l) => s + l.lineSubtotal);
  double get _totalTax => _lines.fold(0.0, (s, l) => s + l.lineTax);
  double get _grandTotal => _subtotal + _totalTax;

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }
    if (_lines.isEmpty || _lines.any((l) => l.selectedProduct == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All line items must have a product selected.')),
      );
      return;
    }

    try {

    // Create / find batch for each line
    final itemsData = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final prod = line.selectedProduct!;

      // Check if batch already exists
      Batch? existingBatch = _db.batches.cast<Batch?>().firstWhere(
        (b) => b!.productId == prod.id && b.batchNumber == line.batchNumberCtrl.text.trim(),
        orElse: () => null,
      );

      if (existingBatch == null) {
        // Create new batch
        final newBatch = Batch(
          productId: prod.id,
          batchNumber: line.batchNumberCtrl.text.trim(),
          mfgDate: line.mfgDate ?? DateTime.now().subtract(const Duration(days: 30)),
          expiryDate: line.expiryDate ?? DateTime.now().add(const Duration(days: 365)),
          retailPrice: line.mrpCtrl.text.isNotEmpty ? double.tryParse(line.mrpCtrl.text) ?? 0.0 : 0.0,
          wholesalePrice: line.wholesalePriceCtrl.text.isNotEmpty ? double.tryParse(line.wholesalePriceCtrl.text) ?? 0.0 : 0.0,
          distributorPrice: line.distributorPriceCtrl.text.isNotEmpty ? double.tryParse(line.distributorPriceCtrl.text) ?? 0.0 : 0.0,
          loyaltyPrice: line.mrpCtrl.text.isNotEmpty ? (double.tryParse(line.mrpCtrl.text) ?? 0.0) * 0.95 : 0.0,
          purchasePrice: double.tryParse(line.purchasePriceCtrl.text) ?? 0.0,
          currentStock: 0, // will be incremented by createInvoice
        );
        await _db.addBatch(newBatch);
        existingBatch = newBatch;
      }

      itemsData.add({
        'product': prod,
        'batch': existingBatch,
        'qty': int.tryParse(line.qtyCtrl.text) ?? 0,
        'price': double.tryParse(line.purchasePriceCtrl.text) ?? 0.0,
        'discount': double.tryParse(line.discountCtrl.text) ?? 0.0,
      });
    }

    await _db.createInvoice(
      invoiceNumber: _invoiceNumberCtrl.text,
      partyId: _selectedSupplier!.id,
      invoiceType: 'purchase',
      paymentMethod: 'cash',
      itemsData: itemsData,
      patientName: '',
      doctorName: '',
      pharmacistApproved: false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase invoice ${_invoiceNumberCtrl.text} saved. Stock updated.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Reset the form for a new entry instead of popping
      setState(() {
        _lines.clear();
        _invoiceNumberCtrl.text =
            'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _addLine();
      });
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving purchase: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _db.parties.where((p) => p.partyType == 'supplier').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase / Supplier Invoice Entry'),
        actions: [
          ElevatedButton.icon(
            onPressed: _savePurchase,
            icon: const Icon(Icons.save),
            label: const Text('Save Purchase'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Party>(
                      value: _selectedSupplier,
                      decoration: const InputDecoration(labelText: 'Supplier *', prefixIcon: Icon(Icons.business)),
                      items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (v) => setState(() => _selectedSupplier = v),
                      validator: (v) => v == null ? 'Select a supplier' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Supplier Invoice / PO Number *', prefixIcon: Icon(Icons.receipt)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ),
            // Lines header
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Batch #', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Mfg Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Exp Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Purchase ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('MRP ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Wholesale ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Dist. ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Disc %', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            // Line items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  return _PurchaseLineWidget(
                    key: ValueKey(_lines[index].key),
                    line: _lines[index],
                    onRemove: () => _removeLine(index),
                    onChanged: () => setState(() {}),
                  );
                },
              ),
            ),
            // Footer totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Line Item'),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal: ₹${_subtotal.toStringAsFixed(2)}'),
                      Text('GST Tax: ₹${_totalTax.toStringAsFixed(2)}'),
                      Text('GRAND TOTAL: ₹${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line item model ──────────────────────────────────────────────────────────

class _PurchaseLineItem {
  final String key = UniqueKey().toString();
  final List<Product> products;
  Product? selectedProduct;
  final batchNumberCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '0');
  final purchasePriceCtrl = TextEditingController(text: '0.00');
  final mrpCtrl = TextEditingController(text: '0.00');
  final wholesalePriceCtrl = TextEditingController(text: '0.00');
  final distributorPriceCtrl = TextEditingController(text: '0.00');
  final discountCtrl = TextEditingController(text: '0');
  DateTime? mfgDate;
  DateTime? expiryDate;

  _PurchaseLineItem({required this.products});

  double get lineSubtotal {
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(purchasePriceCtrl.text) ?? 0;
    final disc = double.tryParse(discountCtrl.text) ?? 0;
    return qty * price * (1 - disc / 100);
  }

  double get lineTax {
    if (selectedProduct == null) return 0;
    return lineSubtotal * (selectedProduct!.gstRate / 100);
  }
}

// ── Line item widget ─────────────────────────────────────────────────────────

class _PurchaseLineWidget extends StatefulWidget {
  final _PurchaseLineItem line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PurchaseLineWidget({
    required super.key,
    required this.line,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PurchaseLineWidget> createState() => _PurchaseLineWidgetState();
}

class _PurchaseLineWidgetState extends State<_PurchaseLineWidget> {
  final _fmt = DateFormat('dd-MM-yyyy');

  Future<void> _pickDate(bool isMfg) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMfg
          ? (widget.line.mfgDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (widget.line.expiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isMfg) {
          widget.line.mfgDate = picked;
        } else {
          widget.line.expiryDate = picked;
        }
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<Product>(
              value: line.selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Select product', isDense: true),
              items: line.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (p) {
                setState(() => line.selectedProduct = p);
                widget.onChanged();
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: line.batchNumberCtrl,
              decoration: const InputDecoration(hintText: 'Batch #', isDense: true),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(isDense: true, hintText: 'Mfg'),
                child: Text(
                  line.mfgDate != null ? _fmt.format(line.mfgDate!) : 'Pick',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(isDense: true, hintText: 'Exp'),
                child: Text(
                  line.expiryDate != null ? _fmt.format(line.expiryDate!) : 'Pick',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.qtyCtrl, decoration: const InputDecoration(hintText: 'Qty', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => widget.onChanged())),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.purchasePriceCtrl, decoration: const InputDecoration(hintText: 'Purchase ₹', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => widget.onChanged())),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.mrpCtrl, decoration: const InputDecoration(hintText: 'MRP ₹', isDense: true), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.wholesalePriceCtrl, decoration: const InputDecoration(hintText: 'Wholesale ₹', isDense: true), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.distributorPriceCtrl, decoration: const InputDecoration(hintText: 'Dist. ₹', isDense: true), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: line.discountCtrl, decoration: const InputDecoration(hintText: 'Disc%', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => widget.onChanged())),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: widget.onRemove),
        ],
      ),
    );
  }
}
