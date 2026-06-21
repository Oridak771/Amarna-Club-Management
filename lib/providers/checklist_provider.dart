import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_item.dart';
import '../repositories/checklist_repository.dart';
import '../services/database_service.dart';
import 'sync_provider.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.watch(isarProvider));
});

class ChecklistNotifier extends StateNotifier<List<ChecklistItem>> {
  final ChecklistRepository _repo;
  final Ref _ref;

  ChecklistNotifier(this._repo, this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    state = await _repo.getAll();
  }

  Future<void> updateItemStatus(String id, ChecklistStatus status,
      {String? comment, String? photoPath}) async {
    final item = await _repo.getById(id);
    if (item != null) {
      final syncState = _ref.read(syncProvider);

      final updated = item.copyWith(
        status: status,
        comment: comment,
        photoPath: photoPath,
      );
      await _repo.put(updated);
      await _loadChecklists();

      // If offline, register sync pending log
      if (!syncState.isOnline) {
        _ref.read(syncProvider.notifier).incrementPendingCount(
            "Mise à jour checklist '${item.title}' -> ${status == ChecklistStatus.done ? 'Terminé' : 'Problème'}");
      }
    }
  }

  Future<void> resetChecklistsForActivity(String activityId) async {
    final items = state.where((i) => i.activityId == activityId).toList();
    for (final item in items) {
      final updated = item.copyWith(
        status: ChecklistStatus.open,
        comment: null,
        photoPath: null,
      );
      await _repo.put(updated);
    }
    await _loadChecklists();
  }
}

final checklistProvider =
    StateNotifierProvider<ChecklistNotifier, List<ChecklistItem>>((ref) {
  final repo = ref.watch(checklistRepositoryProvider);
  return ChecklistNotifier(repo, ref);
});
