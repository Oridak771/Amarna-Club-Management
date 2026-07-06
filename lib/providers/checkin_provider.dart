import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/reservation.dart';
import '../services/odoo_reservation_service.dart';
import 'activities_provider.dart';

/// Tracks which reservations have been checked in during the day.
///
/// The local set gives instant UI feedback; when Odoo is configured the
/// status is also written remotely and the activity occupancy is bumped.
class CheckinNotifier extends StateNotifier<Set<int>> {
  CheckinNotifier(this._ref) : super({});

  final Ref _ref;

  bool isCheckedIn(Reservation reservation) =>
      reservation.status == ReservationStatus.checkedIn ||
      (reservation.remoteId != null && state.contains(reservation.remoteId));

  Future<void> checkIn(Reservation reservation) async {
    final remoteId = reservation.remoteId;
    if (remoteId == null || state.contains(remoteId)) return;

    state = {...state, remoteId};

    // Reflect arrival in the activity occupancy counter.
    final activities = _ref.read(activitiesProvider);
    final match = activities.where(
      (a) =>
          a.id == reservation.activityId ||
          a.name.toLowerCase() == reservation.activityName.toLowerCase(),
    );
    if (match.isNotEmpty) {
      final activity = match.first;
      await _ref.read(activitiesProvider.notifier).updateOccupancy(
            activity.id,
            activity.currentOccupancy + reservation.peopleCount.clamp(1, 999),
          );
    }

    if (!AppEnvironment.isOdooConfigured) return;
    try {
      await _ref
          .read(odooReservationServiceProvider)
          .updateReservationStatus(remoteId, 'checkedin');
    } catch (error) {
      debugPrint('Odoo check-in failed for reservation $remoteId: $error');
    }
  }
}

final checkinProvider =
    StateNotifierProvider<CheckinNotifier, Set<int>>((ref) {
  return CheckinNotifier(ref);
});
