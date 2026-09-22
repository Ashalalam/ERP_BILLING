import '../../models/models.dart';

/// FEFO (First Expire, First Out) Batch Selector Engine
class FefoSelector {
  /// Picks the optimal non-expired batch with available stock expiring soonest.
  static Batch? selectFefoBatch(List<Batch> batches, DateTime currentDate) {
    if (batches.isEmpty) return null;

    final validBatches = batches.where((b) {
      final isNotExpired = b.expiryDate.isAfter(currentDate);
      final hasStock = b.currentStock > 0;
      return isNotExpired && hasStock;
    }).toList();

    if (validBatches.isEmpty) return null;

    validBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return validBatches.first;
  }

  /// Identifies near-expiry batches within 30, 60, or 90 days threshold.
  static List<Batch> getNearExpiryBatches(List<Batch> batches, DateTime currentDate, int thresholdDays) {
    final thresholdDate = currentDate.add(Duration(days: thresholdDays));
    return batches.where((b) {
      return b.expiryDate.isAfter(currentDate) && b.expiryDate.isBefore(thresholdDate) && b.currentStock > 0;
    }).toList();
  }

  /// Identifies expired batches that require Automatic Return-to-Vendor (RTV) draft generation.
  static List<Batch> getExpiredBatches(List<Batch> batches, DateTime currentDate) {
    return batches.where((b) {
      return (b.expiryDate.isBefore(currentDate) || b.expiryDate.isAtSameMomentAs(currentDate)) && b.currentStock > 0;
    }).toList();
  }
}
