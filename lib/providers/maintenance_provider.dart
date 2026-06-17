import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/maintenance_task.dart';
import '../models/incident.dart'; // Reuse IncidentPriority
import '../services/database_service.dart';
import 'sync_provider.dart';

class MaintenanceNotifier extends StateNotifier<List<MaintenanceTask>> {
  final Isar _isar;
  final Ref _ref;

  MaintenanceNotifier(this._isar, this._ref) : super([]) {
    loadTasks();
  }

  void loadTasks() {
    state = _isar.maintenanceTasks.where().sortByDateDueDesc().findAllSync();
  }

  void addMaintenanceTask({
    required String title,
    required String description,
    required String assetId,
    required String assetName,
    required String activityId,
    required MaintenanceType type,
    required IncidentPriority priority,
    DateTime? dateDue,
    String? assignedTechnician,
    bool createdOffline = false,
  }) {
    final syncState = _ref.read(syncProvider);
    final isOffline = !syncState.isOnline || createdOffline;

    final newTask = MaintenanceTask(
      id: 'maint-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      assetId: assetId,
      assetName: assetName,
      activityId: activityId,
      type: type,
      priority: priority,
      status: MaintenanceStatus.todo,
      dateDue: dateDue ?? DateTime.now().add(const Duration(days: 3)),
      assignedTechnician: assignedTechnician,
      syncPending: isOffline,
    );

    _isar.writeTxnSync(() {
      _isar.maintenanceTasks.putSync(newTask);
    });
    loadTasks();

    if (isOffline) {
      _ref.read(syncProvider.notifier).incrementPendingCount(
        "Planification maintenance '$title'"
      );
    }
  }

  void updateTaskStatus(String id, MaintenanceStatus status) {
    final task = _isar.maintenanceTasks.filter().idEqualTo(id).findFirstSync();
    if (task != null) {
      final syncState = _ref.read(syncProvider);
      
      _isar.writeTxnSync(() {
        final updated = MaintenanceTask(
          isarId: task.isarId,
          id: task.id,
          title: task.title,
          description: task.description,
          assetId: task.assetId,
          assetName: task.assetName,
          activityId: task.activityId,
          type: task.type,
          priority: task.priority,
          status: status,
          dateDue: task.dateDue,
          dateCompleted: status == MaintenanceStatus.done ? DateTime.now() : task.dateCompleted,
          assignedTechnician: task.assignedTechnician,
          syncPending: !syncState.isOnline || task.syncPending,
        );
        _isar.maintenanceTasks.putSync(updated);
      });
      loadTasks();

      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
          "Mise à jour maintenance '${task.title}' -> ${status.toString().split('.').last}"
        );
      }
    }
  }
}

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, List<MaintenanceTask>>((ref) {
  final isar = ref.watch(isarProvider);
  return MaintenanceNotifier(isar, ref);
});
