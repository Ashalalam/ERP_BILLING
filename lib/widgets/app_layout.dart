import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

  final List<String> _titles = const [
    'Dashboard',
    'Fast POS & Billing',
    'Sales Returns',
    'Inventory & Expiry',
    'Purchase Entry',
    'Accounting & Ledger',
    'GST & Tax',
    'Regulatory',
    'Customers & Patients',
    'Business Management',
    'Industry',
    'Chain Store Sync',
    'Reports & Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts up-to-date.')),
              );
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<dynamic>(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F52BA),
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(user?.roleName ?? 'User',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?.fullName ?? 'User'),
                  subtitle: Text(user?.email ?? ''),
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
                  title: Text('Sign Out',
                      style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.selected,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.local_pharmacy,
                  color: Color(0xFF0F52BA), size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard')),
              NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('POS Billing')),
              NavigationRailDestination(
                  icon: Icon(Icons.assignment_return_outlined),
                  selectedIcon: Icon(Icons.assignment_return),
                  label: Text('Returns')),
              NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Inventory')),
              NavigationRailDestination(
                  icon: Icon(Icons.add_shopping_cart_outlined),
                  selectedIcon: Icon(Icons.add_shopping_cart),
                  label: Text('Purchase')),
              NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Accounting')),
              NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('GST Tax')),
              NavigationRailDestination(
                  icon: Icon(Icons.security_outlined),
                  selectedIcon: Icon(Icons.security),
                  label: Text('Regulatory')),
              NavigationRailDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: Text('Patients')),
              NavigationRailDestination(
                  icon: Icon(Icons.business_outlined),
                  selectedIcon: Icon(Icons.business),
                  label: Text('Business')),
              NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text('Industry')),
              NavigationRailDestination(
                  icon: Icon(Icons.store_outlined),
                  selectedIcon: Icon(Icons.store),
                  label: Text('Chain Sync')),
              NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Reports')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }
}

/// Wraps PurchaseEntryView as a full page within the nav rail layout.
class PurchaseEntryViewWrapper extends StatelessWidget {
  const PurchaseEntryViewWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const PurchaseEntryView();
  }
}
