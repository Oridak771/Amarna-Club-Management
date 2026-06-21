import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(isarProvider));
});

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final InventoryRepository _repo;
  final Ref _ref;

  InventoryNotifier(this._repo, this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadInventory();
  }

  Future<void> _loadInventory() async {
    state = await _repo.getAll();
  }

  Future<void> adjustStock(String itemId, int amount) async {
    final item = await _repo.getById(itemId);
    if (item != null) {
      final syncState = _ref.read(syncProvider);
      final newStock = (item.currentStock + amount).clamp(0, 9999);

      final updated = item.copyWith(currentStock: newStock);
      await _repo.put(updated);
      await _loadInventory();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Ajustement stock '${item.name}' (${amount > 0 ? '+' : ''}$amount ${item.unitName})");
      }
    }
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    final item = await _repo.getById(itemId);
    if (item != null) {
      final syncState = _ref.read(syncProvider);
      final newStock = newQuantity.clamp(0, 9999);

      final updated = item.copyWith(currentStock: newStock);
      await _repo.put(updated);
      await _loadInventory();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Ajustement stock '${item.name}' -> $newStock ${item.unitName}");
      }
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventoryNotifier(repo, ref);
});
