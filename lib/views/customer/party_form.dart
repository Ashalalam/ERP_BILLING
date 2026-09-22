import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

/// Reusable dialog for creating/editing both Customers and Suppliers.
class PartyFormDialog extends StatefulWidget {
  final Party? existing;
  final String partyType; // 'customer' or 'supplier'

  const PartyFormDialog({
    super.key,
    this.existing,
    required this.partyType,
  });

  @override
  State<PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<PartyFormDialog> {
  final _db = SupabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _gstinCtrl = TextEditingController(text: widget.existing?.gstin ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  late final _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
  late final _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
  late String _pricingTier = widget.existing?.pricingTier ?? 'retail';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existing == null) {
      final party = Party(
        companyId: _db.activeCompany?.id ?? '',
        name: _nameCtrl.text.trim(),
        partyType: widget.partyType,
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        pricingTier: _pricingTier,
      );
      await _db.addParty(party);
    } else {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        pricingTier: _pricingTier,
      );
      await _db.updateParty(updated);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.partyType == 'customer';
    final title = widget.existing == null
        ? 'Add ${isCustomer ? 'Customer' : 'Supplier'}'
        : 'Edit ${isCustomer ? 'Customer' : 'Supplier'}';

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: SizedBox(
        width: 560,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            actions: [
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
              const SizedBox(width: 16),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: '${isCustomer ? 'Customer' : 'Supplier'} Name *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstinCtrl,
                    decoration: const InputDecoration(labelText: 'GSTIN (Optional)', prefixIcon: Icon(Icons.receipt_long)),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (isCustomer)
                    DropdownButtonFormField<String>(
                      value: _pricingTier,
                      decoration: const InputDecoration(labelText: 'Pricing Tier', prefixIcon: Icon(Icons.price_change)),
                      items: const [
                        DropdownMenuItem(value: 'retail', child: Text('Retail')),
                        DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                        DropdownMenuItem(value: 'distributor', child: Text('Distributor')),
                        DropdownMenuItem(value: 'loyalty', child: Text('Loyalty')),
                      ],
                      onChanged: (v) => setState(() => _pricingTier = v!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
