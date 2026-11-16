import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/work_ticket.dart';
import 'odoo_datetime.dart';
import 'odoo_jsonrpc_service.dart';

final ticketSyncServiceProvider = Provider<TicketSyncService>((ref) {
  return TicketSyncService(ref.watch(odooJsonRpcServiceProvider));
});

/// Pushes tablet tickets to `amarna.club.intervention`.
///
/// A ticket is matched on its `mobile_id` (the id the tablet generated), so a
/// retry after a network failure updates the same record instead of creating
/// a duplicate. Tickets pulled from Odoo without a `mobile_id` carry an
/// `odoo-<id>` identifier and are updated by their Odoo id.
class TicketSyncService {
  TicketSyncService(this._odoo);

  static const _model = 'amarna.club.intervention';

  final OdooJsonRpcService _odoo;

  Future<void> syncTicket(WorkTicket ticket) async {
    if (ticket.id.startsWith('odoo-')) {
      final remoteId = int.tryParse(ticket.id.substring('odoo-'.length));
      if (remoteId == null) {
        throw StateError('Identifiant de ticket invalide : ${ticket.id}');
      }
      await _odoo.write(model: _model, id: remoteId, values: _mutableFields(ticket));
      return;
    }

    final existingId = await _findRemoteId(ticket.id);
    if (existingId == null) {
      await _odoo.create(
        model: _model,
        values: {
          ..._mutableFields(ticket),
          'mobile_id': ticket.id,
          'name': ticket.title,
          'description': ticket.description,
        },
      );
    } else {
      await _odoo.write(
        model: _model,
        id: existingId,
        values: _mutableFields(ticket),
      );
    }
  }

  Future<int?> _findRemoteId(String mobileId) async {
    final rows = await _odoo.searchRead(
      model: _model,
      domain: [
        ['mobile_id', '=', mobileId],
      ],
      fields: const ['id'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return (rows.first['id'] as num).toInt();
  }

  /// Fields the tablet may change after creation. Title and description are
  /// only written at creation, so an edit made in Odoo is not overwritten.
  Map<String, dynamic> _mutableFields(WorkTicket ticket) {
    return {
      'type': ticket.type.name,
      'status': ticket.status.name,
      'priority': ticket.priority.name,
      'mobile_activity_code': ticket.activityId,
      'mobile_asset_code': ticket.assetId ?? '',
      'assigned_to': ticket.assignedTechnician ?? '',
      'date_due': ticket.dateDue == null
          ? false
          : toOdooDateTime(ticket.dateDue!),
    };
  }
}
