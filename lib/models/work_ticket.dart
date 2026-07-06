import 'package:isar/isar.dart';

part 'work_ticket.g.dart';

enum TicketType {
  anomaly, // Incident / anomaly reported on the fly
  preventive, // Scheduled inspection / check task
  corrective, // Work order / repair task
}

enum TicketPriority {
  low, // Faible
  medium, // Moyen
  high, // Élevé
  critical, // Critique
}

enum TicketStatus {
  open, // Ouvert / À faire
  inProgress, // En cours
  resolved, // Résolu / Réalisé
}

enum TicketEventType {
  created,
  statusChanged,
  commented,
  photoAdded,
  assigned,
}

/// A single entry in a ticket's history timeline.
@embedded
class TicketEvent {
  @enumerated
  TicketEventType type = TicketEventType.commented;
  String? message;
  String? author;
  DateTime? at;

  TicketEvent();

  TicketEvent.make({
    required this.type,
    this.message,
    this.author,
    DateTime? at,
  }) : at = at ?? DateTime.now();
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
  final DateTime? dateDue; // For scheduled tasks
  final DateTime? dateCompleted; // For resolved tasks
  final List<String> photoPaths;
  final List<TicketEvent> events;
  final String? assignedTechnician;

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
    this.photoPaths = const [],
    this.events = const [],
    this.assignedTechnician,
  });

  WorkTicket copyWith({
    TicketStatus? status,
    TicketPriority? priority,
    DateTime? dateCompleted,
    List<String>? photoPaths,
    List<TicketEvent>? events,
    String? assignedTechnician,
  }) {
    return WorkTicket(
      isarId: isarId,
      id: id,
      title: title,
      description: description,
      activityId: activityId,
      activityName: activityName,
      assetId: assetId,
      assetName: assetName,
      type: type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateCreated: dateCreated,
      dateDue: dateDue,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      photoPaths: photoPaths ?? this.photoPaths,
      events: events ?? this.events,
      assignedTechnician: assignedTechnician ?? this.assignedTechnician,
    );
  }

  bool get isOverdue =>
      status != TicketStatus.resolved &&
      dateDue != null &&
      dateDue!.isBefore(DateTime.now());

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
}
