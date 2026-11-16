import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reservation.dart';
import 'odoo_datetime.dart';
import 'odoo_jsonrpc_service.dart';

final odooReservationServiceProvider = Provider<OdooReservationService>((ref) {
  return OdooReservationService(ref.watch(odooJsonRpcServiceProvider));
});

/// Reservations of the club, stored in `amarna.club.reservation`.
///
/// `start_at` / `end_at` are UTC on the Odoo side and converted here; the
/// status is written as one of the canonical tokens the Odoo model expects.
class OdooReservationService {
  OdooReservationService(this._odoo);

  static const _model = 'amarna.club.reservation';
  static const _fields = [
    'name',
    'mobile_activity_code',
    'activity_id',
    'client_name',
    'people_count',
    'start_at',
    'end_at',
    'status_normalized',
    'notes',
  ];

  final OdooJsonRpcService _odoo;

  /// Reservations whose start falls on the local calendar day [day].
  Future<List<Reservation>> fetchReservationsForDay(DateTime day) async {
    final (start, end) = odooDayBounds(day);
    final rows = await _odoo.searchRead(
      model: _model,
      domain: [
        ['start_at', '>=', start],
        ['start_at', '<', end],
      ],
      fields: _fields,
      order: 'start_at asc',
      limit: 500,
    );
    return rows.map(_mapReservation).whereType<Reservation>().toList();
  }

  Future<int> createReservation({
    required String activityId,
    required String activityName,
    required String clientName,
    required int peopleCount,
    required ReservationStatus status,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) {
    return _odoo.create(
      model: _model,
      values: {
        'name': '$activityName - $clientName',
        'mobile_activity_code': activityId,
        'client_name': clientName,
        'people_count': peopleCount,
        'start_at': toOdooDateTime(startAt),
        'end_at': toOdooDateTime(endAt),
        'status': statusToken(status),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  /// Writes a new status (e.g. check-in) on the remote reservation.
  Future<void> updateReservationStatus(
      int remoteId, ReservationStatus status) async {
    await _odoo.write(
      model: _model,
      id: remoteId,
      values: {'status': statusToken(status)},
    );
  }

  /// Canonical status token understood by `amarna.club.reservation`.
  static String statusToken(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.checkedIn:
        return 'checkedin';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.pending:
      case ReservationStatus.unknown:
        return 'pending';
    }
  }

  Reservation? _mapReservation(Map<String, dynamic> row) {
    final startAt = fromOdooDateTime(row['start_at']);
    final endAt = fromOdooDateTime(row['end_at']);
    if (startAt == null || endAt == null) return null;

    // Odoo returns `false` for empty Char/Text fields: read them as text.
    final activityCode = _text(row['mobile_activity_code']);
    final activityName = _many2oneName(row['activity_id']);
    final clientName = _text(row['client_name']);
    final notes = _text(row['notes']);

    return Reservation(
      remoteId: (row['id'] as num?)?.toInt(),
      title: _text(row['name']).isEmpty ? 'Réservation' : _text(row['name']),
      activityId: activityCode,
      activityName: activityName.isEmpty ? activityCode : activityName,
      clientName: clientName,
      peopleCount: (row['people_count'] as num?)?.toInt() ?? 0,
      status: _parseStatus(_text(row['status_normalized'])),
      startAt: startAt,
      endAt: endAt,
      notes: notes.isEmpty ? null : notes,
    );
  }

  String _text(Object? value) => value is String ? value : '';

  ReservationStatus _parseStatus(String normalized) {
    switch (normalized) {
      case 'checked_in':
        return ReservationStatus.checkedIn;
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'pending':
        return ReservationStatus.pending;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.unknown;
    }
  }

  String _many2oneName(dynamic value) {
    if (value is List && value.length >= 2 && value[1] is String) {
      return value[1] as String;
    }
    return '';
  }
}
