import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/checklist_item.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

class ChecklistNotifier extends StateNotifier<List<ChecklistItem>> {
  final Isar _isar;
  final Ref _ref;

  ChecklistNotifier(this._isar, this._ref) : super([]) {
    _loadChecklists();
  }

  void _loadChecklists() {
    state = _isar.checklistItems.where().findAllSync();
  }

  void updateItemStatus(String id, ChecklistStatus status, {String? comment, String? photoPath}) {
    final item = _isar.checklistItems.filter().idEqualTo(id).findFirstSync();
    if (item != null) {
      final syncState = _ref.read(syncProvider);
      
      _isar.writeTxnSync(() {
        final updated = item.copyWith(
          status: status,
          comment: comment,
          photoPath: photoPath,
        );
        _isar.checklistItems.putSync(updated);
      });
      _loadChecklists();

      // If offline, register sync pending log
      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
          "Mise à jour checklist '${item.title}' -> ${status == ChecklistStatus.done ? 'Terminé' : 'Problème'}"
        );
      }
    }
  }

  void resetChecklistsForActivity(String activityId) {
    final items = _isar.checklistItems.filter().activityIdEqualTo(activityId).findAllSync();
    if (items.isNotEmpty) {
      _isar.writeTxnSync(() {
        for (final item in items) {
          final updated = item.copyWith(
            status: ChecklistStatus.open,
            comment: null,
            photoPath: null,
          );
          _isar.checklistItems.putSync(updated);
        }
      });
      _loadChecklists();
    }
  }
}

final checklistProvider = StateNotifierProvider<ChecklistNotifier, List<ChecklistItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return ChecklistNotifier(isar, ref);
});
