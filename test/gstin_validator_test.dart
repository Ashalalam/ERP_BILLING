import 'package:flutter_test/flutter_test.dart';
import 'package:erp_billing/core/utils/gstin_validator.dart';

void main() {
  group('GSTIN Format & Tax Calculation Tests', () {
    test('Validates structurally correct 15-character GSTIN', () {
      expect(GstinValidator.validate('27AAAAA0000A1Z5'), isTrue);
      expect(GstinValidator.validate('07AABCC1234D1Z2'), isTrue);
    });

    test('Rejects invalid GSTIN strings', () {
      expect(GstinValidator.validate('INVALID_GSTIN'), isFalse);
      expect(GstinValidator.validate('12345'), isFalse);
      expect(GstinValidator.validate(''), isFalse);
    });

    test('Calculates Intra-state CGST + SGST tax split', () {
      final res = GstinValidator.calculateGstTax(amount: 1000.0, gstRate: 12.0, isIntraState: true);
      expect(res['cgst'], equals(60.0));
      expect(res['sgst'], equals(60.0));
      expect(res['igst'], equals(0.0));
      expect(res['totalTax'], equals(120.0));
    });

    test('Calculates Inter-state IGST tax', () {
      final res = GstinValidator.calculateGstTax(amount: 1000.0, gstRate: 18.0, isIntraState: false);
      expect(res['cgst'], equals(0.0));
      expect(res['sgst'], equals(0.0));
      expect(res['igst'], equals(180.0));
      expect(res['totalTax'], equals(180.0));
    });
  });
}
