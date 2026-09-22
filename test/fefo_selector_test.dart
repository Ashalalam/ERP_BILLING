import 'package:flutter_test/flutter_test.dart';
import 'package:erp_billing/models/models.dart';
import 'package:erp_billing/core/utils/fefo_selector.dart';

void main() {
  group('FEFO (First Expire, First Out) Selector Tests', () {
    final now = DateTime.now();

    final bFar = Batch(
      productId: 'p1',
      batchNumber: 'B-FAR',
      mfgDate: now,
      expiryDate: now.add(const Duration(days: 300)),
      retailPrice: 100,
      wholesalePrice: 80,
      distributorPrice: 70,
      loyaltyPrice: 90,
      purchasePrice: 50,
      currentStock: 50,
    );

    final bSoon = Batch(
      productId: 'p1',
      batchNumber: 'B-SOON',
      mfgDate: now,
      expiryDate: now.add(const Duration(days: 30)),
      retailPrice: 100,
      wholesalePrice: 80,
      distributorPrice: 70,
      loyaltyPrice: 90,
      purchasePrice: 50,
      currentStock: 20,
    );

    final bExpired = Batch(
      productId: 'p1',
      batchNumber: 'B-EXPIRED',
      mfgDate: now,
      expiryDate: now.subtract(const Duration(days: 10)),
      retailPrice: 100,
      wholesalePrice: 80,
      distributorPrice: 70,
      loyaltyPrice: 90,
      purchasePrice: 50,
      currentStock: 10,
    );

    test('Picks batch expiring soonest while skipping expired & zero stock batches', () {
      final selected = FefoSelector.selectFefoBatch([bFar, bExpired, bSoon], now);
      expect(selected, isNotNull);
      expect(selected!.batchNumber, equals('B-SOON'));
    });

    test('Identifies near-expiry batches within threshold', () {
      final nearExpiry = FefoSelector.getNearExpiryBatches([bFar, bSoon, bExpired], now, 60);
      expect(nearExpiry.length, equals(1));
      expect(nearExpiry.first.batchNumber, equals('B-SOON'));
    });

    test('Identifies expired batches for RTV generation', () {
      final expired = FefoSelector.getExpiredBatches([bFar, bSoon, bExpired], now);
      expect(expired.length, equals(1));
      expect(expired.first.batchNumber, equals('B-EXPIRED'));
    });
  });
}
