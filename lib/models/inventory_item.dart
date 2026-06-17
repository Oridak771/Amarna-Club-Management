import 'package:isar/isar.dart';

part 'inventory_item.g.dart';

@collection
class InventoryItem {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String name;
  final String activityId;
  final String activityName;
  final int currentStock;
  final int lowThreshold;
  final String unitName; // e.g. "unités", "kg", "boîtes"

  InventoryItem({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.name,
    required this.activityId,
    required this.activityName,
    required this.currentStock,
    required this.lowThreshold,
    required this.unitName,
  });

  bool get isLowStock => currentStock <= lowThreshold;
  bool get isOutOfStock => currentStock <= 0;

  InventoryItem copyWith({
    Id? isarId,
    String? id,
    String? name,
    String? activityId,
    String? activityName,
    int? currentStock,
    int? lowThreshold,
    String? unitName,
  }) {
    return InventoryItem(
      isarId: isarId ?? this.isarId,
      id: id ?? this.id,
      name: name ?? this.name,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      currentStock: currentStock ?? this.currentStock,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      unitName: unitName ?? this.unitName,
    );
  }
}
