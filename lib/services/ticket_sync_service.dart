import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_environment.dart';
import '../models/work_ticket.dart';
import 'odoo_jsonrpc_service.dart';

final ticketSyncServiceProvider = Provider<TicketSyncService>((ref) {
  return TicketSyncService(ref.watch(odooJsonRpcServiceProvider));
});

class TicketSyncService {
  TicketSyncService(this._odoo);

  final OdooJsonRpcService _odoo;

  Future<void> syncTicket(WorkTicket ticket) async {
    // Tickets pulled from Odoo carry an 'odoo-<id>' identifier: write the
    // mapped fields straight back to that record instead of re-creating it
    // (its name/description belong to the Odoo side).
    if (ticket.id.startsWith('odoo-')) {
      final remoteId = int.tryParse(ticket.id.substring('odoo-'.length));
      if (remoteId != null) {
        final values = _buildMappedFields(ticket);
        if (values.isNotEmpty) {
          await _odoo.write(
            model: AppEnvironment.odooTicketModel,
            id: remoteId,
            values: values,
          );
        }
        return;
      }
    }

    final existingId = await _findRemoteTicketId(ticket.id);
    final values = _buildPayload(ticket);

    if (existingId == null) {
      await _odoo.create(
        model: AppEnvironment.odooTicketModel,
        values: values,
      );
      return;
    }

    await _odoo.write(
      model: AppEnvironment.odooTicketModel,
      id: existingId,
      values: values,
    );
  }

  Future<int?> _findRemoteTicketId(String mobileId) async {
    final rows = await _odoo.searchRead(
      model: AppEnvironment.odooTicketModel,
      domain: [
        [
          'description',
          'ilike',
          '[Mobile ID: $mobileId]',
        ],
      ],
      fields: const ['id'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return (rows.first['id'] as num?)?.toInt();
  }

  Map<String, dynamic> _buildPayload(WorkTicket ticket) {
    return {
      'name': '[${ticket.id}] ${ticket.title}',
      'description': _buildDescription(ticket),
      ..._buildMappedFields(ticket),
    };
  }

  /// Only the .env-mapped fields (status, priority, due date, activity,
  /// assignee) — used both for full pushes and for updates of tickets that
  /// originate in Odoo.
  Map<String, dynamic> _buildMappedFields(WorkTicket ticket) {
    final payload = <String, dynamic>{};

    _putIfConfigured(
      payload,
      AppEnvironment.odooTicketDueField,
      ticket.dateDue != null ? _formatDateTime(ticket.dateDue!) : null,
    );
    _putIfConfigured(
      payload,
      AppEnvironment.odooTicketStatusField,
      ticket.status.name,
    );
    _putIfConfigured(
      payload,
      AppEnvironment.odooTicketPriorityField,
      ticket.priority.name,
    );
    _putIfConfigured(
      payload,
      AppEnvironment.odooTicketActivityField,
      ticket.activityId,
    );
    _putIfConfigured(
      payload,
      AppEnvironment.odooTicketAssigneeField,
      ticket.assignedTechnician,
    );

    return payload;
  }

  String _buildDescription(WorkTicket ticket) {
    final buffer = StringBuffer()
      ..writeln('[Mobile ID: ${ticket.id}]')
      ..writeln('Activity: ${ticket.activityName} (${ticket.activityId})')
      ..writeln('Type: ${ticket.type.name}')
      ..writeln('Priority: ${ticket.priority.name}')
      ..writeln('Status: ${ticket.status.name}')
      ..writeln('Created At: ${_formatDateTime(ticket.dateCreated)}');

    if (ticket.dateDue != null) {
      buffer.writeln('Due At: ${_formatDateTime(ticket.dateDue!)}');
    }
    if (ticket.assignedTechnician != null &&
        ticket.assignedTechnician!.isNotEmpty) {
      buffer.writeln('Assigned: ${ticket.assignedTechnician}');
    }
    if (ticket.assetName != null && ticket.assetName!.isNotEmpty) {
      buffer.writeln('Asset: ${ticket.assetName} (${ticket.assetId ?? ''})');
    }

    buffer
      ..writeln()
      ..write(ticket.description);

    return buffer.toString();
  }

  String _formatDateTime(DateTime value) {
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
