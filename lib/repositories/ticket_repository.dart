import 'package:isar/isar.dart';
import '../models/work_ticket.dart';

/// Data-access layer for [WorkTicket] backed by Isar.
/// Providers delegate all DB operations here.
class TicketRepository {
  final Isar _isar;

  TicketRepository(this._isar);

  /// Returns all tickets sorted newest-first.
  Future<List<WorkTicket>> getAll() async {
    return _isar.workTickets.where().sortByDateCreatedDesc().findAll();
  }

  /// Returns a single ticket by its business [id], or null.
  Future<WorkTicket?> getById(String id) async {
    return _isar.workTickets.filter().idEqualTo(id).findFirst();
  }

  /// Returns tickets for a specific activity.
  Future<List<WorkTicket>> getByActivity(String activityId) async {
    return _isar.workTickets
        .filter()
        .activityIdEqualTo(activityId)
        .sortByDateCreatedDesc()
        .findAll();
  }

  /// Returns all tickets that are still pending sync.
  Future<List<WorkTicket>> getPendingSync() async {
    return _isar.workTickets.filter().syncPendingEqualTo(true).findAll();
  }

  /// Inserts or updates a ticket.
  Future<void> put(WorkTicket ticket) async {
    await _isar.writeTxn(() async {
      await _isar.workTickets.put(ticket);
    });
  }

  /// Inserts or updates multiple tickets inside a single transaction.
  Future<void> putAll(List<WorkTicket> tickets) async {
    await _isar.writeTxn(() async {
      await _isar.workTickets.putAll(tickets);
    });
  }

  /// Watches the entire ticket collection for changes.
  Stream<void> watchAll() {
    return _isar.workTickets.watchLazy();
  }
}
