import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_environment.dart';
import '../models/reservation.dart';
import 'odoo_jsonrpc_service.dart';

final odooReservationServiceProvider = Provider<OdooReservationService>((ref) {
  return OdooReservationService(ref.watch(odooJsonRpcServiceProvider));
});

class OdooReservationService {
  OdooReservationService(this._odoo);

  final OdooJsonRpcService _odoo;

  Future<List<Reservation>> fetchReservationsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final fields = <String>{
      'id',
      'name',
      AppEnvironment.odooReservationStartField,
      AppEnvironment.odooReservationEndField,
      if (AppEnvironment.odooReservationActivityField.isNotEmpty)
        AppEnvironment.odooReservationActivityField,
      if (AppEnvironment.odooReservationClientField.isNotEmpty)
        AppEnvironment.odooReservationClientField,
      if (AppEnvironment.odooReservationPeopleCountField.isNotEmpty)
        AppEnvironment.odooReservationPeopleCountField,
      if (AppEnvironment.odooReservationStatusField.isNotEmpty)
        AppEnvironment.odooReservationStatusField,
      if (AppEnvironment.odooReservationNotesField.isNotEmpty)
        AppEnvironment.odooReservationNotesField,
    }.toList();

    final rows = await _odoo.searchRead(
      model: AppEnvironment.odooReservationModel,
      domain: [
        [
          AppEnvironment.odooReservationStartField,
          '>=',
          _formatOdooDateTime(start),
        ],
        [
          AppEnvironment.odooReservationStartField,
          '<',
          _formatOdooDateTime(end),
        ],
      ],
      fields: fields,
      order: '${AppEnvironment.odooReservationStartField} asc',
    );

    return rows.map(_mapReservation).toList();
  }

  Future<int> createReservation({
    required String activityId,
    required String activityName,
    required String clientName,
    required int peopleCount,
    required String status,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) {
    final payload = <String, dynamic>{
      'name': '$activityName - $clientName',
      AppEnvironment.odooReservationStartField: _formatOdooDateTime(startAt),
      AppEnvironment.odooReservationEndField: _formatOdooDateTime(endAt),
    };

    _putIfConfigured(
        payload, AppEnvironment.odooReservationActivityField, activityId);
    _putIfConfigured(
        payload, AppEnvironment.odooReservationClientField, clientName);
    _putIfConfigured(
        payload, AppEnvironment.odooReservationPeopleCountField, peopleCount);
    _putIfConfigured(
        payload, AppEnvironment.odooReservationStatusField, status);
    _putIfConfigured(
      payload,
      AppEnvironment.odooReservationNotesField,
      notes?.trim().isEmpty == true ? null : notes,
    );

    return _odoo.create(
      model: AppEnvironment.odooReservationModel,
      values: payload,
    );
  }

  /// Writes a new status value on the remote reservation.
  /// No-op when the status field is not mapped in the environment.
  Future<void> updateReservationStatus(int remoteId, String status) async {
    if (AppEnvironment.odooReservationStatusField.isEmpty) return;
    await _odoo.write(
      model: AppEnvironment.odooReservationModel,
      id: remoteId,
      values: {AppEnvironment.odooReservationStatusField: status},
    );
  }

  Reservation _mapReservation(Map<String, dynamic> row) {
    final title = row['name']?.toString() ?? 'Reservation';
    final activityValue =
        row[AppEnvironment.odooReservationActivityField]?.toString();
    final clientValue =
        row[AppEnvironment.odooReservationClientField]?.toString();
    final statusValue =
        row[AppEnvironment.odooReservationStatusField]?.toString();
    final notesValue =
        row[AppEnvironment.odooReservationNotesField]?.toString();
    final peopleValue = row[AppEnvironment.odooReservationPeopleCountField];

    return Reservation(
      remoteId: (row['id'] as num?)?.toInt(),
      title: title,
      activityId: activityValue ?? '',
      activityName: activityValue ?? _inferActivityName(title),
      clientName: clientValue ?? _inferClientName(title),
      peopleCount: peopleValue is num ? peopleValue.toInt() : 0,
      status: _parseStatus(statusValue),
      startAt: DateTime.parse(
          row[AppEnvironment.odooReservationStartField].toString()),
      endAt: DateTime.parse(
          row[AppEnvironment.odooReservationEndField].toString()),
      notes: notesValue,
    );
  }

  ReservationStatus _parseStatus(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.contains('check') || normalized.contains('arriv')) {
      return ReservationStatus.checkedIn;
    }
    if (normalized.contains('confirm')) {
      return ReservationStatus.confirmed;
    }
    if (normalized.contains('attente') || normalized.contains('pending')) {
      return ReservationStatus.pending;
    }
    if (normalized.contains('cancel') || normalized.contains('annul')) {
      return ReservationStatus.cancelled;
    }

    return ReservationStatus.unknown;
  }

  String _inferActivityName(String title) {
    final parts = title.split(' - ');
    return parts.isNotEmpty ? parts.first : title;
  }

  String _inferClientName(String title) {
    final parts = title.split(' - ');
    return parts.length > 1 ? parts.sublist(1).join(' - ') : title;
  }

  String _formatOdooDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
  }

  void _putIfConfigured(
    Map<String, dynamic> payload,
    String field,
    Object? value,
  ) {
    if (field.isEmpty || value == null) {
      return;
    }

    payload[field] = value;
  }
}
