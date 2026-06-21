import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/sync_provider.dart';
import '../theme/app_theme.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  DateTime _selectedDate = DateTime.now();

  // Mock reservations data list
  final List<MockReservation> _mockReservations = [
    MockReservation(
      timeStart: '09:00',
      timeEnd: '10:30',
      activityName: 'Stand de Tir',
      activityId: 'shooting',
      clientName: 'Groupe Belhaj',
      peopleCount: 6,
      status: 'Confirmé',
      dayOffset: 0,
    ),
    MockReservation(
      timeStart: '10:00',
      timeEnd: '12:00',
      activityName: 'Piscine',
      activityId: 'pool',
      clientName: 'Mme. Sarah L.',
      peopleCount: 3,
      status: 'Confirmé',
      dayOffset: 0,
    ),
    MockReservation(
      timeStart: '11:00',
      timeEnd: '13:00',
      activityName: 'Terrains de Padel',
      activityId: 'padel',
      clientName: 'Match Amical - Bennani',
      peopleCount: 4,
      status: 'Confirmé',
      dayOffset: 0,
    ),
    MockReservation(
      timeStart: '14:30',
      timeEnd: '16:00',
      activityName: 'Équitation',
      activityId: 'horses',
      clientName: 'Cours d\'équitation - Yassine',
      peopleCount: 2,
      status: 'En attente',
      dayOffset: 0,
    ),
    MockReservation(
      timeStart: '16:00',
      timeEnd: '18:00',
      activityName: 'Paintball',
      activityId: 'paintball',
      clientName: 'Anniversaire - Karim',
      peopleCount: 12,
      status: 'Confirmé',
      dayOffset: 0,
    ),
    // Tomorrow
    MockReservation(
      timeStart: '10:00',
      timeEnd: '11:30',
      activityName: 'Stand de Tir',
      activityId: 'shooting',
      clientName: 'Entraînement Pro',
      peopleCount: 2,
      status: 'Confirmé',
      dayOffset: 1,
    ),
    MockReservation(
      timeStart: '15:00',
      timeEnd: '16:30',
      activityName: 'Terrains de Padel',
      activityId: 'padel',
      clientName: 'Tournoi Double',
      peopleCount: 8,
      status: 'Confirmé',
      dayOffset: 1,
    ),
    // Other days
    MockReservation(
      timeStart: '11:00',
      timeEnd: '12:30',
      activityName: 'Équitation',
      activityId: 'horses',
      clientName: 'Randonnée Guidée',
      peopleCount: 5,
      status: 'Confirmé',
      dayOffset: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final isOffline = !syncState.isOnline;

    // Calculate day offset from today
    final today = DateTime.now();
    final differenceInDays =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;

    // Filter reservations matching selected day offset
    final dayReservations = _mockReservations
        .where((res) => res.dayOffset == differenceInDays)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filtrer par activité',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plus/reservations/nouvelle'),
        backgroundColor: AppColors.accentPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle réservation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Offline Mode warning banner if offline
          if (isOffline)
            Container(
              color: AppColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode hors-ligne : Réservations en lecture seule',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Horizontal Date Selector Card
          _buildHorizontalDatePicker(),

          const Divider(height: 1, color: AppColors.border),

          // 3. Agenda Timeline List
          Expanded(
            child: dayReservations.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayReservations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildReservationCard(dayReservations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    final today = DateTime.now();
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.backgroundSecondary,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 8,
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          final dayName = DateFormat('EEE', 'fr_FR')
              .format(date)
              .toUpperCase()
              .replaceAll('.', '');
          final dayNumber = DateFormat('d').format(date);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: 56, // glove friendly minimum width
              child: Material(
                color: isSelected ? AppColors.accentPrimary : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Aucune réservation',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune activité n\'est planifiée pour le ${DateFormat('d MMMM', 'fr_FR').format(_selectedDate)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(MockReservation res) {
    final activityColor = _getActivityColor(res.activityId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Activity Color Strip
              Container(width: 5, color: activityColor),
              const SizedBox(width: 16),

              // Time Block
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.timeStart,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.timeEnd,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Details
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: activityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              res.activityName,
                              style: TextStyle(
                                color: activityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Text(
                              res.status,
                              style: TextStyle(
                                color: res.status == 'Confirmé'
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        res.clientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people_outline,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${res.peopleCount} personnes',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(String activityId) {
    switch (activityId.toLowerCase()) {
      case 'pool':
        return const Color(0xFF00D4FF);
      case 'horses':
        return const Color(0xFFFFB347);
      case 'paintball':
        return const Color(0xFF7CFC00);
      case 'shooting':
        return const Color(0xFFFF4757);
      case 'gym':
        return const Color(0xFFA855F7);
      case 'padel':
        return const Color(0xFF34D399);
      default:
        return AppColors.accentPrimary;
    }
  }
}

class MockReservation {
  final String timeStart;
  final String timeEnd;
  final String activityName;
  final String activityId;
  final String clientName;
  final int peopleCount;
  final String status;
  final int dayOffset;

  MockReservation({
    required this.timeStart,
    required this.timeEnd,
    required this.activityName,
    required this.activityId,
    required this.clientName,
    required this.peopleCount,
    required this.status,
    required this.dayOffset,
  });
}
