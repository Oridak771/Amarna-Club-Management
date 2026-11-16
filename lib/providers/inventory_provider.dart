import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';
import '../services/odoo_jsonrpc_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(isarProvider));
});

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final InventoryRepository _repo;
  final OdooClubService _club;

  InventoryNotifier(this._repo, this._club) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadInventory();
    await refreshFromOdoo();
  }

  Future<void> _loadInventory() async {
    state = await _repo.getAll();
  }

  /// Pulls consumables from Odoo and upserts them into the local cache.
  Future<void> refreshFromOdoo() async {
    if (!_club.isConfigured) return;
    try {
      final remote = await _club.fetchInventory();
      if (remote.isNotEmpty) {
        await _repo.putAll(remote);
        await _loadInventory();
      }
    } catch (error) {
      reportSyncIssue('Stocks (lecture)', error);
    }
  }

  Future<void> adjustStock(String itemId, int amount) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    final newQty = (item.currentStock + amount).clamp(0, 9999);
    await _repo.put(item.copyWith(currentStock: newQty));
    await _loadInventory();
    _pushQty(itemId, newQty);
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    final newQty = newQuantity.clamp(0, 9999);
    await _repo.put(item.copyWith(currentStock: newQty));
    await _loadInventory();
    _pushQty(itemId, newQty);
  }

  Future<void> _pushQty(String itemId, int qty) async {
    if (!_club.isConfigured) return;
    try {
      await _club.pushInventoryQty(itemId, qty);
    } catch (error) {
      reportSyncIssue('Stock « $itemId »', error);
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  return InventoryNotifier(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(odooClubServiceProvider),
  );
});
