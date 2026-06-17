import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../theme/app_theme.dart';
import 'incident.dart'; // Reuse IncidentPriority for consistency

part 'maintenance_task.g.dart';

enum MaintenanceType {
  preventive, // Préventif
  corrective, // Correctif
}

enum MaintenanceStatus {
  todo,       // À faire
  inProgress, // En cours
  done,       // Réalisé
}

@collection
class MaintenanceTask {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String title;
  final String description;
  final String assetId;
  final String assetName;
  final String activityId;
  
  @enumerated
  final MaintenanceType type;
  
  @enumerated
  final IncidentPriority priority;
  
  @enumerated
  final MaintenanceStatus status;
  
  final DateTime dateDue;
  final DateTime? dateCompleted;
  final String? assignedTechnician;
  final bool syncPending;

  MaintenanceTask({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.title,
    required this.description,
    required this.assetId,
    required this.assetName,
    required this.activityId,
    required this.type,
    required this.priority,
    required this.status,
    required this.dateDue,
    this.dateCompleted,
    this.assignedTechnician,
    this.syncPending = false,
  });

  String get typeTextFrench {
    switch (type) {
      case MaintenanceType.preventive:
        return "Préventif";
      case MaintenanceType.corrective:
        return "Correctif";
    }
  }

  @ignore
  Color get typeColor {
    switch (type) {
      case MaintenanceType.preventive:
        return AppColors.info;
      case MaintenanceType.corrective:
        return AppColors.accentSecondary;
    }
  }

  String get statusTextFrench {
    switch (status) {
      case MaintenanceStatus.todo:
        return "À faire";
      case MaintenanceStatus.inProgress:
        return "En cours";
      case MaintenanceStatus.done:
        return "Réalisé";
    }
  }

  @ignore
  Color get statusColor {
    switch (status) {
      case MaintenanceStatus.todo:
        return AppColors.textSecondary;
      case MaintenanceStatus.inProgress:
        return AppColors.warning;
      case MaintenanceStatus.done:
        return AppColors.success;
    }
  }
}
