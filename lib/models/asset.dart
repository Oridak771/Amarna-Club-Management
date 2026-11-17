import 'package:isar/isar.dart';
import 'dart:convert';

part 'asset.g.dart';

enum AssetStatus {
  available, // Disponible (green)
  inUse, // En utilisation (blue)
  maintenance, // En maintenance (orange)
  broken, // En panne / Hors-service (red)
}

@collection
class Asset {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String serialNumber;
  final String name;
  final String
      category; // e.g. "Equipement Piscine", "Arme de poing", "Machine de musculation"
  final String activityId;

  @enumerated
  final AssetStatus status;

  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String? imageUrl;
  final String? technicalSpecsJson;

  /// Set by Odoo when the asset goes `inUse` (e.g. a padel court session).
  final DateTime? inUseSince;

  /// Armory item, flagged by the admin in Odoo.
  final bool isWeapon;

  Asset({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.category,
    required this.activityId,
    required this.status,
    this.lastMaintenance,
    this.nextMaintenance,
    this.imageUrl,
    this.inUseSince,
    this.isWeapon = false,
    Map<String, String>? technicalSpecs,
    String? technicalSpecsJson,
  })  : _technicalSpecs = technicalSpecs,
        technicalSpecsJson = technicalSpecsJson ??
            (technicalSpecs != null ? jsonEncode(technicalSpecs) : null);

  Asset copyWith({
    AssetStatus? status,
    DateTime? lastMaintenance,
    DateTime? inUseSince,
    bool clearInUseSince = false,
  }) {
    return Asset(
      isarId: isarId,
      id: id,
      serialNumber: serialNumber,
      name: name,
      category: category,
      activityId: activityId,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance,
      imageUrl: imageUrl,
      technicalSpecsJson: technicalSpecsJson,
      inUseSince: clearInUseSince ? null : (inUseSince ?? this.inUseSince),
      isWeapon: isWeapon,
    );
  }

  @ignore
  final Map<String, String>? _technicalSpecs;

  @ignore
  Map<String, String>? get technicalSpecs {
    if (_technicalSpecs != null) return _technicalSpecs;
    if (technicalSpecsJson == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(technicalSpecsJson!);
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  String get statusTextFrench {
    switch (status) {
      case AssetStatus.available:
        return "Disponible";
      case AssetStatus.inUse:
        return "En utilisation";
      case AssetStatus.maintenance:
        return "En maintenance";
      case AssetStatus.broken:
        return "Hors-service";
    }
  }
}
