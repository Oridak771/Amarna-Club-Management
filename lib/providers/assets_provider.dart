import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../repositories/asset_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(isarProvider));
});

class AssetsNotifier extends StateNotifier<List<Asset>> {
  final AssetRepository _repo;
  final OdooClubService _club;

  AssetsNotifier(this._repo, this._club) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadAssets();
    await refreshFromOdoo();
  }

  Future<void> _loadAssets() async {
    state = await _repo.getAll();
  }

  /// Pulls all club assets (equipment, armory, machines, courts) from Odoo
  /// and upserts them into the local cache.
  Future<void> refreshFromOdoo() async {
    if (!_club.isConfigured) return;
    try {
      final remote = await _club.fetchAssets();
      if (remote.isNotEmpty) {
        await _repo.putAll(remote);
        await _loadAssets();
      }
    } catch (error) {
      debugPrint('Odoo assets pull failed: $error');
    }
  }

  Future<void> updateAssetStatus(String assetId, AssetStatus status) async {
    final asset = await _repo.getById(assetId);
    if (asset == null) return;
    await _repo.put(_copyWithStatus(asset, status));
    await _loadAssets();
    if (!_club.isConfigured) return;
    try {
      await _club.pushAssetStatus(assetId, status);
    } catch (error) {
      debugPrint('Odoo asset status push failed for $assetId: $error');
    }
  }

  /// Records a cleaning done now (armory workflow) locally and in Odoo.
  Future<void> markAssetCleaned(String assetId) async {
    final asset = await _repo.getById(assetId);
    if (asset == null) return;
    await _repo.put(Asset(
      isarId: asset.isarId,
      id: asset.id,
      serialNumber: asset.serialNumber,
      name: asset.name,
      category: asset.category,
      activityId: asset.activityId,
      status: asset.status,
      lastMaintenance: DateTime.now(),
      nextMaintenance: asset.nextMaintenance,
      imageUrl: asset.imageUrl,
      technicalSpecsJson: asset.technicalSpecsJson,
    ));
    await _loadAssets();
    if (!_club.isConfigured) return;
    try {
      await _club.pushAssetCleaned(assetId);
    } catch (error) {
      debugPrint('Odoo asset cleaning push failed for $assetId: $error');
    }
  }

  Asset _copyWithStatus(Asset asset, AssetStatus status) {
    return Asset(
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
  }
}

final assetsProvider =
    StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  return AssetsNotifier(
    ref.watch(assetRepositoryProvider),
    ref.watch(odooClubServiceProvider),
  );
});
