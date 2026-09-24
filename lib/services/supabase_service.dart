import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/models.dart';
import '../core/utils/fefo_selector.dart';

/// Central Database Service — backed by Supabase PostgreSQL.
/// Falls back to in-memory demo data when Supabase is not yet configured.
class SupabaseService extends ChangeNotifier {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  // ── In-memory mirrors (populated from DB or seeded as demo) ─────────────
  final List<Company> _companies = [];
  final List<LocationGodown> _locations = [];
  final List<AppUser> _users = [];
  final List<Party> _parties = [];
  final List<PatientProfile> _patients = [];
  final List<Prescription> _prescriptions = [];
  final List<Product> _products = [];
  final List<Batch> _batches = [];
  final List<Invoice> _invoices = [];
  final List<InvoiceItem> _invoiceItems = [];
  final List<CreditNote> _creditNotes = [];
  final List<DebitNote> _debitNotes = [];
  final List<Payment> _payments = [];
  final List<Account> _accounts = [];
  final List<LedgerEntry> _ledgerEntries = [];
  final List<BankReconciliation> _bankReconciliations = [];
  final List<RestrictedDrugLog> _restrictedLogs = [];
  final List<AuditLog> _auditLogs = [];
  final List<RtvNote> _rtvNotes = [];
  final List<PurchaseOrder> _purchaseOrders = [];
  final List<RefillReminder> _refillReminders = [];
  final List<Store> _stores = [];
  final List<StoreStockTransfer> _storeTransfers = [];
  final List<StockAdjustment> _stockAdjustments = [];

  Company? _activeCompany;
  Company? get activeCompany => _activeCompany;

  // ── Public getters ───────────────────────────────────────────────────────
  List<Company> get companies => List.unmodifiable(_companies);
  List<Product> get products => List.unmodifiable(_products);
  List<Batch> get batches => List.unmodifiable(_batches);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<InvoiceItem> get invoiceItems => List.unmodifiable(_invoiceItems);
  List<Party> get parties => List.unmodifiable(_parties);
  List<PatientProfile> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<LedgerEntry> get ledgerEntries => List.unmodifiable(_ledgerEntries);
  List<RestrictedDrugLog> get restrictedLogs => List.unmodifiable(_restrictedLogs);
  List<AuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  List<RtvNote> get rtvNotes => List.unmodifiable(_rtvNotes);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  List<RefillReminder> get refillReminders => List.unmodifiable(_refillReminders);
  List<Store> get stores => List.unmodifiable(_stores);
  List<StoreStockTransfer> get storeTransfers => List.unmodifiable(_storeTransfers);
  List<CreditNote> get creditNotes => List.unmodifiable(_creditNotes);
  List<DebitNote> get debitNotes => List.unmodifiable(_debitNotes);
  List<StockAdjustment> get stockAdjustments => List.unmodifiable(_stockAdjustments);
  List<AppUser> get users => List.unmodifiable(_users);

