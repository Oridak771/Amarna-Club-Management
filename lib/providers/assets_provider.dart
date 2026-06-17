import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/asset.dart';
import '../services/database_service.dart';

class AssetsNotifier extends StateNotifier<List<Asset>> {
  final Isar _isar;

  AssetsNotifier(this._isar) : super([]) {
    _loadAssets();
  }

  void _loadAssets() {
    state = _isar.assets.where().findAllSync();
  }

  void updateAssetStatus(String assetId, AssetStatus status) {
    final asset = _isar.assets.filter().idEqualTo(assetId).findFirstSync();
    if (asset != null) {
      _isar.writeTxnSync(() {
        final updated = Asset(
          isarId: asset.isarId,
          id: asset.id,
          serialNumber: asset.serialNumber,
          name: asset.name,
          category: asset.category,
          activityId: asset.activityId,
          status: status,
          lastMaintenance: asset.lastMaintenance,
          nextMaintenance: asset.nextMaintenance,
          imageUrl: asset.imageUrl,
          technicalSpecsJson: asset.technicalSpecsJson,
        );
        _isar.assets.putSync(updated);
      });
      _loadAssets();
    }
  }
}

final assetsProvider = StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  final isar = ref.watch(isarProvider);
  return AssetsNotifier(isar);
});
