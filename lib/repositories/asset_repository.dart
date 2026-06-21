import 'package:isar/isar.dart';
import '../models/asset.dart';

/// Data-access layer for [Asset] backed by Isar.
class AssetRepository {
  final Isar _isar;

  AssetRepository(this._isar);

  /// Returns all assets.
  Future<List<Asset>> getAll() async {
    return _isar.assets.where().findAll();
  }

  /// Returns assets belonging to a specific activity.
  Future<List<Asset>> getByActivity(String activityId) async {
    return _isar.assets.filter().activityIdEqualTo(activityId).findAll();
  }

  /// Returns a single asset by its business [id], or null.
  Future<Asset?> getById(String id) async {
    return _isar.assets.filter().idEqualTo(id).findFirst();
  }

  /// Inserts or updates an asset.
  Future<void> put(Asset asset) async {
    await _isar.writeTxn(() async {
      await _isar.assets.put(asset);
    });
  }

  /// Watches the entire asset collection.
  Stream<void> watchAll() {
    return _isar.assets.watchLazy();
  }
}
