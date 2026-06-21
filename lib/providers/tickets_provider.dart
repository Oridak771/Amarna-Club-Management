import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_ticket.dart';
import '../repositories/ticket_repository.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(isarProvider));
});

class TicketsNotifier extends StateNotifier<List<WorkTicket>> {
  final TicketRepository _repo;
  final Ref _ref;

  TicketsNotifier(this._repo, this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await loadTickets();
  }

  Future<void> loadTickets() async {
    state = await _repo.getAll();
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
    String? imageUrl,
    String? voiceNoteUrl,
    bool createdOffline = false,
  }) async {
    final syncState = _ref.read(syncProvider);
    final isOffline = !syncState.isOnline || createdOffline;

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
      imageUrl: imageUrl,
      voiceNoteUrl: voiceNoteUrl,
      syncPending: isOffline,
    );

    await _repo.put(newTicket);
    await loadTickets();

    if (isOffline) {
      final label = type == TicketType.anomaly
          ? "Signalement incident '$title' ($activityName)"
          : "Planification maintenance '$title'";
      _ref.read(syncProvider.notifier).incrementPendingCount(label);
    }
  }

  Future<void> updateTicketStatus(String id, TicketStatus status) async {
    final ticket = await _repo.getById(id);
    if (ticket != null) {
      final syncState = _ref.read(syncProvider);

      final updated = WorkTicket(
        isarId: ticket.isarId,
        id: ticket.id,
        title: ticket.title,
        description: ticket.description,
        activityId: ticket.activityId,
        activityName: ticket.activityName,
        assetId: ticket.assetId,
        assetName: ticket.assetName,
        type: ticket.type,
        priority: ticket.priority,
        status: status,
        dateCreated: ticket.dateCreated,
        dateDue: ticket.dateDue,
        dateCompleted: status == TicketStatus.resolved
            ? DateTime.now()
            : ticket.dateCompleted,
        imageUrl: ticket.imageUrl,
        voiceNoteUrl: ticket.voiceNoteUrl,
        assignedTechnician: ticket.assignedTechnician,
        syncPending: !syncState.isOnline || ticket.syncPending,
      );
      await _repo.put(updated);
      await loadTickets();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Mise à jour ticket '${ticket.title}' -> ${status.toString().split('.').last}");
      }
    }
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsNotifier, List<WorkTicket>>((ref) {
  final repo = ref.watch(ticketRepositoryProvider);
  return TicketsNotifier(repo, ref);
});
