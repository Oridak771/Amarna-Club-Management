import 'package:isar/isar.dart';
import '../models/activity.dart';

/// Data-access layer for [Activity] backed by Isar.
class ActivityRepository {
  final Isar _isar;

  ActivityRepository(this._isar);

  /// Returns all activities.
  Future<List<Activity>> getAll() async {
    return _isar.activitys.where().findAll();
  }

  /// Returns a single activity by its business [id], or null.
  Future<Activity?> getById(String id) async {
    return _isar.activitys.filter().idEqualTo(id).findFirst();
  }

  /// Inserts or updates an activity.
  Future<void> put(Activity activity) async {
    await _isar.writeTxn(() async {
      await _isar.activitys.put(activity);
    });
  }

  /// Inserts or updates multiple activities.
  Future<void> putAll(List<Activity> activities) async {
    await _isar.writeTxn(() async {
      await _isar.activitys.putAll(activities);
    });
  }

  /// Watches the entire activity collection.
  Stream<void> watchAll() {
    return _isar.activitys.watchLazy();
  }
}
