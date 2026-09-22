/// GSTIN Validator Utility for verifying 15-character Indian GST Identification Numbers.
class GstinValidator {
  static final RegExp _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  /// Returns true if the string is a structurally valid GSTIN format.
  static bool validate(String gstin) {
    if (gstin.isEmpty) return false;
    final cleanGstin = gstin.trim().toUpperCase();
    if (cleanGstin.length != 15) return false;
    return _gstinRegex.hasMatch(cleanGstin);
  }

  /// Calculates CGST and SGST for Intra-State or IGST for Inter-State supply.
  static Map<String, double> calculateGstTax({
    required double amount,
    required double gstRate,
    required bool isIntraState,
  }) {
    final totalTax = amount * (gstRate / 100.0);
    if (isIntraState) {
      return {
        'cgst': totalTax / 2.0,
        'sgst': totalTax / 2.0,
        'igst': 0.0,
        'totalTax': totalTax,
      };
    } else {
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': totalTax,
        'totalTax': totalTax,
      };
    }
  }
}
