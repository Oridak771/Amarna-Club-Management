import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../repositories/asset_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';
import '../services/odoo_jsonrpc_service.dart';

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
      reportSyncIssue('Équipements (lecture)', error);
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
      reportSyncIssue('Statut équipement « $assetId »', error);
    }
  }

  /// Records a cleaning done now (armory workflow) locally and in Odoo.
  Future<void> markAssetCleaned(String assetId) async {
    final asset = await _repo.getById(assetId);
    if (asset == null) return;
    await _repo.put(asset.copyWith(lastMaintenance: DateTime.now()));
    await _loadAssets();
    if (!_club.isConfigured) return;
    try {
      await _club.pushAssetCleaned(assetId);
    } catch (error) {
      reportSyncIssue('Nettoyage « $assetId »', error);
    }
  }

  /// Mirrors what Odoo does: `inUseSince` is stamped when an asset goes in
  /// use and cleared when it leaves that status.
  Asset _copyWithStatus(Asset asset, AssetStatus status) {
    if (status == AssetStatus.inUse) {
      return asset.status == AssetStatus.inUse
          ? asset
          : asset.copyWith(status: status, inUseSince: DateTime.now());
    }
    return asset.copyWith(status: status, clearInUseSince: true);
  }
}

final assetsProvider =
    StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  return AssetsNotifier(
    ref.watch(assetRepositoryProvider),
    ref.watch(odooClubServiceProvider),
  );
});
