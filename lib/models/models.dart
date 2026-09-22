import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Company {
  final String id;
  final String name;
  final String? gstin;
  final String? address;
  final String? phone;
  final String currency;
  final String financialYear;
  final String industryCategory;
  final DateTime createdAt;

  Company({
    String? id,
    required this.name,
    this.gstin,
    this.address,
    this.phone,
    this.currency = 'INR',
    this.financialYear = '2026-2027',
    this.industryCategory = 'Pharma',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gstin': gstin,
        'address': address,
        'phone': phone,
        'currency': currency,
        'financial_year': financialYear,
        'industry_category': industryCategory,
        'created_at': createdAt.toIso8601String(),
      };
}

class LocationGodown {
  final String id;
  final String companyId;
  final String name;
  final bool isGodown;
  final String? address;

  LocationGodown({
    String? id,
    required this.companyId,
    required this.name,
    this.isGodown = false,
    this.address,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'is_godown': isGodown,
        'address': address,
      };
}

class AppUser {
  final String id;
  final String companyId;
  final String email;
  final String fullName;
  final String roleName;
  final Map<String, dynamic> permissions;
  final String? storeId;

  AppUser({
    String? id,
    required this.companyId,
    required this.email,
    required this.fullName,
    this.roleName = 'Standard User',
    this.permissions = const {},
    this.storeId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'email': email,
        'full_name': fullName,
        'role_name': roleName,
        'permissions': permissions,
        'store_id': storeId,
      };

  AppUser copyWith({
    String? email,
    String? fullName,
    String? roleName,
    Map<String, dynamic>? permissions,
    String? storeId,
  }) =>
      AppUser(
        id: id,
        companyId: companyId,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        roleName: roleName ?? this.roleName,
        permissions: permissions ?? this.permissions,
        storeId: storeId ?? this.storeId,
      );
}

class Party {
  final String id;
  final String companyId;
  final String name;
  final String partyType; // 'customer', 'supplier'
  final String? gstin;
  final String? phone;
  final String? email;
  final String? address;
  final String pricingTier;

  Party({
    String? id,
    required this.companyId,
    required this.name,
    required this.partyType,
    this.gstin,
    this.phone,
    this.email,
    this.address,
    this.pricingTier = 'retail',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'party_type': partyType,
        'gstin': gstin,
        'phone': phone,
        'email': email,
        'address': address,
        'pricing_tier': pricingTier,
      };

  Party copyWith({
    String? name,
    String? gstin,
    String? phone,
    String? email,
    String? address,
    String? pricingTier,
  }) =>
      Party(
        id: id,
        companyId: companyId,
        name: name ?? this.name,
        partyType: partyType,
        gstin: gstin ?? this.gstin,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        pricingTier: pricingTier ?? this.pricingTier,
      );
}

class PatientProfile {
  final String id;
  final String partyId;
  final String patientName;
  final int? age;
  final String? gender;
  final List<String> knownAllergies;
  final String? chronicRefillNotes;
  final String? prescriptionImageUrl;

  PatientProfile({
    String? id,
    required this.partyId,
    required this.patientName,
    this.age,
    this.gender,
    this.knownAllergies = const [],
    this.chronicRefillNotes,
    this.prescriptionImageUrl,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'party_id': partyId,
        'patient_name': patientName,
        'age': age,
        'gender': gender,
        'known_allergies': knownAllergies,
        'chronic_refill_notes': chronicRefillNotes,
        'prescription_image_url': prescriptionImageUrl,
      };

  PatientProfile copyWith({
    String? patientName,
    int? age,
    String? gender,
    List<String>? knownAllergies,
    String? chronicRefillNotes,
    String? prescriptionImageUrl,
  }) =>
      PatientProfile(
        id: id,
        partyId: partyId,
        patientName: patientName ?? this.patientName,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        knownAllergies: knownAllergies ?? this.knownAllergies,
        chronicRefillNotes: chronicRefillNotes ?? this.chronicRefillNotes,
        prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      );
}

class Prescription {
  final String id;
  final String patientId;
  final String doctorName;
  final String? doctorLicense;
  final String rxNumber;
  final String? rxDetails;

  Prescription({
    String? id,
    required this.patientId,
    required this.doctorName,
    this.doctorLicense,
    required this.rxNumber,
    this.rxDetails,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'doctor_name': doctorName,
        'doctor_license': doctorLicense,
        'rx_number': rxNumber,
        'rx_details': rxDetails,
      };
}

class Product {
  final String id;
  final String companyId;
  final String name;
  final String? genericName;
  final String hsnCode;
  final double gstRate;
  final String scheduleType;
  final int reorderLevel;
  final String? rack;
  final String? shelf;
  final String? barcode;
  final String? manufacturer;
  final String? category;
  final String? unit;
  final String? packSize;

  Product({
    String? id,
    required this.companyId,
    required this.name,
    this.genericName,
    required this.hsnCode,
    this.gstRate = 12.0,
    this.scheduleType = 'OTC',
    this.reorderLevel = 10,
    this.rack,
    this.shelf,
    this.barcode,
    this.manufacturer,
    this.category,
    this.unit,
    this.packSize,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'generic_name': genericName,
        'hsn_code': hsnCode,
        'gst_rate': gstRate,
        'schedule_type': scheduleType,
        'reorder_level': reorderLevel,
        'rack': rack,
        'shelf': shelf,
        'barcode': barcode,
        'manufacturer': manufacturer,
        'category': category,
        'unit': unit,
        'pack_size': packSize,
      };

  Product copyWith({
    String? name,
    String? genericName,
    String? hsnCode,
    double? gstRate,
    String? scheduleType,
    int? reorderLevel,
    String? rack,
    String? shelf,
    String? barcode,
    String? manufacturer,
    String? category,
    String? unit,
    String? packSize,
  }) =>
      Product(
        id: id,
        companyId: companyId,
        name: name ?? this.name,
        genericName: genericName ?? this.genericName,
        hsnCode: hsnCode ?? this.hsnCode,
        gstRate: gstRate ?? this.gstRate,
        scheduleType: scheduleType ?? this.scheduleType,
        reorderLevel: reorderLevel ?? this.reorderLevel,
        rack: rack ?? this.rack,
        shelf: shelf ?? this.shelf,
        barcode: barcode ?? this.barcode,
        manufacturer: manufacturer ?? this.manufacturer,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        packSize: packSize ?? this.packSize,
      );
}

class Batch {
  final String id;
  final String productId;
  final String? locationId;
  final String batchNumber;
  final DateTime mfgDate;
  final DateTime expiryDate;
  final double retailPrice;
  final double wholesalePrice;
  final double distributorPrice;
  final double loyaltyPrice;
  final double purchasePrice;
  int currentStock;

  Batch({
    String? id,
    required this.productId,
    this.locationId,
    required this.batchNumber,
    required this.mfgDate,
    required this.expiryDate,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.distributorPrice,
    required this.loyaltyPrice,
    required this.purchasePrice,
    required this.currentStock,
  }) : id = id ?? _uuid.v4();

  double getPriceForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'wholesale': return wholesalePrice;
      case 'distributor': return distributorPrice;
      case 'loyalty': return loyaltyPrice;
      case 'retail':
      default: return retailPrice;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'location_id': locationId,
        'batch_number': batchNumber,
        'mfg_date': mfgDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'distributor_price': distributorPrice,
        'loyalty_price': loyaltyPrice,
        'purchase_price': purchasePrice,
        'current_stock': currentStock,
      };
}

class Invoice {
  final String id;
  final String companyId;
  final String? locationId;
  final String invoiceNumber;
  final String? partyId;
  final String? prescriptionId;
  final String invoiceType;
  final String paymentMethod;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? eInvoiceIrn;
  final bool pharmacistApproved;
  final DateTime createdAt;
  final double? cashAmount;
  final double? cardAmount;
  final double? upiAmount;
  final bool isCancelled;
  final String? cancelReason;

  Invoice({
    String? id,
    required this.companyId,
    this.locationId,
    required this.invoiceNumber,
    this.partyId,
    this.prescriptionId,
    this.invoiceType = 'sales',
    this.paymentMethod = 'cash',
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.eInvoiceIrn,
    this.pharmacistApproved = true,
    DateTime? createdAt,
    this.cashAmount,
    this.cardAmount,
    this.upiAmount,
    this.isCancelled = false,
    this.cancelReason,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'location_id': locationId,
        'invoice_number': invoiceNumber,
        'party_id': partyId,
        'prescription_id': prescriptionId,
        'invoice_type': invoiceType,
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'e_invoice_irn': eInvoiceIrn,
        'pharmacist_approved': pharmacistApproved,
        'created_at': createdAt.toIso8601String(),
        'cash_amount': cashAmount,
        'card_amount': cardAmount,
        'upi_amount': upiAmount,
        'is_cancelled': isCancelled,
        'cancel_reason': cancelReason,
      };
}

class InvoiceItem {
  final String id;
  final String invoiceId;
  final String productId;
  final String batchId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double taxAmount;
  final double totalPrice;
  final double discountPercent;

  InvoiceItem({
    String? id,
    required this.invoiceId,
    required this.productId,
    required this.batchId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.taxAmount,
    required this.totalPrice,
    this.discountPercent = 0.0,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_id': invoiceId,
        'product_id': productId,
        'batch_id': batchId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'tax_amount': taxAmount,
        'total_price': totalPrice,
        'discount_percent': discountPercent,
      };
}

class CreditNote {
  final String id;
  final String companyId;
  final String partyId;
  final double amount;
  final String reason;
  final DateTime createdAt;

  CreditNote({
    String? id,
    required this.companyId,
    required this.partyId,
    required this.amount,
    required this.reason,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'party_id': partyId,
        'amount': amount,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
      };
}

class DebitNote {
  final String id;
  final String companyId;
  final String partyId;
  final double amount;
  final String reason;
  final DateTime createdAt;

  DebitNote({
    String? id,
    required this.companyId,
    required this.partyId,
    required this.amount,
    required this.reason,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'party_id': partyId,
        'amount': amount,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
      };
}

class Payment {
  final String id;
  final String companyId;
  final String partyId;
  final double amount;
  final String paymentType;
  final String paymentMode;
  final DateTime createdAt;

  Payment({
    String? id,
    required this.companyId,
    required this.partyId,
    required this.amount,
    required this.paymentType,
    required this.paymentMode,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'party_id': partyId,
        'amount': amount,
        'payment_type': paymentType,
        'payment_mode': paymentMode,
        'created_at': createdAt.toIso8601String(),
      };
}

class Account {
  final String id;
  final String companyId;
  final String name;
  final String type;
  double balance;

  Account({
    String? id,
    required this.companyId,
    required this.name,
    required this.type,
    this.balance = 0.0,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'type': type,
        'balance': balance,
      };
}

class LedgerEntry {
  final String id;
  final String accountId;
  final String description;
  final double debit;
  final double credit;
  final DateTime createdAt;

  LedgerEntry({
    String? id,
    required this.accountId,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'description': description,
        'debit': debit,
        'credit': credit,
        'created_at': createdAt.toIso8601String(),
      };
}

class BankReconciliation {
  final String id;
  final String companyId;
  final String accountId;
  final DateTime statementDate;
  final double statementBalance;
  bool reconciled;

  BankReconciliation({
    String? id,
    required this.companyId,
    required this.accountId,
    required this.statementDate,
    required this.statementBalance,
    this.reconciled = false,
  }) : id = id ?? _uuid.v4();
}

class RestrictedDrugLog {
  final String id;
  final String companyId;
  final String invoiceId;
  final String productId;
  final String batchId;
  final String scheduleType;
  final String patientName;
  final String doctorName;
  final int quantity;
  final DateTime createdAt;

  RestrictedDrugLog({
    String? id,
    required this.companyId,
    required this.invoiceId,
    required this.productId,
    required this.batchId,
    required this.scheduleType,
    required this.patientName,
    required this.doctorName,
    required this.quantity,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'invoice_id': invoiceId,
        'product_id': productId,
        'batch_id': batchId,
        'schedule_type': scheduleType,
        'patient_name': patientName,
        'doctor_name': doctorName,
        'quantity': quantity,
        'created_at': createdAt.toIso8601String(),
      };
}

class AuditLog {
  final String id;
  final String companyId;
  final String userId;
  final String action;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  AuditLog({
    String? id,
    required this.companyId,
    required this.userId,
    required this.action,
    this.details = const {},
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'user_id': userId,
        'action': action,
        'details': details,
        'created_at': createdAt.toIso8601String(),
      };
}

class RtvNote {
  final String id;
  final String companyId;
  final String batchId;
  final String supplierId;
  final int quantity;
  final String status;

  RtvNote({
    String? id,
    required this.companyId,
    required this.batchId,
    required this.supplierId,
    required this.quantity,
    this.status = 'draft',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'batch_id': batchId,
        'supplier_id': supplierId,
        'quantity': quantity,
        'status': status,
      };
}

class PurchaseOrder {
  final String id;
  final String companyId;
  final String supplierId;
  final String productId;
  final int quantity;
  final String status;

  PurchaseOrder({
    String? id,
    required this.companyId,
    required this.supplierId,
    required this.productId,
    required this.quantity,
    this.status = 'auto_generated',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'supplier_id': supplierId,
        'product_id': productId,
        'quantity': quantity,
        'status': status,
      };
}

class RefillReminder {
  final String id;
  final String patientId;
  final String productId;
  final DateTime reminderDate;
  String status;

  RefillReminder({
    String? id,
    required this.patientId,
    required this.productId,
    required this.reminderDate,
    this.status = 'pending',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'product_id': productId,
        'reminder_date': reminderDate.toIso8601String(),
        'status': status,
      };
}

class Store {
  final String id;
  final String companyId;
  final String name;
  final String? address;

  Store({
    String? id,
    required this.companyId,
    required this.name,
    this.address,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'address': address,
      };
}

class StoreStockTransfer {
  final String id;
  final String fromStoreId;
  final String toStoreId;
  final String productId;
  final String batchId;
  final int quantity;
  final String status;

  StoreStockTransfer({
    String? id,
    required this.fromStoreId,
    required this.toStoreId,
    required this.productId,
    required this.batchId,
    required this.quantity,
    this.status = 'completed',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_store_id': fromStoreId,
        'to_store_id': toStoreId,
        'product_id': productId,
        'batch_id': batchId,
        'quantity': quantity,
        'status': status,
      };
}

class StockAdjustment {
  final String id;
  final String companyId;
  final String batchId;
  final String productId;
  final int quantityChange; // negative for write-off, positive for addition
  final String adjustmentType; // 'damage', 'theft', 'sample', 'manual', 'expired_writeoff'
  final String reason;
  final DateTime createdAt;

  StockAdjustment({
    String? id,
    required this.companyId,
    required this.batchId,
    required this.productId,
    required this.quantityChange,
    required this.adjustmentType,
    required this.reason,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'batch_id': batchId,
        'product_id': productId,
        'quantity_change': quantityChange,
        'adjustment_type': adjustmentType,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
      };
}
