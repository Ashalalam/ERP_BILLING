import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';

class ChainStoreView extends StatefulWidget {
  const ChainStoreView({super.key});

  @override
  State<ChainStoreView> createState() => _ChainStoreViewState();
}

class _ChainStoreViewState extends State<ChainStoreView> {
  final _db = SupabaseService.instance;
  final _syncService = SyncService.instance;

  void _triggerStoreSync() async {
    await _syncService.syncStoreInventory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store inventory successfully synchronized across all pharmacy chain branches.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Multi-Store & Chain Synchronization', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _syncService.isSyncing ? null : _triggerStoreSync,
                icon: _syncService.isSyncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync),
                label: Text(_syncService.isSyncing ? 'Syncing...' : 'Run Store Inventory Sync'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Registered Store Chain Outlets:'),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.stores.length,
              itemBuilder: (context, index) {
                final store = _db.stores[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.blue),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Location: ${store.address ?? 'Main Branch'} | Status: Synchronized'),
                    trailing: const Chip(label: Text('Sync Online'), backgroundColor: Colors.greenAccent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
