import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../theme/app_theme.dart';

part 'activity.g.dart';

enum ActivityStatus {
  open,        // Ouvert (green)
  closed,      // Fermé (red)
  warning,     // Attention (amber)
  maintenance, // Maintenance (blue)
}

@collection
class Activity {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String name;       // e.g. "Piscine", "Équitation"
  final String iconKey;    // e.g. "pool", "horses"
  
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
  double get occupancyPercentage => maxCapacity > 0 ? (currentOccupancy / maxCapacity) : 0.0;

  @ignore
  Color get statusColor {
    switch (status) {
      case ActivityStatus.open:
        return AppColors.success;
      case ActivityStatus.closed:
        return AppColors.danger;
      case ActivityStatus.warning:
        return AppColors.warning;
      case ActivityStatus.maintenance:
        return AppColors.info;
    }
  }

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

  @ignore
  IconData get iconData {
    switch (iconKey) {
      case 'pool':
      case 'piscine':
        return Icons.pool;
      case 'horses':
      case 'chevaux':
        return Icons.pets;
      case 'paintball':
        return Icons.adjust;
      case 'shooting':
      case 'tir':
        return Icons.gps_fixed;
      case 'gym':
        return Icons.fitness_center;
      case 'padel':
        return Icons.sports_tennis;
      default:
        return Icons.help_outline;
    }
  }
}
