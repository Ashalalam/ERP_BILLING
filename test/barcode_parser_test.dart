import 'package:flutter_test/flutter_test.dart';
import 'package:erp_billing/core/utils/barcode_parser.dart';

void main() {
  group('Barcode & QR Parser Tests', () {
    test('Parses GS1-128 AI barcode format', () {
      const gs1 = '(01)08901234567890(17)261231(10)BATCH99';
      final parsed = BarcodeParser.parse(gs1);

      expect(parsed.format, equals('GS1'));
      expect(parsed.gtin, equals('08901234567890'));
      expect(parsed.expiryDateString, equals('261231'));
      expect(parsed.batchNumber, equals('BATCH99'));
    });

    test('Parses standard 1D barcode format', () {
      const barcode1D = '8901234567890';
      final parsed = BarcodeParser.parse(barcode1D);

      expect(parsed.format, equals('1D'));
      expect(parsed.gtin, equals('8901234567890'));
    });
  });
}
