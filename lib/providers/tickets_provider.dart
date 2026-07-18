import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_environment.dart';
import '../models/work_ticket.dart';
import '../repositories/ticket_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';
import '../services/ticket_sync_service.dart';

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

  /// Two-way sync: pulls interventions from Odoo. Unknown tickets are added
  /// to the local cache; for known ones the remote status/priority/assignee
  /// win (a technician may have moved the ticket in the Odoo UI), while the
  /// local timeline events and photos are preserved.
  Future<void> pullFromOdoo() async {
    if (!AppEnvironment.isOdooConfigured) return;
    try {
      final remote = await _club.fetchInterventions();
      for (final ticket in remote) {
        final local = await _repo.getById(ticket.id);
        if (local == null) {
          await _repo.put(ticket);
        } else if (local.status != ticket.status ||
            local.priority != ticket.priority ||
            local.assignedTechnician != ticket.assignedTechnician) {
          await _repo.put(local.copyWith(
            status: ticket.status,
            priority: ticket.priority,
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
      }
      await loadTickets();
    } catch (error) {
      debugPrint('Odoo tickets pull failed: $error');
    }
  }

  /// Pushes the ticket to Odoo when configured; local state is the source
  /// of truth for the UI, so remote failures are logged but non-blocking.
  Future<void> _pushToOdoo(WorkTicket ticket) async {
    if (!AppEnvironment.isOdooConfigured) return;
    try {
      await _odooSync.syncTicket(ticket);
    } catch (error) {
      debugPrint('Odoo push failed for ticket ${ticket.id}: $error');
    }
  }

  Future<void> _saveAndPush(WorkTicket ticket) async {
    await _repo.put(ticket);
    await loadTickets();
    await _pushToOdoo(ticket);
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
      dateDue: dateDue ??
          (type != TicketType.anomaly
              ? DateTime.now().add(const Duration(days: 3))
              : null),
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
