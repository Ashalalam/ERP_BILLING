import 'package:flutter/material.dart';
import '../core/utils/industry_config.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/billing/fast_pos_view.dart';
import '../views/billing/sales_return_view.dart';
import '../views/inventory/inventory_view.dart';
import '../views/purchase/purchase_entry_view.dart';
import '../views/accounting/accounting_view.dart';
import '../views/gst_tax/gst_tax_view.dart';
import '../views/regulatory/regulatory_view.dart';
import '../views/customer/customer_patient_view.dart';
import '../views/business/business_mgmt_view.dart';
import '../views/industry/industry_view.dart';
import '../views/branch/chain_store_view.dart';
import '../views/reports/reports_view.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  final _industry = IndustryState.instance;

  final List<Widget> _views = const [
    DashboardView(),
    FastPosView(),
    SalesReturnView(),
    InventoryView(),
    PurchaseEntryViewWrapper(),
    AccountingView(),
    GstTaxView(),
    RegulatoryView(),
    CustomerPatientView(),
    BusinessMgmtView(),
    IndustryView(),
    ChainStoreView(),
    ReportsView(),
  ];

  @override
  void initState() {
    super.initState();
    // Rebuild nav when industry changes
    _industry.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _industry.removeListener(() => setState(() {}));
    super.dispose();
  }

  /// Nav labels adapt to active industry terminology
  List<_NavItem> get _navItems {
    final cfg = _industry.config;
    return [
      _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      _NavItem(Icons.point_of_sale_outlined, Icons.point_of_sale, cfg.posLabel.split(' ').first),
      _NavItem(Icons.assignment_return_outlined, Icons.assignment_return, 'Returns'),
      _NavItem(Icons.inventory_2_outlined, Icons.inventory_2, cfg.productLabel == 'Dish / Item' ? 'Menu' : 'Inventory'),
      _NavItem(Icons.add_shopping_cart_outlined, Icons.add_shopping_cart, 'Purchase'),
      _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Accounting'),
      _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, cfg.taxLabel.split('/').first.trim()),
      // Regulatory tab only shows for Pharma
      if (cfg.showScheduleType)
        _NavItem(Icons.security_outlined, Icons.security, 'Regulatory'),
      _NavItem(Icons.people_alt_outlined, Icons.people_alt, cfg.customerLabel.split('/').first),
      _NavItem(Icons.business_outlined, Icons.business, 'Business'),
      _NavItem(Icons.category_outlined, Icons.category, 'Industry'),
      _NavItem(Icons.store_outlined, Icons.store, 'Chain Sync'),
      _NavItem(Icons.analytics_outlined, Icons.analytics, 'Reports'),
    ];
  }

  /// Page index adjusted when Regulatory is hidden for non-Pharma
  List<Widget> get _activeViews {
    final cfg = _industry.config;
    if (!cfg.showScheduleType) {
      // Remove Regulatory view (index 7)
      final views = [..._views];
      views.removeAt(7);
      return views;
    }
    return _views;
  }

  String get _pageTitle {
    final cfg = _industry.config;
    final titles = [
      'Dashboard',
      cfg.posLabel,
      'Sales Returns',
      cfg.productLabel == 'Dish / Item' ? 'Menu & Inventory' : 'Inventory & ${cfg.batchLabel} Tracking',
      'Purchase Entry',
      'Accounting & Ledger',
      '${cfg.taxLabel} Compliance',
      if (cfg.showScheduleType) 'Regulatory & Drug Registers',
      '${cfg.customerLabel} Management',
      'Business Management',
      'Industry Mode',
      'Chain Store Sync',
      'Reports & Analytics',
    ];
    if (_selectedIndex < titles.length) return titles[_selectedIndex];
    return 'ERP';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    final cfg = _industry.config;
    final navItems = _navItems;
    final views = _activeViews;

    // Clamp index if nav items changed (e.g. Regulatory removed)
    final safeIndex = _selectedIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Industry mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cfg.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cfg.icon, size: 14, color: cfg.color),
                  const SizedBox(width: 4),
                  Text(cfg.name,
                      style: TextStyle(
                          fontSize: 11,
                          color: cfg.color,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(_pageTitle),
          ],
        ),
        actions: [
          // Notification bell with expiry alert count (Pharma)
          if (cfg.showExpiryTracking)
            _ExpiryAlertBell(industryColor: cfg.color),
          const SizedBox(width: 4),
          // User profile menu
          PopupMenuButton<dynamic>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cfg.color,
                    radius: 16,
                    child: Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName.split(' ').first ?? 'User',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(user?.roleName ?? '',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(user?.roleName ?? '',
                        style: TextStyle(fontSize: 11, color: cfg.color)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () => setState(() => _selectedIndex = navItems.indexWhere((n) => n.label == 'Industry')),
                child: ListTile(
                  leading: Icon(cfg.icon, color: cfg.color),
                  title: Text('${cfg.name} Mode Active'),
                  subtitle: const Text('Tap to switch industry'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async {
                  await auth.logout();
                  if (mounted) setState(() {});
                },
                child: const ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────────────────
          SizedBox(
            width: 88,
            child: SingleChildScrollView(
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.selected,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/lifesprout_logo.jpg',
                            height: 32,
                            width: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('BillSprout', style: TextStyle(fontSize: 8, color: cfg.color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  selectedIconTheme: IconThemeData(color: cfg.color),
                  selectedLabelTextStyle: TextStyle(
                      color: cfg.color, fontWeight: FontWeight.bold, fontSize: 10),
                  destinations: navItems
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon, size: 22),
                            selectedIcon: Icon(item.selectedIcon, size: 22),
                            label: Text(item.label,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: safeIndex < views.length
                ? views[safeIndex]
                : const Center(child: Text('Select a module')),
          ),
        ],
      ),
    );
  }
}

// ── Nav item model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

// ── Expiry alert bell ────────────────────────────────────────────────────────

class _ExpiryAlertBell extends StatelessWidget {
  final Color industryColor;
  const _ExpiryAlertBell({required this.industryColor});

  @override
  Widget build(BuildContext context) {
    final db = SupabaseService.instance;
    final now = DateTime.now();
    final alertCount = db.batches
            .where((b) =>
                b.expiryDate.isAfter(now) &&
                b.expiryDate
                    .isBefore(now.add(const Duration(days: 30))))
            .length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(alertCount > 0
                    ? '$alertCount batch(es) expiring within 30 days!'
                    : 'No expiry alerts.'),
                backgroundColor:
                    alertCount > 0 ? Colors.orange : Colors.green,
              ),
            );
          },
        ),
        if (alertCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text('$alertCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

// ── PurchaseEntryView wrapper ────────────────────────────────────────────────

class PurchaseEntryViewWrapper extends StatelessWidget {
  const PurchaseEntryViewWrapper({super.key});

  @override
  Widget build(BuildContext context) => const PurchaseEntryView();
}
