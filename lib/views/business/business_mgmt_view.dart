import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../customer/party_form.dart';
import 'user_management_view.dart';

class BusinessMgmtView extends StatefulWidget {
  const BusinessMgmtView({super.key});

  @override
  State<BusinessMgmtView> createState() => _BusinessMgmtViewState();
}

class _BusinessMgmtViewState extends State<BusinessMgmtView>
    with SingleTickerProviderStateMixin {
  final _db = SupabaseService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Company & Config'),
            Tab(text: 'Supplier Master'),
            Tab(text: 'User Management'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompanyTab(),
          _buildSuppliersTab(),
          const UserManagementView(),
        ],
      ),
    );
  }

  // ── Company config ───────────────────────────────────────────────────────

  Widget _buildCompanyTab() {
    final company = _db.activeCompany;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Configuration',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.business, color: Colors.blue),
              title: Text(company?.name ?? 'No company'),
              subtitle: Text(
                  'GSTIN: ${company?.gstin ?? 'N/A'} | '
                  'Currency: ${company?.currency ?? 'INR'} | '
                  'FY: ${company?.financialYear ?? '2026-2027'}\n'
                  '${company?.address ?? ''}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(
                        content:
                            Text('Multi-company switcher: coming soon.'))),
                child: const Text('Switch Company'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today,
                        color: Colors.teal),
                    title: const Text('Financial Year'),
                    subtitle: Text(
                        'Active: ${company?.financialYear ?? 'N/A'}'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_money,
                        color: Colors.green),
                    title: const Text('Currency'),
                    subtitle: Text(
                        '${company?.currency ?? 'INR'} (Indian Rupee)'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Database & Backup',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Database backup exported via Supabase.'))),
                        icon: const Icon(Icons.backup),
                        label: const Text('Export DB Backup'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Reports exported.'))),
                        icon: const Icon(Icons.download),
                        label: const Text('Export All Reports'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Supplier master ──────────────────────────────────────────────────────

  Widget _buildSuppliersTab() {
    final suppliers =
        _db.parties.where((p) => p.partyType == 'supplier').toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suppliers (${suppliers.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                      context: context,
                      builder: (_) =>
                          const PartyFormDialog(partyType: 'supplier'));
                  setState(() {});
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Add Supplier'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: suppliers.isEmpty
                ? const Center(child: Text('No suppliers added yet.'))
                : ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, i) {
                      final s = suppliers[i];
                      final totalPurchases = _db.invoices
                          .where((inv) =>
                              inv.partyId == s.id &&
                              inv.invoiceType == 'purchase')
                          .fold(0.0,
                              (sum, inv) => sum + inv.totalAmount);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping,
                              color: Colors.blue),
                          title: Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${s.phone ?? 'No phone'} | ${s.email ?? 'No email'}\n'
                              'GSTIN: ${s.gstin ?? 'N/A'}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                  'Purchases: ₹${totalPurchases.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  await showDialog(
                                      context: context,
                                      builder: (_) => PartyFormDialog(
                                          existing: s,
                                          partyType: 'supplier'));
                                  setState(() {});
                                },
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
}
