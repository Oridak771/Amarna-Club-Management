import 'package:flutter_riverpod/flutter_riverpod.dart';

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

List<Horse> _seedHorses() {
  final now = DateTime.now();
  return [
    Horse(
      id: 'h1',
      name: 'Tornade',
      breed: 'Pur-sang arabe',
      age: 7,
      boxNumber: 'Box 1',
      status: HorseStatus.available,
      fatigue: 0.2,
      diet: 'Foin + granulés (2x/jour)',
      lastFarrier: now.subtract(const Duration(days: 21)),
      lastVaccine: now.subtract(const Duration(days: 120)),
      lastDeworming: now.subtract(const Duration(days: 30)),
      ridesToday: const [
        HorseRide(
            timeRange: '09:00 – 10:00',
            label: 'Entraînement saut',
            rider: 'Jean Dupont'),
        HorseRide(
            timeRange: '14:30 – 15:30',
            label: 'Balade forêt',
            rider: 'Marie Curie'),
      ],
    ),
    Horse(
      id: 'h2',
      name: 'Pégase',
      breed: 'Selle français',
      age: 11,
      boxNumber: 'Box 2',
      status: HorseStatus.resting,
      fatigue: 0.8,
      diet: 'Foin enrichi + compléments articulaires',
      vetNote: 'Surveillance tendon antérieur droit.',
      nextVetVisit: now.add(const Duration(days: 1)),
      lastFarrier: now.subtract(const Duration(days: 50)),
      lastVaccine: now.subtract(const Duration(days: 200)),
      lastDeworming: now.subtract(const Duration(days: 95)),
    ),
    Horse(
      id: 'h3',
      name: 'Éclair',
      breed: 'Barbe',
      age: 5,
      boxNumber: 'Box 3',
      status: HorseStatus.available,
      fatigue: 0.5,
      diet: 'Foin + orge aplatie',
      lastFarrier: now.subtract(const Duration(days: 10)),
      lastVaccine: now.subtract(const Duration(days: 60)),
      lastDeworming: now.subtract(const Duration(days: 45)),
      ridesToday: const [
        HorseRide(
            timeRange: '11:00 – 12:00',
            label: 'Cours débutant',
            rider: 'Groupe enfants'),
      ],
    ),
    Horse(
      id: 'h4',
      name: 'Ombre',
      breed: 'Frison',
      age: 9,
      boxNumber: 'Box 4',
      status: HorseStatus.injured,
      fatigue: 0.0,
      diet: 'Foin uniquement (repos)',
      vetNote: 'Boiterie postérieure gauche — box strict jusqu\'au contrôle.',
      nextVetVisit: now.add(const Duration(hours: 4)),
      lastFarrier: now.subtract(const Duration(days: 35)),
      lastVaccine: now.subtract(const Duration(days: 90)),
      lastDeworming: now.subtract(const Duration(days: 20)),
    ),
    Horse(
      id: 'h5',
      name: 'Spirit',
      breed: 'Mustang',
      age: 6,
      boxNumber: 'Box 5',
      status: HorseStatus.available,
      fatigue: 0.1,
      diet: 'Foin + granulés (2x/jour)',
      lastFarrier: now.subtract(const Duration(days: 14)),
      lastVaccine: now.subtract(const Duration(days: 30)),
      lastDeworming: now.subtract(const Duration(days: 60)),
    ),
    Horse(
      id: 'h6',
      name: 'Jumper',
      breed: 'Hanovrien',
      age: 8,
      boxNumber: 'Box 6',
      status: HorseStatus.resting,
      fatigue: 0.9,
      diet: 'Ration récupération + électrolytes',
      lastFarrier: now.subtract(const Duration(days: 28)),
      lastVaccine: now.subtract(const Duration(days: 150)),
      lastDeworming: now.subtract(const Duration(days: 80)),
      ridesToday: const [
        HorseRide(
            timeRange: '08:00 – 09:30',
            label: 'Concours préparation',
            rider: 'Sophie Marchand'),
      ],
    ),
  ];
}

class HorsesNotifier extends StateNotifier<List<Horse>> {
  HorsesNotifier() : super(_seedHorses());

  void updateStatus(String id, HorseStatus status) {
    state = [
      for (final horse in state)
        if (horse.id == id)
          horse.copyWith(
            status: status,
            // A horse put back to work starts rested.
            fatigue: status == HorseStatus.available ? 0.0 : horse.fatigue,
          )
        else
          horse,
    ];
  }
}

final horsesProvider =
    StateNotifierProvider<HorsesNotifier, List<Horse>>((ref) {
  return HorsesNotifier();
});

final horseByIdProvider = Provider.family<Horse?, String>((ref, id) {
  final horses = ref.watch(horsesProvider);
  for (final horse in horses) {
    if (horse.id == id) return horse;
  }
  return null;
});
