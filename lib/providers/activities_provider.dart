import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  final Isar _isar;
  final Ref _ref;

  ActivitiesNotifier(this._isar, this._ref) : super([]) {
    _loadActivities();
  }

  void _loadActivities() {
    state = _isar.activitys.where().findAllSync();
  }

  void updateOccupancy(String activityId, int newOccupancy) {
    final activity =
        _isar.activitys.filter().idEqualTo(activityId).findFirstSync();
    if (activity != null) {
      final syncState = _ref.read(syncProvider);
      _isar.writeTxnSync(() {
        final updated = Activity(
          isarId: activity.isarId,
          id: activity.id,
          name: activity.name,
          iconKey: activity.iconKey,
          status: activity.status,
          currentOccupancy: newOccupancy.clamp(0, activity.maxCapacity),
          maxCapacity: activity.maxCapacity,
          assignedStaff: activity.assignedStaff,
        );
        _isar.activitys.putSync(updated);
      });
      _loadActivities();

      // Offline logging
      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Modification occupation '${activity.name}' -> $newOccupancy");
      }
    }
  }

  void updateStatus(String activityId, ActivityStatus newStatus) {
    final activity =
        _isar.activitys.filter().idEqualTo(activityId).findFirstSync();
    if (activity != null) {
      final syncState = _ref.read(syncProvider);
      _isar.writeTxnSync(() {
        final updated = Activity(
          isarId: activity.isarId,
          id: activity.id,
          name: activity.name,
          iconKey: activity.iconKey,
          status: newStatus,
          currentOccupancy: newStatus == ActivityStatus.closed ||
                  newStatus == ActivityStatus.maintenance
              ? 0
              : activity.currentOccupancy,
          maxCapacity: activity.maxCapacity,
          assignedStaff: activity.assignedStaff,
        );
        _isar.activitys.putSync(updated);
      });
      _loadActivities();

      // Offline logging
      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Changement statut '${activity.name}' -> ${newStatus.toString().split('.').last}");
      }
    }
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  final isar = ref.watch(isarProvider);
  return ActivitiesNotifier(isar, ref);
});
