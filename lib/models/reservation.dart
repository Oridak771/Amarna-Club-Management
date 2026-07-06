enum ReservationStatus {
  confirmed,
  pending,
  cancelled,
  checkedIn,
  unknown,
}

class Reservation {
  final int? remoteId;
  final String title;
  final String activityId;
  final String activityName;
  final String clientName;
  final int peopleCount;
  final ReservationStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final String? notes;

  const Reservation({
    this.remoteId,
    required this.title,
    required this.activityId,
    required this.activityName,
    required this.clientName,
    required this.peopleCount,
    required this.status,
    required this.startAt,
    required this.endAt,
    this.notes,
  });

  String get statusLabel {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'Confirmé';
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.cancelled:
        return 'Annulé';
      case ReservationStatus.checkedIn:
        return 'Arrivé';
      case ReservationStatus.unknown:
        return 'Inconnu';
    }
  }
}
