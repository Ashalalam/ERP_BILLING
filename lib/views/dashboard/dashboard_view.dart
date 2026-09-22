import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/fefo_selector.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = SupabaseService.instance;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final totalSales = db.invoices.where((i) => i.invoiceType == 'sales').fold(0.0, (sum, i) => sum + i.totalAmount);
    final nearExpiry30 = FefoSelector.getNearExpiryBatches(db.batches, now, 30);
    final expiredCount = FefoSelector.getExpiredBatches(db.batches, now).length;
    final scheduleHCount = db.restrictedLogs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Executive ERP Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Company: ${db.activeCompany?.name ?? 'Pharma ERP'} | FY: ${db.activeCompany?.financialYear ?? '2026-2027'}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              Chip(
                backgroundColor: const Color(0xFF0F52BA).withOpacity(0.15),
                avatar: const Icon(Icons.check_circle, color: Color(0xFF0F52BA), size: 18),
                label: Text('Regulatory Status: Compliant', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMetricCard(context, 'Total Sales Turnover', '₹${totalSales.toStringAsFixed(2)}', Icons.monetization_on, Colors.blue),
                  _buildMetricCard(context, 'Total Active Products', '${db.products.length} Items', Icons.inventory_2, Colors.teal),
                  _buildMetricCard(context, 'Near-Expiry Alerts (<30D)', '${nearExpiry30.length} Batches', Icons.warning_amber, Colors.orange),
                  _buildMetricCard(context, 'Expired Stock (Draft RTV)', '$expiredCount Batches', Icons.dangerous, Colors.red),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Near Expiry Alert Widget
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Real-Time Near-Expiry Stock Alerts (FEFO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () {
                                final count = db.generateRtvDraftsForExpiredBatches();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Generated $count RTV Return-to-Vendor draft notes.'),
                                ));
                              },
                              icon: const Icon(Icons.autorenew, size: 16),
                              label: const Text('Generate RTV Drafts'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: db.batches.length,
                          itemBuilder: (context, index) {
                            final b = db.batches[index];
                            final daysLeft = b.expiryDate.difference(now).inDays;
                            final isExpired = daysLeft <= 0;

                            return ListTile(
                              leading: Icon(
                                isExpired ? Icons.cancel : Icons.warning_amber,
                                color: isExpired ? Colors.red : (daysLeft <= 30 ? Colors.orange : Colors.green),
                              ),
                              title: Text('Batch #${b.batchNumber} (Stock: ${b.currentStock})'),
                              subtitle: Text('Expiry: ${b.expiryDate.toString().split(' ')[0]} ($daysLeft days remaining)'),
                              trailing: Text('MRP ₹${b.retailPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Restricted Drug Log Summary Widget
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Schedule H / H1 / Narcotics Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.security, color: Colors.purple),
                          title: const Text('Restricted Drug Transactions'),
                          trailing: Chip(label: Text('$scheduleHCount Logged')),
                        ),
                        const Divider(),
                        const Text('Latest Audit Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...db.auditLogs.take(4).map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(child: Text('${log.action}: ${log.details.values.join(' ')}', style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
