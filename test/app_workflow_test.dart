import 'package:flutter_test/flutter_test.dart';
import 'package:erp_billing/services/supabase_service.dart';

void main() {
  group('Integrated ERP Workflow Tests', () {
    late SupabaseService db;

    setUp(() {
      db = SupabaseService.instance;
    });

    test('Initializes active company & demo dataset correctly', () {
      expect(db.activeCompany, isNotNull);
      expect(db.products.length, greaterThanOrEqualTo(4));
      expect(db.batches.length, greaterThanOrEqualTo(4));
      expect(db.parties.length, greaterThanOrEqualTo(2));
    });

    test('Creates sales invoice asynchronously and logs audit trail', () async {
      final p = db.products.first;
      final b = db.batches.firstWhere((batch) => batch.productId == p.id);
      final initialStock = b.currentStock;

      final invoice = await db.createInvoice(
        invoiceNumber: 'TEST-INV-101',
        partyId: db.parties.first.id,
        invoiceType: 'sales',
        paymentMethod: 'cash',
        itemsData: [
          {'product': p, 'batch': b, 'qty': 5, 'price': 35.0},
        ],
        patientName: 'Test Patient',
        doctorName: 'Test Doctor',
        pharmacistApproved: true,
      );

      expect(invoice.id, isNotEmpty);
      expect(invoice.totalAmount, greaterThan(0));
      expect(b.currentStock, equals(initialStock - 5));
      expect(db.auditLogs.any((a) => a.action == 'INVOICE_CREATE'), isTrue);
    });

    test('Generates RTV draft notes for expired stock', () {
      final rtvCount = db.generateRtvDraftsForExpiredBatches();
      expect(rtvCount, greaterThanOrEqualTo(1));
      expect(db.rtvNotes.any((r) => r.status == 'draft'), isTrue);
    });

    test('Executes store-to-store stock transfers', () async {
      final fromStore = db.stores.first.id;
      final toStore =
          db.stores.length > 1 ? db.stores[1].id : 'store2';
      final prod = db.products.first.id;
      final batch = db.batches.first.id;

      await db.transferStockBetweenStores(
          fromStore, toStore, prod, batch, 10);
      expect(db.storeTransfers.isNotEmpty, isTrue);
      expect(db.storeTransfers.last.quantity, equals(10));
    });
  });
}
