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
    Map<String, String>? technicalSpecs,
    String? technicalSpecsJson,
  })  : _technicalSpecs = technicalSpecs,
        technicalSpecsJson = technicalSpecsJson ??
            (technicalSpecs != null ? jsonEncode(technicalSpecs) : null);

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
