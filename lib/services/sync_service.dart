import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Synchronises local in-memory state with Supabase for multi-branch sync.
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _lastSyncStatus = 'Not synced yet';

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get lastSyncStatus => _lastSyncStatus;

  /// Re-fetches all data from Supabase to sync latest state across branches.
  Future<void> syncStoreInventory() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _lastSyncStatus = 'Syncing...';
    notifyListeners();

    try {
      await SupabaseService.instance.initialize();
      _lastSyncStatus = 'Sync complete';
    } catch (e) {
      debugPrint('SyncService error: $e');
      _lastSyncStatus = 'Sync failed: $e';
    }

    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    notifyListeners();
  }
}
