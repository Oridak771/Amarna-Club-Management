import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';
import '../services/database_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(isarProvider));
});

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final InventoryRepository _repo;

  InventoryNotifier(this._repo) : super([]) {
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    state = await _repo.getAll();
  }

  Future<void> adjustStock(String itemId, int amount) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    await _repo.put(
      item.copyWith(currentStock: (item.currentStock + amount).clamp(0, 9999)),
    );
    await _loadInventory();
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    await _repo.put(item.copyWith(currentStock: newQuantity.clamp(0, 9999)));
    await _loadInventory();
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  return InventoryNotifier(ref.watch(inventoryRepositoryProvider));
});
