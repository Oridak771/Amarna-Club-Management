import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/work_ticket.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

class TicketsNotifier extends StateNotifier<List<WorkTicket>> {
  final Isar _isar;
  final Ref _ref;

  TicketsNotifier(this._isar, this._ref) : super([]) {
    loadTickets();
  }

  void loadTickets() {
    state = _isar.workTickets.where().sortByDateCreatedDesc().findAllSync();
  }

  void addTicket({
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
  }) {
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
      dateDue: dateDue ?? (type != TicketType.anomaly ? DateTime.now().add(const Duration(days: 3)) : null),
      assignedTechnician: assignedTechnician,
      imageUrl: imageUrl,
      voiceNoteUrl: voiceNoteUrl,
      syncPending: isOffline,
    );

    _isar.writeTxnSync(() {
      _isar.workTickets.putSync(newTicket);
    });
    loadTickets();

    if (isOffline) {
      final label = type == TicketType.anomaly
          ? "Signalement incident '$title' ($activityName)"
          : "Planification maintenance '$title'";
      _ref.read(syncProvider.notifier).incrementPendingCount(label);
    }
  }

  void updateTicketStatus(String id, TicketStatus status) {
    final ticket = _isar.workTickets.filter().idEqualTo(id).findFirstSync();
    if (ticket != null) {
      final syncState = _ref.read(syncProvider);
      
      _isar.writeTxnSync(() {
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
          dateCompleted: status == TicketStatus.resolved ? DateTime.now() : ticket.dateCompleted,
          imageUrl: ticket.imageUrl,
          voiceNoteUrl: ticket.voiceNoteUrl,
          assignedTechnician: ticket.assignedTechnician,
          syncPending: !syncState.isOnline || ticket.syncPending,
        );
        _isar.workTickets.putSync(updated);
      });
      loadTickets();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
          "Mise à jour ticket '${ticket.title}' -> ${status.toString().split('.').last}"
        );
      }
    }
  }
}

final ticketsProvider = StateNotifierProvider<TicketsNotifier, List<WorkTicket>>((ref) {
  final isar = ref.watch(isarProvider);
  return TicketsNotifier(isar, ref);
});
