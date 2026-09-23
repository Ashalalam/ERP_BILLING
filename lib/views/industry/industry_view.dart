import 'package:flutter/material.dart';
import '../../core/utils/industry_config.dart';
import '../../services/supabase_service.dart';

class IndustryView extends StatefulWidget {
  const IndustryView({super.key});

  @override
  State<IndustryView> createState() => _IndustryViewState();
}

class _IndustryViewState extends State<IndustryView> {
  final _industryState = IndustryState.instance;
  final _db = SupabaseService.instance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left: industry selector list ─────────────────────────────────
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.surface,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Industry Mode',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Select your business type to configure\nthe app for your industry.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: IndustryConfig.all.values
                      .map((cfg) => _IndustrySelectorTile(
                            config: cfg,
                            isSelected:
                                _industryState.activeId == cfg.id,
                            onTap: () => _switchIndustry(cfg),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // ── Right: config detail panel ────────────────────────────────────
        Expanded(
          child: _IndustryDetailPanel(
            config: _industryState.config,
            onActivate: () => _switchIndustry(_industryState.config),
            isActive: true,
          ),
        ),
      ],
    );
  }

  void _switchIndustry(IndustryConfig cfg) {
    _industryState.setIndustry(cfg.id);
    // Update company's industry category
    if (_db.activeCompany != null) {
      // Persist in memory — Supabase update on next full save
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(cfg.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Switched to ${cfg.name} mode — app configured for ${cfg.description}'),
          ],
        ),
        backgroundColor: cfg.color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Industry selector tile ───────────────────────────────────────────────────

class _IndustrySelectorTile extends StatelessWidget {
  final IndustryConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndustrySelectorTile({
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isSelected
          ? config.color.withValues(alpha: 0.15)
          : Colors.transparent,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? config.color
              : config.color.withValues(alpha: 0.15),
          child: Icon(config.icon,
              color: isSelected ? Colors.white : config.color, size: 20),
        ),
        title: Text(config.name,
            style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(config.description,
            style: const TextStyle(fontSize: 11)),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: config.color)
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ── Industry detail panel ────────────────────────────────────────────────────

class _IndustryDetailPanel extends StatelessWidget {
  final IndustryConfig config;
  final VoidCallback onActivate;
  final bool isActive;

  const _IndustryDetailPanel({
    required this.config,
    required this.onActivate,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: config.color,
                child: Icon(config.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(config.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Chip(
                          label: const Text('ACTIVE',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: config.color,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Text(config.description,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Terminology section
          _sectionTitle('Terminology in This Mode'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _termChip('Products called', config.productLabel, config.color),
              _termChip('Customers called', config.customerLabel, config.color),
              _termChip('Invoice called', config.invoiceLabel, config.color),
              _termChip('Batch called', config.batchLabel, config.color),
              _termChip('Stock called', config.stockLabel, config.color),
              _termChip('Supplier called', config.supplierLabel, config.color),
              _termChip('POS called', config.posLabel, config.color),
              _termChip('Tax label', config.taxLabel, config.color),
            ],
          ),
          const SizedBox(height: 24),

          // Features enabled
          _sectionTitle('Features Enabled'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('Expiry Tracking', config.showExpiryTracking, config.color),
              _featureChip('Schedule H/H1/Narcotics', config.showScheduleType, config.color),
              _featureChip('Prescription Linkage', config.showPrescription, config.color),
              _featureChip('Batch Tracking', config.showBatchTracking, config.color),
              _featureChip('GST Invoice', config.showGstInvoice, config.color),
              _featureChip('Manufacturing / BOM', config.showManufacturing, config.color),
              _featureChip('Table Management', config.showTableManagement, config.color),
              _featureChip('Recipe Management', config.showRecipe, config.color),
              _featureChip('Wholesale Pricing', config.showWholesale, config.color),
              _featureChip('Refill Reminders', config.showRefillReminders, config.color),
              _featureChip('HSN Code', config.showHsnCode, config.color),
              _featureChip('Weight / Volume Units', config.showWeightVolume, config.color),
            ],
          ),
          const SizedBox(height: 24),

          // Product categories
          _sectionTitle('Product Categories'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: config.productCategories
                .map((cat) => Chip(
                      label: Text(cat,
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          config.color.withValues(alpha: 0.1),
                      side: BorderSide(
                          color: config.color.withValues(alpha: 0.4)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Item types & Units
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Item Types / Classifications'),
                    const SizedBox(height: 8),
                    ...config.itemTypes.map((t) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(Icons.label,
                                  size: 14, color: config.color),
                              const SizedBox(width: 6),
                              Text(t,
                                  style:
                                      const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Units of Measure'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: config.units
                          .map((u) => Chip(
                                label: Text(u,
                                    style: const TextStyle(
                                        fontSize: 11)),
                                padding: EdgeInsets.zero,
                                backgroundColor: config.color
                                    .withValues(alpha: 0.08),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Industry-specific module cards
          _sectionTitle('Industry-Specific Modules'),
          const SizedBox(height: 12),
          _buildModuleCards(context, config),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));

  Widget _termChip(String label, String value, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: Colors.grey)),
              TextSpan(
                  text: value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _featureChip(String label, bool enabled, Color color) => Chip(
        avatar: Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: enabled ? color : Colors.grey,
        ),
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: enabled ? null : Colors.grey)),
        backgroundColor: enabled
            ? color.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.08),
        side: BorderSide(
            color: enabled
                ? color.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _buildModuleCards(BuildContext context, IndustryConfig cfg) {
    final modules = _getModules(cfg);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: modules
          .map((m) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            cfg.color.withValues(alpha: 0.15),
                        child: Icon(m['icon'] as IconData,
                            color: cfg.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m['title'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text(m['sub'] as String,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  List<Map<String, dynamic>> _getModules(IndustryConfig cfg) {
    // Common modules
    final modules = <Map<String, dynamic>>[
      {'icon': Icons.point_of_sale, 'title': cfg.posLabel, 'sub': 'Fast billing & cart'},
      {'icon': Icons.inventory_2, 'title': '${cfg.productLabel} Catalog', 'sub': 'Add & manage ${cfg.productLabel.toLowerCase()}s'},
      {'icon': Icons.receipt_long, 'title': cfg.invoiceLabel, 'sub': 'GST tax invoices'},
      {'icon': Icons.people, 'title': '${cfg.customerLabel} Master', 'sub': 'Manage ${cfg.customerLabel.toLowerCase()}s'},
      {'icon': Icons.local_shipping, 'title': cfg.supplierLabel, 'sub': 'Purchase & supply'},
      {'icon': Icons.analytics, 'title': 'Reports', 'sub': 'Sales & ${cfg.stockLabel.toLowerCase()} reports'},
    ];

    // Industry-specific extras
    if (cfg.showPrescription) {
      modules.add({'icon': Icons.medical_services, 'title': 'Prescription Mgmt', 'sub': 'e-Rx & doctor records'});
    }
    if (cfg.showExpiryTracking) {
      modules.add({'icon': Icons.warning_amber, 'title': 'Expiry Tracking', 'sub': 'FEFO & near-expiry alerts'});
    }
    if (cfg.showScheduleType) {
      modules.add({'icon': Icons.security, 'title': 'Schedule H/H1', 'sub': 'Controlled drug register'});
    }
    if (cfg.showRefillReminders) {
      modules.add({'icon': Icons.notifications_active, 'title': 'Refill Reminders', 'sub': 'Monthly patient alerts'});
    }
    if (cfg.showManufacturing) {
      modules.add({'icon': Icons.precision_manufacturing, 'title': 'Production Orders', 'sub': 'BOM & work orders'});
      modules.add({'icon': Icons.science, 'title': 'Raw Materials', 'sub': 'Input material tracking'});
    }
    if (cfg.showTableManagement) {
      modules.add({'icon': Icons.table_restaurant, 'title': 'Table Management', 'sub': 'Dine-in & KOT orders'});
      modules.add({'icon': Icons.delivery_dining, 'title': 'Delivery Orders', 'sub': 'Swiggy / Zomato orders'});
    }
    if (cfg.showRecipe) {
      modules.add({'icon': Icons.menu_book, 'title': 'Recipe / Menu', 'sub': 'Dish costing & menu'});
    }
    if (cfg.showWholesale) {
      modules.add({'icon': Icons.price_change, 'title': 'Tier Pricing', 'sub': 'Retail/wholesale/dist.'});
    }
    if (cfg.showWeightVolume) {
      modules.add({'icon': Icons.scale, 'title': 'Weight / Volume', 'sub': 'UOM conversions'});
    }

    return modules;
  }
}
