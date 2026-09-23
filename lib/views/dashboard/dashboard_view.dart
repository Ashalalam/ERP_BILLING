import 'package:flutter/material.dart';
import '../../core/utils/fefo_selector.dart';
import '../../core/utils/industry_config.dart';
import '../../services/supabase_service.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = SupabaseService.instance;
    final cfg = IndustryState.instance.config;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final totalSales = db.invoices
        .where((i) => i.invoiceType == 'sales' && !i.isCancelled)
        .fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalPurchases = db.invoices
        .where((i) => i.invoiceType == 'purchase' && !i.isCancelled)
        .fold(0.0, (sum, i) => sum + i.totalAmount);
    final nearExpiry30 =
        FefoSelector.getNearExpiryBatches(db.batches, now, 30);
    final expiredCount =
        FefoSelector.getExpiredBatches(db.batches, now).length;
    final scheduleHCount = db.restrictedLogs.length;
    final lowStockCount = db.products
        .where((p) =>
            db.batches
                .where((b) => b.productId == p.id)
                .fold(0, (s, b) => s + b.currentStock) <=
            p.reorderLevel)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cfg.icon, color: cfg.color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '${cfg.name} ERP Dashboard',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Company: ${db.activeCompany?.name ?? 'ERP'} '
                    '| FY: ${db.activeCompany?.financialYear ?? '2026-2027'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              // Status chip — changes per industry
              Chip(
                backgroundColor: cfg.color.withValues(alpha: 0.12),
                avatar: Icon(Icons.check_circle, color: cfg.color, size: 16),
                label: Text(
                  cfg.showScheduleType
                      ? 'Regulatory: Compliant'
                      : '${cfg.name} Mode Active',
                  style: TextStyle(
                      color: cfg.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Quick action buttons ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickActionButton(
                  icon: Icons.point_of_sale,
                  label: 'New ${cfg.invoiceLabel}',
                  color: cfg.color,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _QuickActionButton(
                  icon: Icons.add_box,
                  label: 'Add ${cfg.productLabel}',
                  color: Colors.teal,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _QuickActionButton(
                  icon: Icons.add_shopping_cart,
                  label: 'Purchase Entry',
                  color: Colors.orange,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _QuickActionButton(
                  icon: Icons.analytics,
                  label: 'View Reports',
                  color: Colors.purple,
                  onTap: () {},
                ),
                if (cfg.showExpiryTracking) ...[
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.autorenew,
                    label: 'Generate RTV',
                    color: Colors.red,
                    onTap: () {
                      final count =
                          db.generateRtvDraftsForExpiredBatches();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Generated $count RTV Return-to-Vendor drafts.'),
                        backgroundColor: Colors.orange,
                      ));
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── KPI metric cards ─────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 2.4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    title: 'Total Sales',
                    value: '₹${totalSales.toStringAsFixed(0)}',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                    trend: '+',
                  ),
                  _MetricCard(
                    title: 'Total Purchases',
                    value: '₹${totalPurchases.toStringAsFixed(0)}',
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    title: 'Active ${cfg.productLabel}s',
                    value: '${db.products.length} items',
                    icon: cfg.icon,
                    color: cfg.color,
                  ),
                  _MetricCard(
                    title: 'Low ${cfg.stockLabel} Alerts',
                    value: '$lowStockCount items',
                    icon: Icons.warning_amber,
                    color: lowStockCount > 0 ? Colors.orange : Colors.grey,
                  ),
                  if (cfg.showExpiryTracking) ...[
                    _MetricCard(
                      title: 'Near Expiry (<30 days)',
                      value: '${nearExpiry30.length} batches',
                      icon: Icons.hourglass_bottom,
                      color: nearExpiry30.isNotEmpty
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    _MetricCard(
                      title: 'Expired ${cfg.batchLabel}s',
                      value: '$expiredCount batches',
                      icon: Icons.cancel,
                      color: expiredCount > 0 ? Colors.red : Colors.grey,
                    ),
                  ],
                  if (cfg.showScheduleType)
                    _MetricCard(
                      title: 'Controlled Drug Logs',
                      value: '$scheduleHCount entries',
                      icon: Icons.security,
                      color: Colors.purple,
                    ),
                  _MetricCard(
                    title: 'Invoices Today',
                    value:
                        '${db.invoices.where((i) => i.createdAt.day == now.day && i.createdAt.month == now.month).length}',
                    icon: Icons.receipt,
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Main content row ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: expiry / stock alerts
              Expanded(
                flex: 3,
                child: _buildAlertCard(context, cfg, db, now),
              ),
              const SizedBox(width: 16),
              // Right: audit log / industry summary
              Expanded(
                flex: 2,
                child: _buildSummaryCard(context, cfg, db, scheduleHCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Alert card — adapts per industry ─────────────────────────────────────

  Widget _buildAlertCard(BuildContext context, IndustryConfig cfg,
      SupabaseService db, DateTime now) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(cfg.showExpiryTracking
                        ? Icons.warning_amber
                        : Icons.inventory_2,
                        color: cfg.color),
                    const SizedBox(width: 8),
                    Text(
                      cfg.showExpiryTracking
                          ? 'Near-Expiry ${cfg.batchLabel} Alerts (FEFO)'
                          : '${cfg.stockLabel} Status',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cfg.showExpiryTracking)
              ...db.batches.take(6).map((b) {
                final daysLeft = b.expiryDate.difference(now).inDays;
                final isExpired = daysLeft <= 0;
                final prod = db.products.cast().firstWhere(
                    (p) => p.id == b.productId,
                    orElse: () => null);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isExpired ? Icons.cancel : Icons.warning_amber,
                    color: isExpired
                        ? Colors.red
                        : (daysLeft <= 30 ? Colors.orange : Colors.green),
                    size: 20,
                  ),
                  title: Text(prod?.name ?? 'Unknown',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                      '${cfg.batchLabel} #${b.batchNumber} | '
                      'Exp: ${b.expiryDate.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    isExpired ? 'EXPIRED' : '$daysLeft days',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? Colors.red
                            : (daysLeft <= 30
                                ? Colors.orange
                                : Colors.green),
                        fontSize: 12),
                  ),
                );
              })
            else
              ...db.products.take(6).map((p) {
                final stock = db.batches
                    .where((b) => b.productId == p.id)
                    .fold(0, (s, b) => s + b.currentStock);
                final isLow = stock <= p.reorderLevel;
                return ListTile(
                  dense: true,
                  leading: Icon(cfg.icon,
                      color: isLow ? Colors.orange : Colors.green,
                      size: 20),
                  title: Text(p.name,
                      style: const TextStyle(fontSize: 13)),
                  trailing: Text(
                    '$stock ${cfg.units.first}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLow ? Colors.orange : null,
                        fontSize: 12),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, IndustryConfig cfg,
      SupabaseService db, int scheduleHCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(cfg.icon, color: cfg.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  cfg.showScheduleType
                      ? 'Schedule H / H1 / Narcotics'
                      : '${cfg.name} Summary',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cfg.showScheduleType) ...[
              ListTile(
                dense: true,
                leading:
                    const Icon(Icons.security, color: Colors.purple, size: 18),
                title: const Text('Controlled Drug Transactions'),
                trailing: Chip(
                    label: Text('$scheduleHCount Logged'),
                    padding: EdgeInsets.zero),
              ),
              const Divider(),
            ],
            // Recent audit logs
            const Text('Recent Activity:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...db.auditLogs.take(5).map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          size: 12, color: cfg.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${log.action}: ${log.details.values.join(' ')}',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Metric card widget ───────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(value,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (trend != null)
                        Text(trend!,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
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

// ── Quick action button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
