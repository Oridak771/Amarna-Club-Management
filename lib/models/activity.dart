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

  /// Dedicated screen chosen by the admin in Odoo (`pool`, `horses`,
  /// `armory`, `padel`, `paintball`, `gym`), empty when there is none.
  final String screenKey;
  final String screenLabel;

  /// Optional planned offline interval from Odoo.
  final DateTime? closureStart;
  final DateTime? closureEnd;

  Activity({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.name,
    required this.iconKey,
    required this.status,
    required this.currentOccupancy,
    required this.maxCapacity,
    required this.assignedStaff,
    this.screenKey = '',
    this.screenLabel = '',
    this.closureStart,
    this.closureEnd,
  });

  Activity copyWith({ActivityStatus? status, int? currentOccupancy}) {
    return Activity(
      isarId: isarId,
      id: id,
      name: name,
      iconKey: iconKey,
      status: status ?? this.status,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      maxCapacity: maxCapacity,
      assignedStaff: assignedStaff,
      screenKey: screenKey,
      screenLabel: screenLabel,
      closureStart: closureStart,
      closureEnd: closureEnd,
    );
  }

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

  /// Mirrors `amarna.club.activity.is_available_at` on the Odoo side: open
  /// and warning activities take bookings, and a booking may not overlap the
  /// closure window (a booking ending exactly when the closure starts is fine).
  bool isAvailableAt(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return false;
    if (status != ActivityStatus.open && status != ActivityStatus.warning) {
      return false;
    }
    final from = closureStart;
    if (from == null) return true;
    final until = closureEnd;
    if (until == null) return !end.isAfter(from);
    return !(start.isBefore(until) && end.isAfter(from));
  }
}
