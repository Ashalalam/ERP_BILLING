import 'package:flutter/material.dart';

/// Defines per-industry configuration — terminology, features, product categories,
/// tax labels, and UI adaptations for each of the 6 operating modes.
class IndustryConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  // Terminology
  final String productLabel;       // "Medicine" / "Product" / "Item" / "Dish"
  final String customerLabel;      // "Patient" / "Customer" / "Client" / "Guest"
  final String invoiceLabel;       // "Tax Invoice" / "Bill" / "Receipt" / "Order"
  final String batchLabel;         // "Batch" / "Lot" / "SKU" / "Variant"
  final String stockLabel;         // "Stock" / "Inventory" / "Raw Material"
  final String supplierLabel;      // "Supplier" / "Vendor" / "Distributor"
  final String posLabel;           // "Fast POS" / "Billing Counter" / "Table Order"

  // Feature flags
  final bool showExpiryTracking;
  final bool showScheduleType;     // Schedule H/H1/Narcotics — Pharma only
  final bool showPrescription;     // Prescription linkage — Pharma only
  final bool showBatchTracking;
  final bool showGstInvoice;
  final bool showManufacturing;    // BOM/production orders — Manufacturing only
  final bool showTableManagement;  // Tables/KOT — Restaurant only
  final bool showRecipe;           // Recipes — Restaurant only
  final bool showWholesale;        // Wholesale/distributor pricing
  final bool showRefillReminders;  // Chronic refills — Pharma only
  final bool showHsnCode;
  final bool showWeightVolume;     // Weight/volume units — FMCG/Manufacturing

  // Product categories for this industry
  final List<String> productCategories;

  // GST/tax label
  final String taxLabel;           // "GST" / "VAT" / "Service Tax"

  // Schedule types (Pharma) or product types (others)
  final List<String> itemTypes;

  // Units of measure
  final List<String> units;

  const IndustryConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.productLabel,
    required this.customerLabel,
    required this.invoiceLabel,
    required this.batchLabel,
    required this.stockLabel,
    required this.supplierLabel,
    required this.posLabel,
    required this.showExpiryTracking,
    required this.showScheduleType,
    required this.showPrescription,
    required this.showBatchTracking,
    required this.showGstInvoice,
    required this.showManufacturing,
    required this.showTableManagement,
    required this.showRecipe,
    required this.showWholesale,
    required this.showRefillReminders,
    required this.showHsnCode,
    required this.showWeightVolume,
    required this.productCategories,
    required this.taxLabel,
    required this.itemTypes,
    required this.units,
  });

  // ── All 6 industry configs ───────────────────────────────────────────────

  static const Map<String, IndustryConfig> all = {
    'Pharma': IndustryConfig(
      id: 'Pharma',
      name: 'Pharma',
      description: 'Pharmaceutical & Medical Store',
      icon: Icons.local_pharmacy,
      color: Color(0xFF0F52BA),
      productLabel: 'Medicine',
      customerLabel: 'Patient',
      invoiceLabel: 'Tax Invoice',
      batchLabel: 'Batch',
      stockLabel: 'Stock',
      supplierLabel: 'Pharma Distributor',
      posLabel: 'Fast POS Billing',
      showExpiryTracking: true,
      showScheduleType: true,
      showPrescription: true,
      showBatchTracking: true,
      showGstInvoice: true,
      showManufacturing: false,
      showTableManagement: false,
      showRecipe: false,
      showWholesale: true,
      showRefillReminders: true,
      showHsnCode: true,
      showWeightVolume: false,
      productCategories: [
        'Tablet / Capsule',
        'Syrup / Liquid',
        'Injection / IV',
        'Topical / Ointment',
        'Surgical / Devices',
        'Vitamins / Supplements',
        'Ayurvedic / Herbal',
        'Narcotics / Controlled',
      ],
      taxLabel: 'GST',
      itemTypes: ['OTC', 'Schedule H', 'Schedule H1', 'Narcotics'],
      units: ['Strip', 'Bottle', 'Vial', 'Tube', 'Sachet', 'Box', 'Ampoule'],
    ),

    'Retail': IndustryConfig(
      id: 'Retail',
      name: 'Retail',
      description: 'General Retail & Supermarket',
      icon: Icons.storefront,
      color: Color(0xFF2E7D32),
      productLabel: 'Product',
      customerLabel: 'Customer',
      invoiceLabel: 'Tax Invoice',
      batchLabel: 'Lot',
      stockLabel: 'Inventory',
      supplierLabel: 'Supplier',
      posLabel: 'POS Billing',
      showExpiryTracking: true,
      showScheduleType: false,
      showPrescription: false,
      showBatchTracking: true,
      showGstInvoice: true,
      showManufacturing: false,
      showTableManagement: false,
      showRecipe: false,
      showWholesale: false,
      showRefillReminders: false,
      showHsnCode: true,
      showWeightVolume: true,
      productCategories: [
        'Grocery / Food',
        'Beverages',
        'Personal Care',
        'Household Items',
        'Electronics',
        'Clothing & Apparel',
        'Stationery',
        'Toys & Games',
      ],
      taxLabel: 'GST',
      itemTypes: ['General', 'Food', 'Non-Food', 'Taxable', 'Exempt'],
      units: ['Pcs', 'Kg', 'Litre', 'Box', 'Pack', 'Dozen', 'Bag'],
    ),

    'Wholesale/distribution': IndustryConfig(
      id: 'Wholesale/distribution',
      name: 'Wholesale / Distribution',
      description: 'B2B Wholesale & Distribution',
      icon: Icons.local_shipping,
      color: Color(0xFF1565C0),
      productLabel: 'Product',
      customerLabel: 'Dealer / Retailer',
      invoiceLabel: 'Tax Invoice',
      batchLabel: 'Lot',
      stockLabel: 'Inventory',
      supplierLabel: 'Manufacturer',
      posLabel: 'Order Billing',
      showExpiryTracking: true,
      showScheduleType: false,
      showPrescription: false,
      showBatchTracking: true,
      showGstInvoice: true,
      showManufacturing: false,
      showTableManagement: false,
      showRecipe: false,
      showWholesale: true,
      showRefillReminders: false,
      showHsnCode: true,
      showWeightVolume: true,
      productCategories: [
        'Consumer Goods',
        'Industrial Supplies',
        'Raw Materials',
        'Chemicals',
        'Textiles',
        'Electronics',
        'Agricultural',
        'Building Materials',
      ],
      taxLabel: 'GST',
      itemTypes: ['Standard', 'Bulk', 'Perishable', 'Fragile', 'Hazardous'],
      units: ['Carton', 'Pallet', 'Kg', 'Litre', 'Box', 'Drum', 'Ton'],
    ),

    'FMCG': IndustryConfig(
      id: 'FMCG',
      name: 'FMCG',
      description: 'Fast Moving Consumer Goods',
      icon: Icons.shopping_basket,
      color: Color(0xFFE65100),
      productLabel: 'SKU',
      customerLabel: 'Retailer',
      invoiceLabel: 'Delivery Invoice',
      batchLabel: 'Batch',
      stockLabel: 'Stock',
      supplierLabel: 'Vendor',
      posLabel: 'Van Sales / Billing',
      showExpiryTracking: true,
      showScheduleType: false,
      showPrescription: false,
      showBatchTracking: true,
      showGstInvoice: true,
      showManufacturing: false,
      showTableManagement: false,
      showRecipe: false,
      showWholesale: true,
      showRefillReminders: false,
      showHsnCode: true,
      showWeightVolume: true,
      productCategories: [
        'Food & Snacks',
        'Beverages',
        'Dairy Products',
        'Personal Hygiene',
        'Home Care',
        'Baby Products',
        'Pet Food',
        'Confectionery',
      ],
      taxLabel: 'GST',
      itemTypes: ['Perishable', 'Non-Perishable', 'Frozen', 'Chilled', 'Ambient'],
      units: ['Pcs', 'Kg', 'Gram', 'Litre', 'ML', 'Box', 'Case', 'Pouch'],
    ),

    'Manufacturing': IndustryConfig(
      id: 'Manufacturing',
      name: 'Manufacturing',
      description: 'Production & Manufacturing',
      icon: Icons.precision_manufacturing,
      color: Color(0xFF4527A0),
      productLabel: 'Finished Good',
      customerLabel: 'Client',
      invoiceLabel: 'Sales Invoice',
      batchLabel: 'Production Lot',
      stockLabel: 'Raw Material / WIP',
      supplierLabel: 'Raw Material Supplier',
      posLabel: 'Production Billing',
      showExpiryTracking: true,
      showScheduleType: false,
      showPrescription: false,
      showBatchTracking: true,
      showGstInvoice: true,
      showManufacturing: true,
      showTableManagement: false,
      showRecipe: false,
      showWholesale: true,
      showRefillReminders: false,
      showHsnCode: true,
      showWeightVolume: true,
      productCategories: [
        'Finished Goods',
        'Semi-Finished / WIP',
        'Raw Materials',
        'Packaging Materials',
        'Spare Parts',
        'Tools & Equipment',
        'Chemicals',
        'By-Products',
      ],
      taxLabel: 'GST',
      itemTypes: ['Finished Good', 'WIP', 'Raw Material', 'Consumable', 'Asset'],
      units: ['Pcs', 'Kg', 'Litre', 'Metre', 'Ton', 'Roll', 'Set', 'Unit'],
    ),

    'Restaurant': IndustryConfig(
      id: 'Restaurant',
      name: 'Restaurant',
      description: 'Food Service & Restaurant',
      icon: Icons.restaurant,
      color: Color(0xFFC62828),
      productLabel: 'Dish / Item',
      customerLabel: 'Guest / Diner',
      invoiceLabel: 'Bill / Receipt',
      batchLabel: 'Portion',
      stockLabel: 'Ingredients',
      supplierLabel: 'Food Vendor',
      posLabel: 'Table / Counter Billing',
      showExpiryTracking: false,
      showScheduleType: false,
      showPrescription: false,
      showBatchTracking: false,
      showGstInvoice: true,
      showManufacturing: false,
      showTableManagement: true,
      showRecipe: true,
      showWholesale: false,
      showRefillReminders: false,
      showHsnCode: false,
      showWeightVolume: true,
      productCategories: [
        'Starters / Appetizers',
        'Main Course',
        'Breads & Rice',
        'Desserts',
        'Beverages / Drinks',
        'Combos / Meals',
        'Soups & Salads',
        'Specials',
      ],
      taxLabel: 'GST / Service Charge',
      itemTypes: ['Veg', 'Non-Veg', 'Vegan', 'Jain', 'Beverage', 'Combo'],
      units: ['Plate', 'Half', 'Full', 'Glass', 'Bowl', 'Piece', 'Portion'],
    ),
  };

  static IndustryConfig get(String id) =>
      all[id] ?? all['Pharma']!;
}

/// Global industry state — singleton accessed anywhere in the app
class IndustryState extends ChangeNotifier {
  static final IndustryState instance = IndustryState._();
  IndustryState._();

  String _activeIndustry = 'Pharma';

  String get activeId => _activeIndustry;
  IndustryConfig get config => IndustryConfig.get(_activeIndustry);

  void setIndustry(String id) {
    if (_activeIndustry == id) return;
    _activeIndustry = id;
    notifyListeners();
  }
}
