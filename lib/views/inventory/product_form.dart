import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? existing;
  const ProductFormDialog({super.key, this.existing});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _db = SupabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _genericCtrl = TextEditingController(text: widget.existing?.genericName ?? '');
  late final _hsnCtrl = TextEditingController(text: widget.existing?.hsnCode ?? '');
  late final _reorderCtrl = TextEditingController(text: widget.existing?.reorderLevel.toString() ?? '10');
  late final _rackCtrl = TextEditingController(text: widget.existing?.rack ?? '');
  late final _shelfCtrl = TextEditingController(text: widget.existing?.shelf ?? '');
  late final _barcodeCtrl = TextEditingController(text: widget.existing?.barcode ?? '');
  late final _manufacturerCtrl = TextEditingController(text: widget.existing?.manufacturer ?? '');
  late final _categoryCtrl = TextEditingController(text: widget.existing?.category ?? '');
  late final _unitCtrl = TextEditingController(text: widget.existing?.unit ?? '');
  late final _packSizeCtrl = TextEditingController(text: widget.existing?.packSize ?? '');
  late double _gstRate = widget.existing?.gstRate ?? 12.0;
  late String _scheduleType = widget.existing?.scheduleType ?? 'OTC';

  static const _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  static const _scheduleOptions = ['OTC', 'Schedule H', 'Schedule H1', 'Narcotics'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existing == null) {
      final product = Product(
        companyId: _db.activeCompany?.id ?? '',
        name: _nameCtrl.text.trim(),
        genericName: _genericCtrl.text.trim().isEmpty ? null : _genericCtrl.text.trim(),
        hsnCode: _hsnCtrl.text.trim(),
        gstRate: _gstRate,
        scheduleType: _scheduleType,
        reorderLevel: int.tryParse(_reorderCtrl.text) ?? 10,
        rack: _rackCtrl.text.trim().isEmpty ? null : _rackCtrl.text.trim(),
        shelf: _shelfCtrl.text.trim().isEmpty ? null : _shelfCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        packSize: _packSizeCtrl.text.trim().isEmpty ? null : _packSizeCtrl.text.trim(),
      );
      await _db.addProduct(product);
    } else {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        genericName: _genericCtrl.text.trim().isEmpty ? null : _genericCtrl.text.trim(),
        hsnCode: _hsnCtrl.text.trim(),
        gstRate: _gstRate,
        scheduleType: _scheduleType,
        reorderLevel: int.tryParse(_reorderCtrl.text) ?? 10,
        rack: _rackCtrl.text.trim().isEmpty ? null : _rackCtrl.text.trim(),
        shelf: _shelfCtrl.text.trim().isEmpty ? null : _shelfCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        packSize: _packSizeCtrl.text.trim().isEmpty ? null : _packSizeCtrl.text.trim(),
      );
      await _db.updateProduct(updated);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 680,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.existing == null ? 'Add New Medicine' : 'Edit Medicine'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            actions: [
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row([
                    _field(_nameCtrl, 'Brand / Medicine Name *', required: true),
                    _field(_genericCtrl, 'Generic Name / Salt Composition'),
                  ]),
                  const SizedBox(height: 16),
                  _row([
                    _field(_manufacturerCtrl, 'Manufacturer'),
                    _field(_categoryCtrl, 'Category (e.g. Antibiotic, Analgesic)'),
                  ]),
                  const SizedBox(height: 16),
                  _row([
                    _field(_hsnCtrl, 'HSN Code *', required: true),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: _gstRate,
                        decoration: const InputDecoration(labelText: 'GST Rate %'),
                        items: _gstOptions.map((r) => DropdownMenuItem(value: r, child: Text('$r%'))).toList(),
                        onChanged: (v) => setState(() => _gstRate = v!),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _scheduleType,
                        decoration: const InputDecoration(labelText: 'Schedule Type'),
                        items: _scheduleOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _scheduleType = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _row([
                    _field(_unitCtrl, 'Unit (e.g. Strip, Bottle, Vial)'),
                    _field(_packSizeCtrl, 'Pack Size (e.g. 10x10)'),
                    _field(_reorderCtrl, 'Reorder Level', keyboardType: TextInputType.number),
                  ]),
                  const SizedBox(height: 16),
                  _row([
                    _field(_rackCtrl, 'Rack Location'),
                    _field(_shelfCtrl, 'Shelf Location'),
                    _field(_barcodeCtrl, 'Barcode'),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
        children: children
            .map((c) => c is Expanded ? c : Expanded(child: c))
            .expand((c) => [c, const SizedBox(width: 16)])
            .toList()
          ..removeLast(),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      );
}
