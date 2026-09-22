/// Result structure for parsed barcodes
class ParsedBarcode {
  final String rawData;
  final String format; // 'GS1', 'DataMatrix', '1D'
  final String? gtin;
  final String? batchNumber;
  final String? expiryDateString;

  ParsedBarcode({
    required this.rawData,
    required this.format,
    this.gtin,
    this.batchNumber,
    this.expiryDateString,
  });
}

/// Barcode & QR Decoder for GS1-128, DataMatrix, and 1D Barcodes
class BarcodeParser {
  static ParsedBarcode parse(String barcodeData) {
    final clean = barcodeData.trim();

    // Check for GS1-128 / DataMatrix Application Identifiers (AI) e.g. (01)08901234567890(17)261231(10)BATCH123
    if (clean.contains('(01)') || clean.contains('(17)') || clean.contains('(10)')) {
      String? gtin;
      String? expiry;
      String? batch;

      final gtinMatch = RegExp(r'\(01\)(\d{14})').firstMatch(clean);
      if (gtinMatch != null) gtin = gtinMatch.group(1);

      final expMatch = RegExp(r'\(17\)(\d{6})').firstMatch(clean);
      if (expMatch != null) expiry = expMatch.group(1);

      final batchMatch = RegExp(r'\(10\)([A-Za-z0-9\-]+)').firstMatch(clean);
      if (batchMatch != null) batch = batchMatch.group(1);

      final format = clean.contains('(01)') ? 'GS1' : 'DataMatrix';
      return ParsedBarcode(
        rawData: clean,
        format: format,
        gtin: gtin,
        expiryDateString: expiry,
        batchNumber: batch,
      );
    }

    // Default 1D Barcode (EAN-13, Code-128)
    return ParsedBarcode(
      rawData: clean,
      format: '1D',
      gtin: clean,
    );
  }
}
