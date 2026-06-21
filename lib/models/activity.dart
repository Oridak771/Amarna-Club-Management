import 'package:isar/isar.dart';

part 'activity.g.dart';

enum ActivityStatus {
  open, // Ouvert (green)
  closed, // Fermé (red)
  warning, // Attention (amber)
  maintenance, // Maintenance (blue)
}

@collection
class Activity {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String name; // e.g. "Piscine", "Équitation"
  final String iconKey; // e.g. "pool", "horses"

  @enumerated
  final ActivityStatus status;

  final int currentOccupancy;
  final int maxCapacity;
  final String assignedStaff;

  Activity({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.name,
    required this.iconKey,
    required this.status,
    required this.currentOccupancy,
    required this.maxCapacity,
    required this.assignedStaff,
  });

  @ignore
  double get occupancyPercentage =>
      maxCapacity > 0 ? (currentOccupancy / maxCapacity) : 0.0;

  String get statusTextFrench {
    switch (status) {
      case ActivityStatus.open:
        return "Ouvert";
      case ActivityStatus.closed:
        return "Fermé";
      case ActivityStatus.warning:
        return "Attention";
      case ActivityStatus.maintenance:
        return "En Maintenance";
    }
  }
}
