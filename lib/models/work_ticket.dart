import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../theme/app_theme.dart';

part 'work_ticket.g.dart';

enum TicketType {
  anomaly,            // Quick operational issues / anomalies reported on the fly
  preventive,         // Scheduled inspection / check task
  corrective,         // Work order / repair task
}

enum TicketPriority {
  low,      // Faible
  medium,   // Moyen
  high,     // Élevé
  critical, // Critique
}

enum TicketStatus {
  open,       // Ouvert / À faire
  inProgress, // En cours
  resolved,   // Résolu / Réalisé
}

@collection
class WorkTicket {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String title;
  final String description;
  final String activityId;
  final String activityName;
  final String? assetId;
  final String? assetName;

  @enumerated
  final TicketType type;

  @enumerated
  final TicketPriority priority;

  @enumerated
  final TicketStatus status;

  final DateTime dateCreated;
  final DateTime? dateDue;       // For scheduled tasks
  final DateTime? dateCompleted; // For resolved tasks
  final String? imageUrl;
  final String? voiceNoteUrl;
  final String? assignedTechnician;
  final bool syncPending;

  WorkTicket({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.title,
    required this.description,
    required this.activityId,
    required this.activityName,
    this.assetId,
    this.assetName,
    required this.type,
    required this.priority,
    required this.status,
    required this.dateCreated,
    this.dateDue,
    this.dateCompleted,
    this.imageUrl,
    this.voiceNoteUrl,
    this.assignedTechnician,
    this.syncPending = false,
  });

  @ignore
  Color get priorityColor {
    switch (priority) {
      case TicketPriority.low:
        return AppColors.priorityLow;
      case TicketPriority.medium:
        return AppColors.priorityMedium;
      case TicketPriority.high:
        return AppColors.priorityHigh;
      case TicketPriority.critical:
        return AppColors.priorityCritical;
    }
  }

  String get priorityTextFrench {
    switch (priority) {
      case TicketPriority.low:
        return "Faible";
      case TicketPriority.medium:
        return "Moyen";
      case TicketPriority.high:
        return "Élevé";
      case TicketPriority.critical:
        return "Critique";
    }
  }

  String get statusTextFrench {
    switch (status) {
      case TicketStatus.open:
        return type == TicketType.anomaly ? "Ouvert" : "À faire";
      case TicketStatus.inProgress:
        return "En cours";
      case TicketStatus.resolved:
        return type == TicketType.anomaly ? "Résolu" : "Réalisé";
    }
  }

  @ignore
  Color get statusColor {
    switch (status) {
      case TicketStatus.open:
        return type == TicketType.anomaly ? AppColors.danger : AppColors.textSecondary;
      case TicketStatus.inProgress:
        return AppColors.warning;
      case TicketStatus.resolved:
        return AppColors.success;
    }
  }

  String get typeTextFrench {
    switch (type) {
      case TicketType.anomaly:
        return "Anomalie";
      case TicketType.preventive:
        return "Préventif";
      case TicketType.corrective:
        return "Correctif";
    }
  }

  @ignore
  Color get typeColor {
    switch (type) {
      case TicketType.anomaly:
        return AppColors.priorityCritical;
      case TicketType.preventive:
        return AppColors.info;
      case TicketType.corrective:
        return AppColors.accentSecondary;
    }
  }
}
