import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';
import '../providers/checkin_provider.dart';
import '../providers/reservations_provider.dart';
import '../theme/app_theme.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  DateTime _selectedDate = _normalize(DateTime.now());

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(
      reservationsForDateProvider(_selectedDate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.read(reservationsRefreshProvider.notifier).state++;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plus/reservations/nouvelle'),
        backgroundColor: context.colors.accentPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle reservation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildHorizontalDatePicker(),
          Divider(height: 1, color: context.colors.border),
          Expanded(
            child: reservationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildReservationCard(items[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    final today = _normalize(DateTime.now());
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: context.colors.backgroundSecondary,
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 56,
              child: Material(
                color: isSelected
                    ? context.colors.accentPrimary
                    : context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        isSelected ? Colors.transparent : context.colors.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _selectedDate = _normalize(date)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.colors.textPrimary,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Aucune reservation',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune activite n\'est planifiee pour le ${DateFormat('d MMMM', 'fr_FR').format(_selectedDate)}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.colors.warning),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les reservations Odoo',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final activityColor = _getActivityColor(reservation.activityId);
    ref.watch(checkinProvider);
    final checkinNotifier = ref.read(checkinProvider.notifier);
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isCheckedIn = checkinNotifier.isCheckedIn(reservation);
    final canCheckIn = isToday &&
        !isCheckedIn &&
        reservation.status != ReservationStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: activityColor),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(reservation.startAt),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(reservation.endAt),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                              reservation.activityName,
                              style: TextStyle(
                                color: activityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              reservation.statusLabel,
                              style: TextStyle(
                                color: reservation.status ==
                                        ReservationStatus.confirmed
                                    ? context.colors.success
                                    : context.colors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reservation.clientName,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reservation.peopleCount > 0
                                  ? '${reservation.peopleCount} personnes'
                                  : 'Capacite non renseignee',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (isCheckedIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.colors.success
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 15,
                                      color: context.colors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Arrivé',
                                    style: TextStyle(
                                      color: context.colors.success,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (canCheckIn)
                            FilledButton.icon(
                              onPressed: () async {
                                await runCheckIn(context, checkinNotifier, reservation);
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                              ),
                              icon:
                                  const Icon(Icons.how_to_reg_rounded, size: 17),
                              label: const Text('Check-in'),
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
    return context.colors.getActivityColor(activityId);
  }
}
