import 'package:isar/isar.dart';
import '../models/checklist_item.dart';

/// Data-access layer for [ChecklistItem] backed by Isar.
class ChecklistRepository {
  final Isar _isar;

  ChecklistRepository(this._isar);

  /// Returns all checklist items.
  Future<List<ChecklistItem>> getAll() async {
    return _isar.checklistItems.where().findAll();
  }

  /// Returns checklist items for a specific activity.
  Future<List<ChecklistItem>> getByActivity(String activityId) async {
    return _isar.checklistItems
        .filter()
        .activityIdEqualTo(activityId)
        .findAll();
  }

  /// Returns a single item by its business [id], or null.
  Future<ChecklistItem?> getById(String id) async {
    return _isar.checklistItems.filter().idEqualTo(id).findFirst();
  }

  /// Inserts or updates a checklist item.
  Future<void> put(ChecklistItem item) async {
    await _isar.writeTxn(() async {
      await _isar.checklistItems.put(item);
    });
  }

  /// Watches the entire checklist collection.
  Stream<void> watchAll() {
    return _isar.checklistItems.watchLazy();
  }
}
