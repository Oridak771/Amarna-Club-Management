import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../services/database_service.dart';
import '../models/work_ticket.dart';
import 'tickets_provider.dart';

class SyncState {
  final bool isOnline;
  final DateTime? lastSyncTime;
  final int pendingSyncCount;
  final bool isSyncing;
  final List<String> syncLogs;

  const SyncState({
    required this.isOnline,
    this.lastSyncTime,
    required this.pendingSyncCount,
    required this.isSyncing,
    required this.syncLogs,
  });

  SyncState copyWith({
    bool? isOnline,
    DateTime? lastSyncTime,
    int? pendingSyncCount,
    bool? isSyncing,
    List<String>? syncLogs,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isSyncing: isSyncing ?? this.isSyncing,
      syncLogs: syncLogs ?? this.syncLogs,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;

  SyncNotifier(this._ref)
      : super(
          SyncState(
            isOnline: true,
            lastSyncTime: DateTime.now().subtract(const Duration(minutes: 15)),
            pendingSyncCount: 0,
            isSyncing: false,
            syncLogs: ['Démarrage de l\'application - Synchronisé.'],
          ),
        );

  // Simulate network toggle
  void setOnlineStatus(bool online) {
    if (state.isOnline == online) return;
    
    final newLogs = List<String>.from(state.syncLogs);
    if (online) {
      newLogs.add('Connexion réseau rétablie. Synchronisation automatique en cours...');
      state = state.copyWith(isOnline: true, syncLogs: newLogs);
      triggerSync();
    } else {
      newLogs.add('Connexion réseau perdue. Mode hors-ligne activé.');
      state = state.copyWith(isOnline: false, syncLogs: newLogs);
    }
  }

  // Increment pending item count
  void incrementPendingCount(String actionDescription) {
    final newLogs = List<String>.from(state.syncLogs);
    newLogs.add('Hors-ligne : Action mise en attente - "$actionDescription"');
    state = state.copyWith(
      pendingSyncCount: state.pendingSyncCount + 1,
      syncLogs: newLogs,
    );
  }

  // Perform sync
  Future<void> triggerSync() async {
    if (!state.isOnline || state.isSyncing || state.pendingSyncCount == 0) return;

    state = state.copyWith(isSyncing: true);
    final newLogs = List<String>.from(state.syncLogs);
    newLogs.add('Début de synchronisation de ${state.pendingSyncCount} élément(s)...');
    
    // Simulate API network call
    await Future.delayed(const Duration(seconds: 2));

    final isar = _ref.read(isarProvider);
    
    // Perform database sync updates
    await isar.writeTxn(() async {
      // Sync pending work tickets
      final pendingTickets = await isar.workTickets.filter().syncPendingEqualTo(true).findAll();
      for (final ticket in pendingTickets) {
        final updated = WorkTicket(
          isarId: ticket.isarId,
          id: ticket.id,
          title: ticket.title,
          description: ticket.description,
          activityId: ticket.activityId,
          activityName: ticket.activityName,
          assetId: ticket.assetId,
          assetName: ticket.assetName,
          type: ticket.type,
          priority: ticket.priority,
          status: ticket.status,
          dateCreated: ticket.dateCreated,
          dateDue: ticket.dateDue,
          dateCompleted: ticket.dateCompleted,
          imageUrl: ticket.imageUrl,
          voiceNoteUrl: ticket.voiceNoteUrl,
          assignedTechnician: ticket.assignedTechnician,
          syncPending: false,
        );
        await isar.workTickets.put(updated);
      }
    });

    // Refresh providers to reflect synced state
    _ref.read(ticketsProvider.notifier).loadTickets();

    newLogs.add('Synchronisation avec Odoo ERP réussie. Base locale à jour.');
    state = state.copyWith(
      isSyncing: false,
      pendingSyncCount: 0,
      lastSyncTime: DateTime.now(),
      syncLogs: newLogs,
    );
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
