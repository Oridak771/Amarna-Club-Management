import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../repositories/asset_repository.dart';
import '../services/database_service.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(isarProvider));
});

class AssetsNotifier extends StateNotifier<List<Asset>> {
  final AssetRepository _repo;

  AssetsNotifier(this._repo) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    state = await _repo.getAll();
  }

  Future<void> updateAssetStatus(String assetId, AssetStatus status) async {
    final asset = await _repo.getById(assetId);
    if (asset != null) {
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
      await _repo.put(updated);
      await _loadAssets();
    }
  }
}

final assetsProvider =
    StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  final repo = ref.watch(assetRepositoryProvider);
  return AssetsNotifier(repo);
});