  void setActiveCompany(Company company) {
    _activeCompany = company;
    notifyListeners();
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Call once at app startup. Tries to load from Supabase; falls back to demo.
  Future<void> initialize() async {
    try {
      await _loadFromSupabase();
    } catch (e) {
      debugPrint('Supabase load failed ($e). Using demo data.');
      _seedInitialDemoData();
    }
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final companiesData = await _client.from('companies').select();
    if ((companiesData as List).isEmpty) {
      _seedInitialDemoData();
      await _pushSeedToSupabase();
      return;
    }

    _companies.clear();
    for (final row in companiesData) {
      _companies.add(Company(
        id: row['id'],
        name: row['name'],
        gstin: row['gstin'],
        address: row['address'],
        phone: row['phone'],
        currency: row['currency'] ?? 'INR',
        financialYear: row['financial_year'] ?? '2026-2027',
        industryCategory: row['industry_category'] ?? 'Pharma',
        createdAt: DateTime.parse(row['created_at']),
      ));
    }
    if (_companies.isNotEmpty) _activeCompany = _companies.first;

    await Future.wait([
      _loadProducts(),
      _loadBatches(),
      _loadParties(),
      _loadPatients(),
      _loadPrescriptions(),
      _loadInvoices(),
      _loadAccounts(),
      _loadLedgerEntries(),
      _loadRestrictedLogs(),
      _loadAuditLogs(),
      _loadRtvNotes(),
      _loadPurchaseOrders(),
      _loadRefillReminders(),
      _loadStores(),
      _loadStoreTransfers(),
    ]);
  }

  Future<void> _loadProducts() async {
    final data = await _client.from('products').select();
    _products.clear();
    for (final r in data as List) {
      _products.add(Product(
        id: r['id'],
        companyId: r['company_id'],
        name: r['name'],
        genericName: r['generic_name'],
        hsnCode: r['hsn_code'] ?? '',
        gstRate: (r['gst_rate'] as num).toDouble(),
        scheduleType: r['schedule_type'] ?? 'OTC',
        reorderLevel: r['reorder_level'] ?? 10,
        rack: r['rack'],
        shelf: r['shelf'],
        barcode: r['barcode'],
        manufacturer: r['manufacturer'],
        category: r['category'],
        unit: r['unit'],
        packSize: r['pack_size'],
      ));
    }
  }

  Future<void> _loadBatches() async {
    final data = await _client.from('batches').select();
    _batches.clear();
    for (final r in data as List) {
      _batches.add(Batch(
        id: r['id'],
        productId: r['product_id'],
        locationId: r['location_id'],
        batchNumber: r['batch_number'],
        mfgDate: DateTime.parse(r['mfg_date']),
        expiryDate: DateTime.parse(r['expiry_date']),
        retailPrice: (r['retail_price'] as num).toDouble(),
        wholesalePrice: (r['wholesale_price'] as num).toDouble(),
        distributorPrice: (r['distributor_price'] as num).toDouble(),
        loyaltyPrice: (r['loyalty_price'] as num).toDouble(),
        purchasePrice: (r['purchase_price'] as num).toDouble(),
        currentStock: r['current_stock'] ?? 0,
      ));
    }
  }

  Future<void> _loadParties() async {
    final data = await _client.from('parties').select();
    _parties.clear();
    for (final r in data as List) {
      _parties.add(Party(
        id: r['id'],
        companyId: r['company_id'],
        name: r['name'],
        partyType: r['party_type'],
        gstin: r['gstin'],
        phone: r['phone'],
        email: r['email'],
        address: r['address'],
        pricingTier: r['pricing_tier'] ?? 'retail',
      ));
    }
  }

  Future<void> _loadPatients() async {
    final data = await _client.from('patient_profiles').select();
    _patients.clear();
    for (final r in data as List) {
      _patients.add(PatientProfile(
        id: r['id'],
        partyId: r['party_id'],
        patientName: r['patient_name'],
        age: r['age'],
        gender: r['gender'],
        knownAllergies: List<String>.from(r['known_allergies'] ?? []),
        chronicRefillNotes: r['chronic_refill_notes'],
        prescriptionImageUrl: r['prescription_image_url'],
      ));
    }
  }

  Future<void> _loadPrescriptions() async {
    final data = await _client.from('prescriptions').select();
    _prescriptions.clear();
    for (final r in data as List) {
      _prescriptions.add(Prescription(
        id: r['id'],
        patientId: r['patient_id'],
        doctorName: r['doctor_name'],
        doctorLicense: r['doctor_license'],
        rxNumber: r['rx_number'],
        rxDetails: r['rx_details'],
      ));
    }
  }

  Future<void> _loadInvoices() async {
    final data = await _client.from('invoices').select();
    _invoices.clear();
    for (final r in data as List) {
      _invoices.add(Invoice(
        id: r['id'],
        companyId: r['company_id'],
        locationId: r['location_id'],
        invoiceNumber: r['invoice_number'],
        partyId: r['party_id'],
        prescriptionId: r['prescription_id'],
        invoiceType: r['invoice_type'] ?? 'sales',
        paymentMethod: r['payment_method'] ?? 'cash',
        subtotal: (r['subtotal'] as num).toDouble(),
        taxAmount: (r['tax_amount'] as num).toDouble(),
        totalAmount: (r['total_amount'] as num).toDouble(),
        eInvoiceIrn: r['e_invoice_irn'],
        pharmacistApproved: r['pharmacist_approved'] ?? false,
        createdAt: DateTime.parse(r['created_at']),
        cashAmount: (r['cash_amount'] as num?)?.toDouble(),
        cardAmount: (r['card_amount'] as num?)?.toDouble(),
        upiAmount: (r['upi_amount'] as num?)?.toDouble(),
        isCancelled: r['is_cancelled'] ?? false,
        cancelReason: r['cancel_reason'],
      ));
    }
    final itemData = await _client.from('invoice_items').select();
    _invoiceItems.clear();
    for (final r in itemData as List) {
      _invoiceItems.add(InvoiceItem(
        id: r['id'],
        invoiceId: r['invoice_id'],
        productId: r['product_id'],
        batchId: r['batch_id'],
        productName: r['product_name'],
        quantity: r['quantity'],
        unitPrice: (r['unit_price'] as num).toDouble(),
        taxAmount: (r['tax_amount'] as num).toDouble(),
        totalPrice: (r['total_price'] as num).toDouble(),
        discountPercent: (r['discount_percent'] as num?)?.toDouble() ?? 0.0,
      ));
    }
  }

  Future<void> _loadAccounts() async {
    final data = await _client.from('accounts').select();
    _accounts.clear();
    for (final r in data as List) {
      _accounts.add(Account(
        id: r['id'],
        companyId: r['company_id'],
        name: r['name'],
        type: r['type'],
        balance: (r['balance'] as num).toDouble(),
      ));
    }
  }

  Future<void> _loadLedgerEntries() async {
    final data = await _client.from('ledger_entries').select();
    _ledgerEntries.clear();
    for (final r in data as List) {
      _ledgerEntries.add(LedgerEntry(
        id: r['id'],
        accountId: r['account_id'],
        description: r['description'],
        debit: (r['debit'] as num).toDouble(),
        credit: (r['credit'] as num).toDouble(),
        createdAt: DateTime.parse(r['created_at']),
      ));
    }
  }

  Future<void> _loadRestrictedLogs() async {
    final data = await _client.from('restricted_drug_logs').select();
    _restrictedLogs.clear();
    for (final r in data as List) {
      _restrictedLogs.add(RestrictedDrugLog(
        id: r['id'],
        companyId: r['company_id'],
        invoiceId: r['invoice_id'],
        productId: r['product_id'],
        batchId: r['batch_id'],
        scheduleType: r['schedule_type'],
        patientName: r['patient_name'],
        doctorName: r['doctor_name'],
        quantity: r['quantity'],
        createdAt: DateTime.parse(r['created_at']),
      ));
    }
  }

  Future<void> _loadAuditLogs() async {
    final data = await _client.from('audit_logs').select().order('created_at', ascending: false).limit(200);
    _auditLogs.clear();
    for (final r in data as List) {
      _auditLogs.add(AuditLog(
        id: r['id'],
        companyId: r['company_id'],
        userId: r['user_id'],
        action: r['action'],
        details: Map<String, dynamic>.from(r['details'] ?? {}),
        createdAt: DateTime.parse(r['created_at']),
      ));
    }
  }

  Future<void> _loadRtvNotes() async {
    final data = await _client.from('rtv_notes').select();
    _rtvNotes.clear();
    for (final r in data as List) {
      _rtvNotes.add(RtvNote(
        id: r['id'],
        companyId: r['company_id'],
        batchId: r['batch_id'],
        supplierId: r['supplier_id'],
        quantity: r['quantity'],
        status: r['status'] ?? 'draft',
      ));
    }
  }

  Future<void> _loadPurchaseOrders() async {
    final data = await _client.from('purchase_orders').select();
    _purchaseOrders.clear();
    for (final r in data as List) {
      _purchaseOrders.add(PurchaseOrder(
        id: r['id'],
        companyId: r['company_id'],
        supplierId: r['supplier_id'],
        productId: r['product_id'],
        quantity: r['quantity'],
        status: r['status'] ?? 'auto_generated',
      ));
    }
  }

  Future<void> _loadRefillReminders() async {
    final data = await _client.from('refill_reminders').select();
    _refillReminders.clear();
    for (final r in data as List) {
      _refillReminders.add(RefillReminder(
        id: r['id'],
        patientId: r['patient_id'],
        productId: r['product_id'],
        reminderDate: DateTime.parse(r['reminder_date']),
        status: r['status'] ?? 'pending',
      ));
    }
  }

  Future<void> _loadStores() async {
    final data = await _client.from('stores').select();
    _stores.clear();
    for (final r in data as List) {
      _stores.add(Store(
        id: r['id'],
        companyId: r['company_id'],
        name: r['name'],
        address: r['address'],
      ));
    }
  }

  Future<void> _loadStoreTransfers() async {
    final data = await _client.from('store_stock_transfers').select();
    _storeTransfers.clear();
    for (final r in data as List) {
      _storeTransfers.add(StoreStockTransfer(
        id: r['id'],
        fromStoreId: r['from_store_id'],
        toStoreId: r['to_store_id'],
        productId: r['product_id'],
        batchId: r['batch_id'],
        quantity: r['quantity'],
        status: r['status'] ?? 'completed',
      ));
    }
  }

  // ── Seed demo data then push to Supabase ─────────────────────────────────

  Future<void> _pushSeedToSupabase() async {
    try {
      for (final c in _companies) {
        await _client.from('companies').upsert(c.toJson());
      }
      for (final p in _products) {
        await _client.from('products').upsert(p.toJson());
      }
      for (final b in _batches) {
        await _client.from('batches').upsert(b.toJson());
      }
      for (final p in _parties) {
        await _client.from('parties').upsert(p.toJson());
      }
      for (final p in _patients) {
        await _client.from('patient_profiles').upsert(p.toJson());
      }
      for (final rx in _prescriptions) {
        await _client.from('prescriptions').upsert(rx.toJson());
      }
      for (final a in _accounts) {
        await _client.from('accounts').upsert(a.toJson());
      }
      for (final le in _ledgerEntries) {
        await _client.from('ledger_entries').upsert(le.toJson());
      }
      for (final s in _stores) {
        await _client.from('stores').upsert(s.toJson());
      }
    } catch (e) {
      debugPrint('Push seed to Supabase failed: $e');
    }
  }

  // ── Product CRUD ─────────────────────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    _products.add(product);
    _logAudit('PRODUCT_ADD', {'product_name': product.name});
    notifyListeners();
    try {
      await _client.from('products').insert(product.toJson());
    } catch (e) {
      debugPrint('addProduct DB error: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) _products[idx] = product;
    _logAudit('PRODUCT_UPDATE', {'product_name': product.name});
    notifyListeners();
    try {
      await _client.from('products').update(product.toJson()).eq('id', product.id);
    } catch (e) {
      debugPrint('updateProduct DB error: $e');
    }
  }

  // ── Batch CRUD ───────────────────────────────────────────────────────────

  Future<void> addBatch(Batch batch) async {
    _batches.add(batch);
    _logAudit('BATCH_ADD', {'batch_number': batch.batchNumber, 'stock': batch.currentStock});
    notifyListeners();
    try {
      await _client.from('batches').insert(batch.toJson());
    } catch (e) {
      debugPrint('addBatch DB error: $e');
    }
  }

  Future<void> updateBatchStock(String batchId, int newStock) async {
    final b = _batches.firstWhere((b) => b.id == batchId);
    b.currentStock = newStock;
    notifyListeners();
    try {
      await _client.from('batches').update({'current_stock': newStock}).eq('id', batchId);
    } catch (e) {
      debugPrint('updateBatchStock DB error: $e');
    }
  }

  // ── User CRUD ────────────────────────────────────────────────────────────

  Future<void> addUser(AppUser user) async {
    _users.add(user);
    _logAudit('USER_ADD', {'email': user.email, 'role': user.roleName});
    notifyListeners();
    try {
      await _client.from('app_users').insert(user.toJson());
    } catch (e) {
      debugPrint('addUser DB error: $e');
    }
  }

  Future<void> updateUser(AppUser user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) _users[idx] = user;
    _logAudit('USER_UPDATE', {'email': user.email, 'role': user.roleName});
    notifyListeners();
    try {
      await _client.from('app_users').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      debugPrint('updateUser DB error: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    _logAudit('USER_DELETE', {'user_id': userId});
    notifyListeners();
    try {
      await _client.from('app_users').delete().eq('id', userId);
    } catch (e) {
      debugPrint('deleteUser DB error: $e');
    }
  }

  // ── Party CRUD ───────────────────────────────────────────────────────────

  Future<void> addParty(Party party) async {
    _parties.add(party);
    _logAudit('PARTY_ADD', {'name': party.name, 'type': party.partyType});
    notifyListeners();
    try {
      await _client.from('parties').insert(party.toJson());
    } catch (e) {
      debugPrint('addParty DB error: $e');
    }
  }

  Future<void> updateParty(Party party) async {
    final idx = _parties.indexWhere((p) => p.id == party.id);
    if (idx >= 0) _parties[idx] = party;
    notifyListeners();
    try {
      await _client.from('parties').update(party.toJson()).eq('id', party.id);
    } catch (e) {
      debugPrint('updateParty DB error: $e');
    }
  }

  // ── Patient CRUD ─────────────────────────────────────────────────────────

  Future<void> addPatient(PatientProfile patient) async {
    _patients.add(patient);
    notifyListeners();
    try {
      await _client.from('patient_profiles').insert(patient.toJson());
    } catch (e) {
      debugPrint('addPatient DB error: $e');
    }
  }

  Future<void> updatePatient(PatientProfile patient) async {
    final idx = _patients.indexWhere((p) => p.id == patient.id);
    if (idx >= 0) _patients[idx] = patient;
    notifyListeners();
    try {
      await _client.from('patient_profiles').update(patient.toJson()).eq('id', patient.id);
    } catch (e) {
      debugPrint('updatePatient DB error: $e');
    }
  }

  // ── Invoice creation ─────────────────────────────────────────────────────

  Future<Invoice> createInvoice({
    required String invoiceNumber,
    required String partyId,
    String? prescriptionId,
    required String invoiceType,
    required String paymentMethod,
    required List<Map<String, dynamic>> itemsData,
    required String patientName,
    required String doctorName,
    required bool pharmacistApproved,
    double cashAmount = 0,
    double cardAmount = 0,
    double upiAmount = 0,
  }) async {
    double subtotal = 0.0;
    double totalTax = 0.0;
    final String compId = _activeCompany?.id ?? '';

    // Build a temporary invoice ID for item linkage
    final tempInvoice = Invoice(
      companyId: compId,
      invoiceNumber: invoiceNumber,
      partyId: partyId,
      prescriptionId: prescriptionId,
      invoiceType: invoiceType,
      paymentMethod: paymentMethod,
      subtotal: 0.0,
      taxAmount: 0.0,
      totalAmount: 0.0,
      pharmacistApproved: pharmacistApproved,
      cashAmount: cashAmount,
      cardAmount: cardAmount,
      upiAmount: upiAmount,
    );

    final List<InvoiceItem> createdItems = [];

    for (final itemMap in itemsData) {
      final Product prod = itemMap['product'];
      final Batch b = itemMap['batch'];
      final int qty = itemMap['qty'];
      final double price = itemMap['price'];
      final double discountPct = (itemMap['discount'] as double?) ?? 0.0;

      final discounted = price * (1 - discountPct / 100);
      final itemSubtotal = qty * discounted;
      final itemTax = itemSubtotal * (prod.gstRate / 100.0);
      final itemTotal = itemSubtotal + itemTax;

      subtotal += itemSubtotal;
      totalTax += itemTax;

      final invItem = InvoiceItem(
        invoiceId: tempInvoice.id,
        productId: prod.id,
        batchId: b.id,
        productName: prod.name,
        quantity: qty,
        unitPrice: discounted,
        taxAmount: itemTax,
        totalPrice: itemTotal,
        discountPercent: discountPct,
      );
      createdItems.add(invItem);

      // Stock adjustment
      if (invoiceType == 'sales') {
        b.currentStock = (b.currentStock - qty).clamp(0, 999999);
        await updateBatchStock(b.id, b.currentStock);
      } else {
        b.currentStock += qty;
        await updateBatchStock(b.id, b.currentStock);
      }

      // Restricted drug log
      if (prod.scheduleType != 'OTC') {
        final log = RestrictedDrugLog(
          companyId: compId,
          invoiceId: tempInvoice.id,
          productId: prod.id,
          batchId: b.id,
          scheduleType: prod.scheduleType,
          patientName: patientName,
          doctorName: doctorName,
          quantity: qty,
        );
        _restrictedLogs.add(log);
        try {
          await _client.from('restricted_drug_logs').insert(log.toJson());
        } catch (e) {
          debugPrint('restricted_drug_logs insert error: $e');
        }
      }
    }

    final double totalAmount = subtotal + totalTax;

    final finalInvoice = Invoice(
      id: tempInvoice.id,
      companyId: compId,
      invoiceNumber: invoiceNumber,
      partyId: partyId,
      prescriptionId: prescriptionId,
      invoiceType: invoiceType,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      taxAmount: totalTax,
      totalAmount: totalAmount,
      eInvoiceIrn: invoiceType == 'sales' ? 'IRN-${DateTime.now().millisecondsSinceEpoch}' : null,
      pharmacistApproved: pharmacistApproved,
      cashAmount: cashAmount,
      cardAmount: cardAmount,
      upiAmount: upiAmount,
    );

    _invoices.add(finalInvoice);
    _invoiceItems.addAll(createdItems);

    // Ledger posting
    final cashAcc = _accounts.firstWhere((a) => a.type == 'cash', orElse: () => _accounts.first);
    if (invoiceType == 'sales') {
      cashAcc.balance += totalAmount;
      final le = LedgerEntry(accountId: cashAcc.id, description: 'Sales Invoice #$invoiceNumber', debit: totalAmount);
      _ledgerEntries.add(le);
      try {
        await _client.from('ledger_entries').insert(le.toJson());
      } catch (e) { debugPrint('ledger insert error: $e'); }
    } else {
      cashAcc.balance -= totalAmount;
      final le = LedgerEntry(accountId: cashAcc.id, description: 'Purchase Invoice #$invoiceNumber', credit: totalAmount);
      _ledgerEntries.add(le);
      try {
        await _client.from('ledger_entries').insert(le.toJson());
      } catch (e) { debugPrint('ledger insert error: $e'); }
    }

    try {
      await _client.from('invoices').insert(finalInvoice.toJson());
      for (final item in createdItems) {
        await _client.from('invoice_items').insert(item.toJson());
      }
    } catch (e) {
      debugPrint('invoice insert DB error: $e');
    }

    _checkReorderAutomation();
    _logAudit('INVOICE_CREATE', {'invoice_number': invoiceNumber, 'total': totalAmount});
    notifyListeners();
    return finalInvoice;
  }

  // ── Invoice cancellation ─────────────────────────────────────────────────

  Future<void> cancelInvoice(String invoiceId, String reason) async {
    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx < 0) return;
    final inv = _invoices[idx];
    if (inv.isCancelled) return;

    // Reverse stock
    final items = _invoiceItems.where((i) => i.invoiceId == invoiceId).toList();
    for (final item in items) {
      final batchIdx = _batches.indexWhere((b) => b.id == item.batchId);
      if (batchIdx >= 0) {
        if (inv.invoiceType == 'sales') {
          _batches[batchIdx].currentStock += item.quantity;
          await updateBatchStock(_batches[batchIdx].id, _batches[batchIdx].currentStock);
        } else {
          _batches[batchIdx].currentStock = (_batches[batchIdx].currentStock - item.quantity).clamp(0, 999999);
          await updateBatchStock(_batches[batchIdx].id, _batches[batchIdx].currentStock);
        }
      }
    }

    // Reverse ledger
    final cashAcc = _accounts.firstWhere((a) => a.type == 'cash', orElse: () => _accounts.first);
    if (inv.invoiceType == 'sales') {
      cashAcc.balance -= inv.totalAmount;
      final le = LedgerEntry(accountId: cashAcc.id, description: 'CANCELLATION: Invoice #${inv.invoiceNumber}', credit: inv.totalAmount);
      _ledgerEntries.add(le);
      try { await _client.from('ledger_entries').insert(le.toJson()); } catch (_) {}
    } else {
      cashAcc.balance += inv.totalAmount;
      final le = LedgerEntry(accountId: cashAcc.id, description: 'CANCELLATION: Invoice #${inv.invoiceNumber}', debit: inv.totalAmount);
      _ledgerEntries.add(le);
      try { await _client.from('ledger_entries').insert(le.toJson()); } catch (_) {}
    }

    final cancelled = Invoice(
      id: inv.id, companyId: inv.companyId, invoiceNumber: inv.invoiceNumber,
      partyId: inv.partyId, prescriptionId: inv.prescriptionId,
      invoiceType: inv.invoiceType, paymentMethod: inv.paymentMethod,
      subtotal: inv.subtotal, taxAmount: inv.taxAmount, totalAmount: inv.totalAmount,
      eInvoiceIrn: inv.eInvoiceIrn, pharmacistApproved: inv.pharmacistApproved,
      createdAt: inv.createdAt, isCancelled: true, cancelReason: reason,
      cashAmount: inv.cashAmount, cardAmount: inv.cardAmount, upiAmount: inv.upiAmount,
    );
    _invoices[idx] = cancelled;

    try {
      await _client.from('invoices').update({'is_cancelled': true, 'cancel_reason': reason}).eq('id', invoiceId);
    } catch (e) { debugPrint('cancelInvoice DB error: $e'); }

    _logAudit('INVOICE_CANCEL', {'invoice_number': inv.invoiceNumber, 'reason': reason});
    notifyListeners();
  }

  // ── Sales Return (Credit Note) ───────────────────────────────────────────

  Future<void> createSalesReturn({
    required String originalInvoiceId,
    required String partyId,
    required String reason,
    required List<Map<String, dynamic>> returnItems,
  }) async {
    double totalReturn = 0.0;
    final compId = _activeCompany?.id ?? '';

    for (final item in returnItems) {
      final Batch b = item['batch'];
      final int qty = item['qty'];
      final double price = item['price'];
      final Product prod = item['product'];

      b.currentStock += qty;
      await updateBatchStock(b.id, b.currentStock);

      final itemTotal = qty * price * (1 + prod.gstRate / 100);
      totalReturn += itemTotal;
    }

    final cn = CreditNote(companyId: compId, partyId: partyId, amount: totalReturn, reason: reason);
    _creditNotes.add(cn);

    final cashAcc = _accounts.firstWhere((a) => a.type == 'cash', orElse: () => _accounts.first);
    cashAcc.balance -= totalReturn;
    final le = LedgerEntry(accountId: cashAcc.id, description: 'Sales Return: $reason', credit: totalReturn);
    _ledgerEntries.add(le);

    try {
      await _client.from('credit_notes').insert(cn.toJson());
      await _client.from('ledger_entries').insert(le.toJson());
    } catch (e) { debugPrint('sales return DB error: $e'); }

    _logAudit('SALES_RETURN', {'party_id': partyId, 'amount': totalReturn});
    notifyListeners();
  }

  // ── Stock Adjustment (damage / write-off / manual) ───────────────────────

  Future<void> addStockAdjustment(StockAdjustment adj) async {
    _stockAdjustments.add(adj);
    final batchIdx = _batches.indexWhere((b) => b.id == adj.batchId);
    if (batchIdx >= 0) {
      _batches[batchIdx].currentStock = (_batches[batchIdx].currentStock + adj.quantityChange).clamp(0, 999999);
      await updateBatchStock(_batches[batchIdx].id, _batches[batchIdx].currentStock);
    }
    _logAudit('STOCK_ADJUSTMENT', {'type': adj.adjustmentType, 'qty': adj.quantityChange});
    notifyListeners();
    try {
      await _client.from('stock_adjustments').insert(adj.toJson());
    } catch (e) { debugPrint('stock_adjustment DB error: $e'); }
  }

  // ── RTV ──────────────────────────────────────────────────────────────────

  int generateRtvDraftsForExpiredBatches() {
    final now = DateTime.now();
    final expired = FefoSelector.getExpiredBatches(_batches, now);
    int count = 0;
    for (final batch in expired) {
      final exists = _rtvNotes.any((r) => r.batchId == batch.id && r.status == 'draft');
      if (!exists && batch.currentStock > 0) {
        final note = RtvNote(
          companyId: _activeCompany?.id ?? '',
          batchId: batch.id,
          supplierId: _parties.firstWhere((p) => p.partyType == 'supplier', orElse: () => _parties.first).id,
          quantity: batch.currentStock,
          status: 'draft',
        );
        _rtvNotes.add(note);
        _client.from('rtv_notes').insert(note.toJson()).catchError((e) => debugPrint('rtv_notes insert error: $e'));
        count++;
      }
    }
    if (count > 0) {
      _logAudit('RTV_DRAFT_GENERATE', {'count': count});
      notifyListeners();
    }
    return count;
  }

  // ── Reorder automation ───────────────────────────────────────────────────

  void _checkReorderAutomation() {
    for (final prod in _products) {
      final totalStock = _batches.where((b) => b.productId == prod.id).fold(0, (sum, b) => sum + b.currentStock);
      if (totalStock <= prod.reorderLevel) {
        final existing = _purchaseOrders.any((po) => po.productId == prod.id && po.status == 'auto_generated');
        if (!existing) {
          final po = PurchaseOrder(
            companyId: _activeCompany?.id ?? '',
            supplierId: _parties.firstWhere((p) => p.partyType == 'supplier', orElse: () => _parties.first).id,
            productId: prod.id,
            quantity: prod.reorderLevel * 2,
            status: 'auto_generated',
          );
          _purchaseOrders.add(po);
          _client.from('purchase_orders').insert(po.toJson()).catchError((e) => debugPrint('po insert error: $e'));
        }
      }
    }
  }

  // ── Stock transfer ───────────────────────────────────────────────────────

  Future<void> transferStockBetweenStores(String fromStoreId, String toStoreId, String productId, String batchId, int qty) async {
    final transfer = StoreStockTransfer(
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      productId: productId,
      batchId: batchId,
      quantity: qty,
      status: 'completed',
    );
    _storeTransfers.add(transfer);
    _logAudit('STORE_TRANSFER', {'from': fromStoreId, 'to': toStoreId, 'qty': qty});
    notifyListeners();
    try {
      await _client.from('store_stock_transfers').insert(transfer.toJson());
    } catch (e) { debugPrint('store_transfer DB error: $e'); }
  }

  // ── Credit / Debit notes ─────────────────────────────────────────────────

  Future<void> createCreditNote(String partyId, double amount, String reason) async {
    final compId = _activeCompany?.id ?? '';
    final cn = CreditNote(companyId: compId, partyId: partyId, amount: amount, reason: reason);
    _creditNotes.add(cn);
    _logAudit('CREDIT_NOTE', {'party_id': partyId, 'amount': amount});
    notifyListeners();
    try { await _client.from('credit_notes').insert(cn.toJson()); } catch (e) { debugPrint('credit_note error: $e'); }
  }

  Future<void> createDebitNote(String partyId, double amount, String reason) async {
    final compId = _activeCompany?.id ?? '';
    final dn = DebitNote(companyId: compId, partyId: partyId, amount: amount, reason: reason);
    _debitNotes.add(dn);
    _logAudit('DEBIT_NOTE', {'party_id': partyId, 'amount': amount});
    notifyListeners();
    try { await _client.from('debit_notes').insert(dn.toJson()); } catch (e) { debugPrint('debit_note error: $e'); }
  }

  // ── Prescription upload URL ──────────────────────────────────────────────

  Future<String?> uploadPrescriptionImage(String patientId, Uint8List fileBytes, String fileName) async {
    try {
      final path = 'prescriptions/$patientId/$fileName';
      await _client.storage.from('prescriptions').uploadBinary(path, fileBytes);
      final url = _client.storage.from('prescriptions').getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('uploadPrescriptionImage error: $e');
      return null;
    }
  }

  // ── Audit logger ─────────────────────────────────────────────────────────

  void _logAudit(String action, Map<String, dynamic> details) {
    final compId = _activeCompany?.id ?? '';
    final userId = _users.isNotEmpty ? _users.first.id : '';
    final log = AuditLog(companyId: compId, userId: userId, action: action, details: details);
    _auditLogs.insert(0, log);
    _client.from('audit_logs').insert(log.toJson()).catchError((e) => debugPrint('audit_log insert error: $e'));
  }

  // ── Demo seed ────────────────────────────────────────────────────────────

  void _seedInitialDemoData() {
    final company = Company(
      name: 'BillSprout Demo Company',
      gstin: '27AAAAA0000A1Z5',
      address: '101 Healthcare Plaza, Mumbai, India',
      phone: '+91 9876543210',
      currency: 'INR',
      financialYear: '2026-2027',
      industryCategory: 'Pharma',
    );
    _companies.add(company);
    _activeCompany = company;

    final store1 = Store(companyId: company.id, name: 'BillSprout - Main Branch', address: 'Main Branch');
    final store2 = Store(companyId: company.id, name: 'BillSprout - Express Outlet', address: 'Uptown');
    _stores.addAll([store1, store2]);

    final user = AppUser(
      companyId: company.id,
      email: 'admin@billsprout.com',
      fullName: 'Primary Authorized User',
      roleName: 'System Administrator',
      permissions: {'all': true},
    );
    _users.add(user);

    final customer = Party(
      companyId: company.id, name: 'Rahul Sharma', partyType: 'customer',
      gstin: '27AACCB1234C1Z1', phone: '+91 9123456789',
      email: 'rahul@example.com', pricingTier: 'retail',
    );
    final supplier = Party(
      companyId: company.id, name: 'Sun Pharma Distributors', partyType: 'supplier',
      gstin: '27BBBBB1111B1Z2', phone: '+91 9898989898',
      email: 'sales@sunpharma.com', pricingTier: 'wholesale',
    );
    _parties.addAll([customer, supplier]);

    final patient = PatientProfile(
      partyId: customer.id, patientName: 'Rahul Sharma', age: 42,
      gender: 'Male', knownAllergies: ['Penicillin', 'Sulfa drugs'],
      chronicRefillNotes: 'Monthly Diabetes & Hypertension medication',
    );
    _patients.add(patient);

    final rx = Prescription(
      patientId: patient.id, doctorName: 'Dr. A. K. Gupta (MD)',
      doctorLicense: 'MCI-98765', rxNumber: 'RX-2026-8891',
      rxDetails: 'Amoxicillin 500mg, Paracetamol 650mg BD x 5 days',
    );
    _prescriptions.add(rx);

    final p1 = Product(companyId: company.id, name: 'Paracetamol 650mg (Calpol)',
      genericName: 'Paracetamol / Acetaminophen', hsnCode: '30049060',
      gstRate: 12.0, scheduleType: 'OTC', reorderLevel: 20,
      rack: 'Aisle A', shelf: 'Rack 1, Shelf B', barcode: '8901234567890',
      manufacturer: 'GSK', category: 'Analgesic', unit: 'Strip', packSize: '10 tablets');
    final p2 = Product(companyId: company.id, name: 'Amoxicillin & Potassium Clavulanate (Augmentin 625)',
      genericName: 'Amoxicillin + Clavulanic Acid', hsnCode: '30041010',
      gstRate: 12.0, scheduleType: 'Schedule H', reorderLevel: 15,
      rack: 'Aisle B', shelf: 'Rack 3, Shelf A', barcode: '8909876543210',
      manufacturer: 'GlaxoSmithKline', category: 'Antibiotic', unit: 'Strip', packSize: '6 tablets');
    final p3 = Product(companyId: company.id, name: 'Alprazolam 0.5mg (Alprax)',
      genericName: 'Alprazolam', hsnCode: '30049099',
      gstRate: 12.0, scheduleType: 'Schedule H1', reorderLevel: 10,
      rack: 'Secure Vault', shelf: 'Safe 1', barcode: '8901111222333',
      manufacturer: 'Torrent', category: 'Anxiolytic', unit: 'Strip', packSize: '10 tablets');
    final p4 = Product(companyId: company.id, name: 'Morphine Sulfate 10mg Inj',
      genericName: 'Morphine Sulfate', hsnCode: '30044000',
      gstRate: 18.0, scheduleType: 'Narcotics', reorderLevel: 5,
      rack: 'Narcotics Vault', shelf: 'Locker N1', barcode: '8904444555666',
      manufacturer: 'Neon', category: 'Opioid Analgesic', unit: 'Vial', packSize: '1 vial');
    _products.addAll([p1, p2, p3, p4]);

    final now = DateTime.now();
    _batches.addAll([
      Batch(productId: p1.id, batchNumber: 'CALP-2026-A',
        mfgDate: now.subtract(const Duration(days: 60)),
        expiryDate: now.add(const Duration(days: 300)),
        retailPrice: 35.0, wholesalePrice: 28.0, distributorPrice: 25.0,
        loyaltyPrice: 32.0, purchasePrice: 22.0, currentStock: 150),
      Batch(productId: p2.id, batchNumber: 'AUG-2026-X',
        mfgDate: now.subtract(const Duration(days: 90)),
        expiryDate: now.add(const Duration(days: 20)),
        retailPrice: 200.0, wholesalePrice: 170.0, distributorPrice: 150.0,
        loyaltyPrice: 190.0, purchasePrice: 130.0, currentStock: 45),
      Batch(productId: p3.id, batchNumber: 'ALP-2025-OLD',
        mfgDate: now.subtract(const Duration(days: 400)),
        expiryDate: now.subtract(const Duration(days: 10)),
        retailPrice: 60.0, wholesalePrice: 50.0, distributorPrice: 45.0,
        loyaltyPrice: 55.0, purchasePrice: 38.0, currentStock: 12),
      Batch(productId: p4.id, batchNumber: 'MOR-2026-N',
        mfgDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 500)),
        retailPrice: 450.0, wholesalePrice: 400.0, distributorPrice: 380.0,
        loyaltyPrice: 440.0, purchasePrice: 320.0, currentStock: 8),
    ]);

    final cashAccount = Account(companyId: company.id, name: 'Main Cash Account', type: 'cash', balance: 50000.0);
    final bankAccount = Account(companyId: company.id, name: 'HDFC Bank Account', type: 'bank', balance: 250000.0);
    final salesAccount = Account(companyId: company.id, name: 'Sales Revenue Account', type: 'income', balance: 120000.0);
    final purchaseAccount = Account(companyId: company.id, name: 'Purchase Expense Account', type: 'expense', balance: 75000.0);
    _accounts.addAll([cashAccount, bankAccount, salesAccount, purchaseAccount]);

    _ledgerEntries.add(LedgerEntry(accountId: cashAccount.id, description: 'Opening Cash Balance', debit: 50000.0));
    _ledgerEntries.add(LedgerEntry(accountId: bankAccount.id, description: 'Opening Bank Balance', debit: 250000.0));

    _refillReminders.add(RefillReminder(
      patientId: patient.id, productId: p1.id,
      reminderDate: now.add(const Duration(days: 5)), status: 'pending',
    ));

    _auditLogs.add(AuditLog(
      companyId: company.id, userId: user.id, action: 'SYSTEM_INIT',
      details: {'message': 'System initialized with demo dataset.'},
    ));
  }
}
