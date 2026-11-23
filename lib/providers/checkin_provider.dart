import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/reservation.dart';
import '../services/odoo_jsonrpc_service.dart';
import '../services/odoo_reservation_service.dart';
import 'activities_provider.dart';
import 'reservations_provider.dart';

/// Tracks which reservations have been checked in during the day.
///
/// Odoo is the source of truth: the check-in is written first, and Odoo
/// itself deducts the sessions and bumps the activity occupancy. Only after
/// that succeeds are the local views refreshed, so the tablet never shows an
/// arrival that Odoo refused (e.g. no sessions left on the subscription).
class CheckinNotifier extends StateNotifier<Set<int>> {
  CheckinNotifier(this._ref) : super({});

  final Ref _ref;

  bool isCheckedIn(Reservation reservation) =>
      reservation.status == ReservationStatus.checkedIn ||
      (reservation.remoteId != null && state.contains(reservation.remoteId));

  /// Throws [OdooException] (with Odoo's message) when the check-in is refused.
  Future<void> checkIn(Reservation reservation) async {
    final remoteId = reservation.remoteId;
    if (remoteId == null || state.contains(remoteId)) return;
    if (!AppEnvironment.isOdooConfigured) {
      throw const OdooException('Serveur Odoo non configuré : check-in impossible.');
    }

    await _ref
        .read(odooReservationServiceProvider)
        .updateReservationStatus(remoteId, ReservationStatus.checkedIn);

    state = {...state, remoteId};
    await _ref.read(activitiesProvider.notifier).refreshFromOdoo();
    _ref.read(reservationsRefreshProvider.notifier).state++;
  }
}

final checkinProvider =
    StateNotifierProvider<CheckinNotifier, Set<int>>((ref) {
  return CheckinNotifier(ref);
});

/// Checks a reservation in and tells the user the outcome. Odoo's refusal
/// (e.g. no sessions left) is shown with its own message.
Future<void> runCheckIn(
  BuildContext context,
  CheckinNotifier notifier,
  Reservation reservation,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;
  try {
    await notifier.checkIn(reservation);
    messenger.showSnackBar(SnackBar(
      content: Text('${reservation.clientName} — arrivée enregistrée ✓'),
    ));
  } on OdooException catch (error) {
    messenger.showSnackBar(SnackBar(
      // Odoo's refusals already start with "Arrivée refusée"; do not say it twice.
      content: Text(error.message.startsWith('Arrivée refusée')
          ? error.message
          : 'Check-in refusé : ${error.message}'),
      backgroundColor: errorColor,
    ));
  }
}
