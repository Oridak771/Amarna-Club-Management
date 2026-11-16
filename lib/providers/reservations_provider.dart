import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/reservation.dart';
import '../services/odoo_reservation_service.dart';

final reservationsRefreshProvider = StateProvider<int>((ref) => 0);

/// Reservations for one local calendar day, read from Odoo.
///
/// The family key must be a normalized date (midnight): callers should watch
/// [todaysReservationsProvider] or normalize the date themselves.
///
/// Errors are not hidden: when Odoo cannot be reached the screen shows the
/// error and a retry, instead of invented bookings.
final reservationsForDateProvider =
    FutureProvider.family<List<Reservation>, DateTime>((ref, date) async {
  ref.watch(reservationsRefreshProvider);

  final normalized = DateTime(date.year, date.month, date.day);
  if (!AppEnvironment.isOdooConfigured) {
    throw StateError('Serveur Odoo non configuré : planning indisponible.');
  }
  return ref
      .read(odooReservationServiceProvider)
      .fetchReservationsForDay(normalized);
});

/// Today's reservations with a stable cache key — watching
/// `reservationsForDateProvider(DateTime.now())` directly would create a new
/// family key on every rebuild and restart the fetch forever.
final todaysReservationsProvider = FutureProvider<List<Reservation>>((ref) {
  final now = DateTime.now();
  return ref.watch(
    reservationsForDateProvider(DateTime(now.year, now.month, now.day)).future,
  );
});
