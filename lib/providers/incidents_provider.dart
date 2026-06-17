import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/incident.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

class IncidentsNotifier extends StateNotifier<List<Incident>> {
  final Isar _isar;
  final Ref _ref;

  IncidentsNotifier(this._isar, this._ref) : super([]) {
    loadIncidents();
  }

  void loadIncidents() {
    state = _isar.incidents.where().sortByDateCreatedDesc().findAllSync();
  }

  void addIncident({
    required String title,
    required String description,
    required String activityId,
    required String activityName,
    required IncidentPriority priority,
    String? imageUrl,
    String? voiceNoteUrl,
    bool createdOffline = false,
  }) {
    final syncState = _ref.read(syncProvider);
    final isOffline = !syncState.isOnline || createdOffline;

    final newIncident = Incident(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      activityId: activityId,
      activityName: activityName,
      priority: priority,
      status: IncidentStatus.open,
      dateCreated: DateTime.now(),
      imageUrl: imageUrl,
      voiceNoteUrl: voiceNoteUrl,
      syncPending: isOffline,
    );

    _isar.writeTxnSync(() {
      _isar.incidents.putSync(newIncident);
    });
    loadIncidents();

    if (isOffline) {
      _ref.read(syncProvider.notifier).incrementPendingCount(
        "Signalement incident '$title' ($activityName)"
      );
    }
  }

  void updateIncidentStatus(String id, IncidentStatus status) {
    final incident = _isar.incidents.filter().idEqualTo(id).findFirstSync();
    if (incident != null) {
      final syncState = _ref.read(syncProvider);
      
      _isar.writeTxnSync(() {
        final updated = Incident(
          isarId: incident.isarId,
          id: incident.id,
          title: incident.title,
          description: incident.description,
          activityId: incident.activityId,
          activityName: incident.activityName,
          priority: incident.priority,
          status: status,
          dateCreated: incident.dateCreated,
          imageUrl: incident.imageUrl,
          voiceNoteUrl: incident.voiceNoteUrl,
          assignedTechnician: incident.assignedTechnician,
          syncPending: !syncState.isOnline || incident.syncPending,
        );
        _isar.incidents.putSync(updated);
      });
      loadIncidents();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
          "Mise à jour incident '${incident.title}' -> ${status.toString().split('.').last}"
        );
      }
    }
  }
}

final incidentsProvider = StateNotifierProvider<IncidentsNotifier, List<Incident>>((ref) {
  final isar = ref.watch(isarProvider);
  return IncidentsNotifier(isar, ref);
});
