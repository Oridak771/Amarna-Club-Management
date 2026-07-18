import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../services/database_service.dart';
import '../services/odoo_club_service.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(isarProvider));
});

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  final ActivityRepository _repo;
  final OdooClubService _club;

  ActivitiesNotifier(this._repo, this._club) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadActivities();
    await refreshFromOdoo();
  }

  Future<void> _loadActivities() async {
    state = await _repo.getAll();
  }

  /// Pulls the activity list from Odoo and upserts it into the local cache
  /// (business id is a unique replace index, so this is an upsert).
  Future<void> refreshFromOdoo() async {
    if (!_club.isConfigured) return;
    try {
      final remote = await _club.fetchActivities();
      if (remote.isNotEmpty) {
        await _repo.putAll(remote);
        await _loadActivities();
      }
    } catch (error) {
      debugPrint('Odoo activities pull failed: $error');
    }
  }

  Future<void> updateOccupancy(String activityId, int newOccupancy) async {
    final activity = await _repo.getById(activityId);
    if (activity == null) return;
    final clamped = newOccupancy.clamp(0, activity.maxCapacity);
    final updated = Activity(
      isarId: activity.isarId,
      id: activity.id,
      name: activity.name,
      iconKey: activity.iconKey,
      status: activity.status,
      currentOccupancy: clamped,
      maxCapacity: activity.maxCapacity,
      assignedStaff: activity.assignedStaff,
    );
    await _repo.put(updated);
    await _loadActivities();
    _pushOccupancy(activity.id, clamped);
  }

  Future<void> updateStatus(String activityId, ActivityStatus newStatus) async {
    final activity = await _repo.getById(activityId);
    if (activity == null) return;
    final occupancy = newStatus == ActivityStatus.closed ||
            newStatus == ActivityStatus.maintenance
        ? 0
        : activity.currentOccupancy;
    final updated = Activity(
      isarId: activity.isarId,
      id: activity.id,
      name: activity.name,
      iconKey: activity.iconKey,
      status: newStatus,
      currentOccupancy: occupancy,
      maxCapacity: activity.maxCapacity,
      assignedStaff: activity.assignedStaff,
    );
    await _repo.put(updated);
    await _loadActivities();
    _pushStatus(activity.id, newStatus, occupancy);
  }

  Future<void> _pushOccupancy(String code, int occupancy) async {
    if (!_club.isConfigured) return;
    try {
      await _club.pushActivityOccupancy(code, occupancy);
    } catch (error) {
      debugPrint('Odoo occupancy push failed for $code: $error');
    }
  }

  Future<void> _pushStatus(
      String code, ActivityStatus status, int occupancy) async {
    if (!_club.isConfigured) return;
    try {
      await _club.pushActivityStatus(code, status);
      await _club.pushActivityOccupancy(code, occupancy);
    } catch (error) {
      debugPrint('Odoo status push failed for $code: $error');
    }
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  return ActivitiesNotifier(
    ref.watch(activityRepositoryProvider),
    ref.watch(odooClubServiceProvider),
  );
});
