import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/odoo_club_service.dart';
import '../services/odoo_jsonrpc_service.dart';

enum HorseStatus { available, resting, injured }

extension HorseStatusX on HorseStatus {
  String get labelFrench {
    switch (this) {
      case HorseStatus.available:
        return 'Disponible';
      case HorseStatus.resting:
        return 'Au repos';
      case HorseStatus.injured:
        return 'Blessé';
    }
  }
}

class HorseRide {
  final String timeRange;
  final String label;
  final String rider;

  const HorseRide({
    required this.timeRange,
    required this.label,
    required this.rider,
  });
}

class Horse {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String boxNumber;
  final HorseStatus status;
  final double fatigue; // 0.0 – 1.0
  final String diet;
  final String? vetNote;
  final DateTime? nextVetVisit;
  final DateTime lastFarrier; // maréchal-ferrant
  final DateTime lastVaccine;
  final DateTime lastDeworming; // vermifuge
  final List<HorseRide> ridesToday;

  const Horse({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.boxNumber,
    required this.status,
    required this.fatigue,
    required this.diet,
    this.vetNote,
    this.nextVetVisit,
    required this.lastFarrier,
    required this.lastVaccine,
    required this.lastDeworming,
    this.ridesToday = const [],
  });

  Horse copyWith({HorseStatus? status, double? fatigue, String? vetNote}) {
    return Horse(
      id: id,
      name: name,
      breed: breed,
      age: age,
      boxNumber: boxNumber,
      status: status ?? this.status,
      fatigue: fatigue ?? this.fatigue,
      diet: diet,
      vetNote: vetNote ?? this.vetNote,
      nextVetVisit: nextVetVisit,
      lastFarrier: lastFarrier,
      lastVaccine: lastVaccine,
      lastDeworming: lastDeworming,
      ridesToday: ridesToday,
    );
  }

  /// Farrier work is recommended every ~6 weeks.
  bool get farrierDue => DateTime.now().difference(lastFarrier).inDays > 42;

  /// Deworming every ~3 months.
  bool get dewormingDue =>
      DateTime.now().difference(lastDeworming).inDays > 90;
}

class HorsesNotifier extends StateNotifier<List<Horse>> {
  HorsesNotifier(this._club) : super(const []) {
    refreshFromOdoo();
  }

  final OdooClubService _club;

  /// Loads the herd from Odoo. Empty until the first successful pull.
  Future<void> refreshFromOdoo() async {
    if (!_club.isConfigured) return;
    try {
      final remote = await _club.fetchHorses();
      if (remote.isNotEmpty) {
        state = remote;
      }
    } catch (error) {
      reportSyncIssue('Écurie (lecture)', error);
    }
  }

  void updateStatus(String id, HorseStatus status) {
    // A horse put back to work starts rested.
    final newFatigue = status == HorseStatus.available ? 0.0 : null;
    state = [
      for (final horse in state)
        if (horse.id == id)
          horse.copyWith(status: status, fatigue: newFatigue)
        else
          horse,
    ];
    _pushStatus(id, status);
  }

  Future<void> _pushStatus(String id, HorseStatus status) async {
    if (!_club.isConfigured) return;
    final horse = state.where((h) => h.id == id).toList();
    if (horse.isEmpty) return;
    try {
      await _club.pushHorseStatus(id, status, horse.first.fatigue);
    } catch (error) {
      reportSyncIssue('Statut cheval « $id »', error);
    }
  }
}

final horsesProvider =
    StateNotifierProvider<HorsesNotifier, List<Horse>>((ref) {
  return HorsesNotifier(ref.watch(odooClubServiceProvider));
});

final horseByIdProvider = Provider.family<Horse?, String>((ref, id) {
  final horses = ref.watch(horsesProvider);
  for (final horse in horses) {
    if (horse.id == id) return horse;
  }
  return null;
});
