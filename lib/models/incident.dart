import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../theme/app_theme.dart';

part 'incident.g.dart';

enum IncidentPriority {
  low,      // Faible
  medium,   // Moyen
  high,     // Élevé
  critical, // Critique
}

enum IncidentStatus {
  open,       // Ouvert
  inProgress, // En cours
  resolved,   // Résolu
}

@collection
class Incident {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String title;
  final String description;
  final String activityId;
  final String activityName;
  
  @enumerated
  final IncidentPriority priority;
  
  @enumerated
  final IncidentStatus status;
  
  final DateTime dateCreated;
  final String? imageUrl;
  final String? voiceNoteUrl;
  final String? assignedTechnician;
  final bool syncPending; // True if created offline and not yet synced to Odoo

  Incident({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.title,
    required this.description,
    required this.activityId,
    required this.activityName,
    required this.priority,
    required this.status,
    required this.dateCreated,
    this.imageUrl,
    this.voiceNoteUrl,
    this.assignedTechnician,
    this.syncPending = false,
  });

  @ignore
  Color get priorityColor {
    switch (priority) {
      case IncidentPriority.low:
        return AppColors.priorityLow;
      case IncidentPriority.medium:
        return AppColors.priorityMedium;
      case IncidentPriority.high:
        return AppColors.priorityHigh;
      case IncidentPriority.critical:
        return AppColors.priorityCritical;
    }
  }

  String get priorityTextFrench {
    switch (priority) {
      case IncidentPriority.low:
        return "Faible";
      case IncidentPriority.medium:
        return "Moyen";
      case IncidentPriority.high:
        return "Élevé";
      case IncidentPriority.critical:
        return "Critique";
    }
  }

  String get statusTextFrench {
    switch (status) {
      case IncidentStatus.open:
        return "Ouvert";
      case IncidentStatus.inProgress:
        return "En cours";
      case IncidentStatus.resolved:
        return "Résolu";
    }
  }

  @ignore
  Color get statusColor {
    switch (status) {
      case IncidentStatus.open:
        return AppColors.danger;
      case IncidentStatus.inProgress:
        return AppColors.warning;
      case IncidentStatus.resolved:
        return AppColors.success;
    }
  }
}
