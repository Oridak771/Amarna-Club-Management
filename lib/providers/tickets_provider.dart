import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_ticket.dart';
import '../repositories/ticket_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';
import '../services/ticket_sync_service.dart';
import '../services/odoo_jsonrpc_service.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(isarProvider));
});

class TicketsNotifier extends StateNotifier<List<WorkTicket>> {
  final TicketRepository _repo;
  final TicketSyncService _odooSync;
  final OdooClubService _club;

  TicketsNotifier(this._repo, this._odooSync, this._club) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await loadTickets();
    await pullFromOdoo();
  }

  Future<void> loadTickets() async {
    state = await _repo.getAll();
  }

  /// Two-way sync with Odoo.
  ///
  /// Local changes are pushed first. Then the Odoo state is merged in: new
  /// tickets are added, and status/priority/assignee changes made in the Odoo
  /// back office are adopted. A ticket that still has a local change waiting
  /// to be pushed is never overwritten, so an offline edit cannot be reverted.
  Future<void> pullFromOdoo() async {
    if (!_club.isConfigured) return;
    await flushPending();
    try {
      final remote = await _club.fetchInterventions();
      final localById = {
        for (final ticket in await _repo.getAll()) ticket.id: ticket,
      };
      for (final ticket in remote) {
        final local = localById[ticket.id];
        if (local == null) {
          await _repo.put(ticket);
          continue;
        }
        if (local.syncPending) continue;
        final changed = local.status != ticket.status ||
            local.priority != ticket.priority ||
            local.assignedTechnician != ticket.assignedTechnician ||
            local.dateDue != ticket.dateDue ||
            local.dateCompleted != ticket.dateCompleted;
        if (!changed) continue;
        await _repo.put(local.copyWith(
          status: ticket.status,
          priority: ticket.priority,
          dateDue: ticket.dateDue,
          dateCompleted: ticket.dateCompleted,
          assignedTechnician: ticket.assignedTechnician,
          events: [
            ...local.events,
            TicketEvent.make(
              type: TicketEventType.statusChanged,
              message: 'Mis à jour depuis Odoo',
              author: ticket.assignedTechnician,
            ),
          ],
        ));
      }
      await loadTickets();
    } catch (error) {
      reportSyncIssue('Interventions (lecture)', error);
    }
  }

  /// Retries every local change that has not reached Odoo yet.
  Future<void> flushPending() async {
    if (!_club.isConfigured) return;
    final pending = (await _repo.getAll()).where((t) => t.syncPending).toList();
    for (final ticket in pending) {
      await _pushToOdoo(ticket);
    }
    await loadTickets();
  }

  /// Pushes [ticket] to Odoo. On success its pending flag is cleared, unless
  /// the ticket was changed again while the request was in flight.
  Future<void> _pushToOdoo(WorkTicket ticket) async {
    if (!_club.isConfigured) return;
    try {
      await _odooSync.syncTicket(ticket);
      final latest = await _repo.getById(ticket.id);
      if (latest != null &&
          latest.syncPending &&
          latest.status == ticket.status &&
          latest.priority == ticket.priority &&
          latest.assignedTechnician == ticket.assignedTechnician &&
          latest.dateDue == ticket.dateDue &&
          latest.events.length == ticket.events.length) {
        await _repo.put(latest.copyWith(syncPending: false));
      }
    } catch (error) {
      // The ticket stays pending and is retried on the next sync.
      reportSyncIssue('Intervention « ${ticket.id} »', error);
    }
  }

  Future<void> _saveAndPush(WorkTicket ticket) async {
    final pending = ticket.copyWith(syncPending: true);
    await _repo.put(pending);
    await loadTickets();
    await _pushToOdoo(pending);
  }

  Future<void> addTicket({
    required String title,
    required String description,
    required String activityId,
    required String activityName,
    required TicketType type,
    required TicketPriority priority,
    String? assetId,
    String? assetName,
    DateTime? dateDue,
    String? assignedTechnician,
    List<String> photoPaths = const [],
    String? author,
  }) async {
    final newTicket = WorkTicket(
      id: '${type == TicketType.anomaly ? "inc" : "maint"}-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      activityId: activityId,
      activityName: activityName,
      assetId: assetId,
      assetName: assetName,
      type: type,
      priority: priority,
      status: TicketStatus.open,
      dateCreated: DateTime.now(),
      // The due date is chosen by the caller, from the club's delay setting.
      dateDue: dateDue,
      assignedTechnician: assignedTechnician,
      photoPaths: photoPaths,
      events: [
        TicketEvent.make(
          type: TicketEventType.created,
          message: type == TicketType.anomaly
              ? 'Incident signalé'
              : 'Intervention planifiée',
          author: author,
        ),
        if (photoPaths.isNotEmpty)
          TicketEvent.make(
            type: TicketEventType.photoAdded,
            message: '${photoPaths.length} photo(s) jointe(s)',
            author: author,
          ),
        if (assignedTechnician != null && assignedTechnician.isNotEmpty)
          TicketEvent.make(
            type: TicketEventType.assigned,
            message: 'Assigné à $assignedTechnician',
            author: author,
          ),
      ],
    );

    await _saveAndPush(newTicket);
  }

  Future<void> updateTicketStatus(String id, TicketStatus status,
      {String? author}) async {
    final ticket = await _repo.getById(id);
    if (ticket == null || ticket.status == status) return;

    final updated = ticket.copyWith(
      status: status,
      dateCompleted:
          status == TicketStatus.resolved ? DateTime.now() : ticket.dateCompleted,
      events: [
        ...ticket.events,
        TicketEvent.make(
          type: TicketEventType.statusChanged,
          message: _statusLabel(ticket.type, status),
          author: author,
        ),
      ],
    );
    await _saveAndPush(updated);
  }

  Future<void> addComment(String id, String message, {String? author}) async {
    final ticket = await _repo.getById(id);
    if (ticket == null || message.trim().isEmpty) return;

    await _saveAndPush(ticket.copyWith(
      events: [
        ...ticket.events,
        TicketEvent.make(
          type: TicketEventType.commented,
          message: message.trim(),
          author: author,
        ),
      ],
    ));
  }

  Future<void> addPhoto(String id, String photoPath, {String? author}) async {
    final ticket = await _repo.getById(id);
    if (ticket == null) return;

    await _saveAndPush(ticket.copyWith(
      photoPaths: [...ticket.photoPaths, photoPath],
      events: [
        ...ticket.events,
        TicketEvent.make(
          type: TicketEventType.photoAdded,
          message: 'Photo ajoutée',
          author: author,
        ),
      ],
    ));
  }

  Future<void> assignTechnician(String id, String technician,
      {String? author}) async {
    final ticket = await _repo.getById(id);
    if (ticket == null) return;

    await _saveAndPush(ticket.copyWith(
      assignedTechnician: technician,
      events: [
        ...ticket.events,
        TicketEvent.make(
          type: TicketEventType.assigned,
          message: 'Assigné à $technician',
          author: author,
        ),
      ],
    ));
  }

  String _statusLabel(TicketType type, TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Ticket rouvert';
      case TicketStatus.inProgress:
        return 'Prise en charge';
      case TicketStatus.resolved:
        return type == TicketType.anomaly
            ? 'Incident résolu'
            : 'Intervention réalisée';
    }
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsNotifier, List<WorkTicket>>((ref) {
  return TicketsNotifier(
    ref.watch(ticketRepositoryProvider),
    ref.watch(ticketSyncServiceProvider),
    ref.watch(odooClubServiceProvider),
  );
});
