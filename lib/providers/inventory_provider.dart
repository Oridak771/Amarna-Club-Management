import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final Isar _isar;
  final Ref _ref;

  InventoryNotifier(this._isar, this._ref) : super([]) {
    _loadInventory();
  }

  void _loadInventory() {
    state = _isar.inventoryItems.where().findAllSync();
  }

  void adjustStock(String itemId, int amount) {
    final item =
        _isar.inventoryItems.filter().idEqualTo(itemId).findFirstSync();
    if (item != null) {
      final syncState = _ref.read(syncProvider);
      final newStock = (item.currentStock + amount).clamp(0, 9999);

      _isar.writeTxnSync(() {
        final updated = item.copyWith(currentStock: newStock);
        _isar.inventoryItems.putSync(updated);
      });
      _loadInventory();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Ajustement stock '${item.name}' (${amount > 0 ? '+' : ''}$amount ${item.unitName})");
      }
    }
  }

  void updateStock(String itemId, int newQuantity) {
    final item =
        _isar.inventoryItems.filter().idEqualTo(itemId).findFirstSync();
    if (item != null) {
      final syncState = _ref.read(syncProvider);
      final newStock = newQuantity.clamp(0, 9999);

      _isar.writeTxnSync(() {
        final updated = item.copyWith(currentStock: newStock);
        _isar.inventoryItems.putSync(updated);
      });
      _loadInventory();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Ajustement stock '${item.name}' -> $newStock ${item.unitName}");
      }
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return InventoryNotifier(isar, ref);
});
