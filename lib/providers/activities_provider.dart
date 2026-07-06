import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../services/database_service.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(isarProvider));
});

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  final ActivityRepository _repo;

  ActivitiesNotifier(this._repo) : super([]) {
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    state = await _repo.getAll();
  }

  Future<void> updateOccupancy(String activityId, int newOccupancy) async {
    final activity = await _repo.getById(activityId);
    if (activity == null) return;
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
    await _repo.put(updated);
    await _loadActivities();
  }

  Future<void> updateStatus(String activityId, ActivityStatus newStatus) async {
    final activity = await _repo.getById(activityId);
    if (activity == null) return;
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
    await _repo.put(updated);
    await _loadActivities();
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  return ActivitiesNotifier(ref.watch(activityRepositoryProvider));
});
