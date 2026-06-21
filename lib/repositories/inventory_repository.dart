import 'package:isar/isar.dart';
import '../models/inventory_item.dart';

/// Data-access layer for [InventoryItem] backed by Isar.
class InventoryRepository {
  final Isar _isar;

  InventoryRepository(this._isar);

  /// Returns all inventory items.
  Future<List<InventoryItem>> getAll() async {
    return _isar.inventoryItems.where().findAll();
  }

  /// Returns inventory items belonging to a specific activity.
  Future<List<InventoryItem>> getByActivity(String activityId) async {
    return _isar.inventoryItems
        .filter()
        .activityIdEqualTo(activityId)
        .findAll();
  }

  /// Returns a single item by its business [id], or null.
  Future<InventoryItem?> getById(String id) async {
    return _isar.inventoryItems.filter().idEqualTo(id).findFirst();
  }

  /// Inserts or updates an inventory item.
  Future<void> put(InventoryItem item) async {
    await _isar.writeTxn(() async {
      await _isar.inventoryItems.put(item);
    });
  }

  /// Watches the entire inventory collection.
  Stream<void> watchAll() {
    return _isar.inventoryItems.watchLazy();
  }
}
