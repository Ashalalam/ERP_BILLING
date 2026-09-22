import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/utils/share_service.dart';
import 'party_form.dart';

class CustomerPatientView extends StatefulWidget {
  const CustomerPatientView({super.key});

  @override
  State<CustomerPatientView> createState() => _CustomerPatientViewState();
}

class _CustomerPatientViewState extends State<CustomerPatientView>
    with SingleTickerProviderStateMixin {
  final _db = SupabaseService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer & Patient Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Customers'),
            Tab(text: 'Patient Profiles'),
            Tab(text: 'Refill Reminders'),
            Tab(text: 'AR Aging Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomersTab(),
          _buildPatientsTab(),
          _buildRefillTab(),
          _buildArAgingTab(),
        ],
      ),
    );
  }

  // ── Customers ────────────────────────────────────────────────────────────

  Widget _buildCustomersTab() {
    final customers =
        _db.parties.where((p) => p.partyType == 'customer').toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Customers (${customers.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                      context: context,
                      builder: (_) =>
                          const PartyFormDialog(partyType: 'customer'));
                  setState(() {});
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Customer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];
                final totalPurchases = _db.invoices
                    .where((inv) =>
                        inv.partyId == c.id && inv.invoiceType == 'sales')
                    .fold(0.0, (s, inv) => s + inv.totalAmount);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(c.name[0].toUpperCase())),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${c.phone ?? 'No phone'} | ${c.email ?? 'No email'}\n'
                        'Tier: ${c.pricingTier} | GSTIN: ${c.gstin ?? 'N/A'}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${totalPurchases.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (c.phone != null)
                              IconButton(
                                icon: const Icon(Icons.message,
                                    color: Colors.green, size: 18),
                                tooltip: 'WhatsApp',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ShareService.launchWhatsApp(
                                    context,
                                    'https://wa.me/${c.phone!.replaceAll(RegExp(r'[^\d]'), '')}'),
                              ),
                            if (c.email != null)
                              IconButton(
                                icon: const Icon(Icons.email,
                                    color: Colors.blue, size: 18),
                                tooltip: 'Email',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ShareService.launchEmail(
                                    context, 'mailto:${c.email}'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await showDialog(
                                    context: context,
                                    builder: (_) => PartyFormDialog(
                                        existing: c, partyType: 'customer'));
                                setState(() {});
                              },
                            ),
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
    );
  }

  // ── Patient Profiles ─────────────────────────────────────────────────────

  Widget _buildPatientsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Patient Profiles',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showPatientForm(null),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Patient'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _db.patients.isEmpty
                ? const Center(child: Text('No patient profiles yet.'))
                : ListView.builder(
                    itemCount: _db.patients.length,
                    itemBuilder: (context, i) {
                      final p = _db.patients[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p.patientName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Row(
                                    children: [
                                      Text(
                                          'Age: ${p.age ?? 'N/A'} | ${p.gender ?? ''}'),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showPatientForm(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.image,
                                            color: Colors.teal, size: 18),
                                        tooltip: 'Upload Prescription Image',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _uploadPrescriptionImage(p),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (p.knownAllergies.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.warning,
                                        color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                          'Allergies: ${p.knownAllergies.join(', ')}',
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                              if (p.chronicRefillNotes != null)
                                Text('Chronic: ${p.chronicRefillNotes}',
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              if (p.prescriptionImageUrl != null)
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 14),
                                    SizedBox(width: 4),
                                    Text('Prescription image uploaded',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green)),
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
    );
  }

  void _showPatientForm(PatientProfile? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.patientName ?? '');
    final ageCtrl =
        TextEditingController(text: existing?.age?.toString() ?? '');
    final allergiesCtrl =
        TextEditingController(text: existing?.knownAllergies.join(', ') ?? '');
    final chronicCtrl =
        TextEditingController(text: existing?.chronicRefillNotes ?? '');
    String gender = existing?.gender ?? 'Male';

    Party? party = existing != null
        ? _db.parties
            .cast<Party?>()
            .firstWhere((p) => p!.id == existing.partyId,
                orElse: () => null)
        : _db.parties
            .where((p) => p.partyType == 'customer')
            .cast<Party?>()
            .firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Patient' : 'Edit Patient'),
        content: StatefulBuilder(
          builder: (context, setS) => SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Party>(
                    value: party,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Linked Customer'),
                    items: _db.parties
                        .where((p) => p.partyType == 'customer')
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setS(() => party = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Patient Full Name')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: ageCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Age'),
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration:
                              const InputDecoration(labelText: 'Gender'),
                          items: ['Male', 'Female', 'Other']
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setS(() => gender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: allergiesCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Known Allergies (comma separated)')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: chronicCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Chronic Refill Notes'),
                      maxLines: 2),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (party == null || nameCtrl.text.isEmpty) return;
              final allergies = allergiesCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (existing == null) {
                await _db.addPatient(PatientProfile(
                  partyId: party!.id,
                  patientName: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text),
                  gender: gender,
                  knownAllergies: allergies,
                  chronicRefillNotes: chronicCtrl.text.trim().isEmpty
                      ? null
                      : chronicCtrl.text.trim(),
                ));
              } else {
                await _db.updatePatient(existing.copyWith(
                  patientName: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text),
                  gender: gender,
                  knownAllergies: allergies,
                  chronicRefillNotes: chronicCtrl.text.trim().isEmpty
                      ? null
                      : chronicCtrl.text.trim(),
                ));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPrescriptionImage(PatientProfile patient) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final url =
        await _db.uploadPrescriptionImage(patient.id, bytes, file.name);
    if (url != null) {
      await _db.updatePatient(patient.copyWith(prescriptionImageUrl: url));
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Prescription image uploaded.'),
            backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload failed. Check Supabase Storage config.'),
            backgroundColor: Colors.orange));
      }
    }
  }

  // ── Refill Reminders ─────────────────────────────────────────────────────

  Widget _buildRefillTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Refill Reminders',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: _db.refillReminders.isEmpty
                ? const Center(
                    child: Text('No refill reminders configured.'))
                : ListView.builder(
                    itemCount: _db.refillReminders.length,
                    itemBuilder: (context, i) {
                      final reminder = _db.refillReminders[i];
                      final patient = _db.patients
                          .cast<PatientProfile?>()
                          .firstWhere(
                              (p) => p!.id == reminder.patientId,
                              orElse: () => null);
                      final product = _db.products
                          .cast<Product?>()
                          .firstWhere(
                              (p) => p!.id == reminder.productId,
                              orElse: () => null);
                      final party = patient != null
                          ? _db.parties.cast<Party?>().firstWhere(
                              (p) => p!.id == patient.partyId,
                              orElse: () => null)
                          : null;
                      final waUrl =
                          ShareService.buildWhatsAppRefillReminderUrl(
                        patient?.patientName ?? 'Patient',
                        product?.name ?? 'Medication',
                        party?.phone ?? '+919876543210',
                        reminder.reminderDate,
                      );
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active,
                              color: Colors.blue),
                          title: Text(
                              '${patient?.patientName ?? 'Unknown'} — ${product?.name ?? 'Unknown'}'),
                          subtitle: Text(
                              'Due: ${reminder.reminderDate.toString().split(' ')[0]} | Status: ${reminder.status}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    ShareService.launchWhatsApp(
                                        context, waUrl),
                                icon: const Icon(Icons.message, size: 14),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6)),
                              ),
                              if (party?.email != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      ShareService.launchEmail(context,
                                          'mailto:${party!.email}'),
                                  icon:
                                      const Icon(Icons.email, size: 14),
                                  label: const Text('Email'),
                                ),
                              ],
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

  // ── AR Aging Ledger ──────────────────────────────────────────────────────

  Widget _buildArAgingTab() {
    final customers =
        _db.parties.where((p) => p.partyType == 'customer').toList();
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accounts Receivable (AR) Aging Report',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Outstanding customer balances by aging bucket',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              _agingHeader('Customer', flex: 3),
              _agingHeader('Current', color: Colors.green),
              _agingHeader('1-30 Days', color: Colors.yellow[700]!),
              _agingHeader('31-60 Days', color: Colors.orange),
              _agingHeader('61-90 Days', color: Colors.deepOrange),
              _agingHeader('90+ Days', color: Colors.red),
              _agingHeader('Total', color: Colors.blue),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];
                final invoices = _db.invoices
                    .where((inv) =>
                        inv.partyId == c.id &&
                        inv.invoiceType == 'sales' &&
                        !inv.isCancelled)
                    .toList();
                double current = 0,
                    d30 = 0,
                    d60 = 0,
                    d90 = 0,
                    over90 = 0;
                for (final inv in invoices) {
                  final age =
                      now.difference(inv.createdAt).inDays;
                  if (age <= 0) current += inv.totalAmount;
                  else if (age <= 30) d30 += inv.totalAmount;
                  else if (age <= 60) d60 += inv.totalAmount;
                  else if (age <= 90) d90 += inv.totalAmount;
                  else over90 += inv.totalAmount;
                }
                final total = current + d30 + d60 + d90 + over90;
                if (total == 0) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        _agingCell(current, color: Colors.green),
                        _agingCell(d30, color: Colors.yellow[700]!),
                        _agingCell(d60, color: Colors.orange),
                        _agingCell(d90, color: Colors.deepOrange),
                        _agingCell(over90, color: Colors.red),
                        _agingCell(total,
                            color: Colors.blue, bold: true),
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

  Widget _agingHeader(String label,
          {int flex = 1, Color? color}) =>
      Expanded(
        flex: flex,
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color),
            textAlign: TextAlign.end),
      );

  Widget _agingCell(double amount,
          {Color? color, bool bold = false}) =>
      Expanded(
        child: Text(
          amount > 0 ? '₹${amount.toStringAsFixed(0)}' : '-',
          style: TextStyle(
              fontSize: 12,
              color: amount > 0 ? color : Colors.grey,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal),
          textAlign: TextAlign.end,
        ),
      );
}
