import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/reservation.dart';
import '../services/odoo_reservation_service.dart';

final reservationsRefreshProvider = StateProvider<int>((ref) => 0);

/// Reservations for one day.
///
/// IMPORTANT: the family key must be a normalized date (midnight) — callers
/// should watch via [todaysReservationsProvider] or normalize themselves.
/// Falls back to local demo data when Odoo is not configured, so the UI
/// always shows concrete content.
final reservationsForDateProvider =
    FutureProvider.family<List<Reservation>, DateTime>((ref, date) async {
  ref.watch(reservationsRefreshProvider);

  final normalized = DateTime(date.year, date.month, date.day);
  if (!AppEnvironment.isOdooConfigured) {
    return _demoReservationsForDay(normalized);
  }
  try {
    return await ref
        .read(odooReservationServiceProvider)
        .fetchReservationsForDay(normalized);
  } catch (_) {
    // Odoo is reachable but the reservation model isn't available yet
    // (Calendar not installed / no booking model). Keep the UI populated
    // with demo sessions instead of showing an error.
    return _demoReservationsForDay(normalized);
  }
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

// ---------------------------------------------------------------------------
// Demo data (used until Odoo JSON-RPC is configured in .env)
// ---------------------------------------------------------------------------

List<Reservation> _demoReservationsForDay(DateTime day) {
  // No sessions on past days in demo mode; keep the planner honest.
  final today = DateTime.now();
  final isPast =
      day.isBefore(DateTime(today.year, today.month, today.day));
  if (isPast) return const [];

  Reservation make(
    int id,
    int startHour,
    int startMinute,
    int durationMinutes,
    String activityId,
    String activityName,
    String client,
    int people,
    ReservationStatus status,
  ) {
    final start =
        DateTime(day.year, day.month, day.day, startHour, startMinute);
    return Reservation(
      remoteId: day.day * 1000 + id,
      title: '$activityName - $client',
      activityId: activityId,
      activityName: activityName,
      clientName: client,
      peopleCount: people,
      status: status,
      startAt: start,
      endAt: start.add(Duration(minutes: durationMinutes)),
    );
  }

  // Rotate demo content a little by weekday so days look different.
  final wd = day.weekday;
  return [
    make(1, 9, 0, 90, 'horses', 'Équitation', 'Club Junior — cours poney',
        6 + (wd % 3), ReservationStatus.confirmed),
    make(2, 10, 0, 60, 'pool', 'Piscine', 'Aquagym Seniors', 12,
        ReservationStatus.confirmed),
    make(3, 11, 30, 90, 'padel', 'Padel', 'Karim B. & invités', 4,
        ReservationStatus.confirmed),
    if (wd != DateTime.sunday)
      make(4, 14, 0, 120, 'paintball', 'Paintball',
          'Anniversaire Yacine (groupe)', 10 + (wd % 4),
          ReservationStatus.pending),
    make(5, 16, 0, 60, 'shooting', 'Stand de Tir', 'Session découverte', 4,
        ReservationStatus.confirmed),
    if (wd == DateTime.saturday || wd == DateTime.wednesday)
      make(6, 17, 30, 60, 'gym', 'Salle de Gym', 'Coaching privé — S. Alit', 1,
          ReservationStatus.confirmed),
  ];
}
