import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';
import '../providers/reservations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';
import '../widgets/reservation_tile.dart';

/// « Planning » — the day's bookings, one tab away from home.
///
/// Pick a day in the strip (today and the next two weeks), see the day's
/// totals, then check people in from the list grouped by activity.
class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  static const _dayCount = 14;

  final DateTime _today = _normalize(DateTime.now());
  late DateTime _selectedDate = _today;

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync =
        ref.watch(reservationsForDateProvider(_selectedDate));
    final dayLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDate);
    final isToday = _sameDay(_selectedDate, _today);

    return AppPage(
      title: 'Planning',
      subtitle: dayLabel[0].toUpperCase() + dayLabel.substring(1),
      onRefresh: () async {
        ref.invalidate(reservationsForDateProvider(_selectedDate));
      },
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              ref.invalidate(reservationsForDateProvider(_selectedDate)),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/planning/nouvelle'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Réserver'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayStrip(
            today: _today,
            days: _dayCount,
            selected: _selectedDate,
            onSelected: (day) => setState(() => _selectedDate = day),
          ),
          const SizedBox(height: 16),
          reservationsAsync.when(
            loading: () => const AppLoadingState(message: 'Chargement du planning…'),
            error: (error, _) => AppErrorState(
              message: _errorText(error),
              onRetry: () =>
                  ref.invalidate(reservationsForDateProvider(_selectedDate)),
            ),
            data: (items) => _DayContent(
              items: items,
              isToday: isToday,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.today,
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final DateTime today;
  final int days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: days,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected = _isSameDay(date, selected);
          final foreground = isSelected ? colors.textOnAccent : colors.textPrimary;
          return Material(
            color: isSelected ? colors.accentPrimary : colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              onTap: () => onSelected(date),
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusField),
                  border: Border.all(
                    color: isSelected ? colors.accentPrimary : colors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      index == 0
                          ? 'AUJ.'
                          : DateFormat('EEE', 'fr_FR')
                              .format(date)
                              .toUpperCase()
                              .replaceAll('.', ''),
                      style: TextStyle(
                        color: isSelected
                            ? foreground
                            : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        color: foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayContent extends StatelessWidget {
  const _DayContent({required this.items, required this.isToday});

  final List<Reservation> items;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final active =
        items.where((r) => r.status != ReservationStatus.cancelled).toList();
    if (active.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_available_rounded,
        title: 'Aucune réservation ce jour',
        message: isToday
            ? 'Vous pouvez enregistrer une réservation pour aujourd’hui.'
            : 'Choisissez un autre jour ou créez une réservation.',
        action: FilledButton.icon(
          onPressed: () => context.push('/planning/nouvelle'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvelle réservation'),
        ),
      );
    }

    final arrived =
        active.where((r) => r.status == ReservationStatus.checkedIn).length;
    final pending = active.length - arrived;

    final byActivity = <String, List<Reservation>>{};
    for (final reservation in active) {
      final key = reservation.activityName.isNotEmpty
          ? reservation.activityName
          : (reservation.activityId.isNotEmpty
              ? reservation.activityId
              : 'Sans activité');
      byActivity.putIfAbsent(key, () => []).add(reservation);
    }
    final groups = byActivity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Totals(
                label: 'Réservations',
                value: '${active.length}',
                color: context.colors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Totals(
                label: 'Arrivées',
                value: '$arrived',
                color: context.colors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Totals(
                label: 'À venir',
                value: '$pending',
                color: context.colors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (final group in groups) ...[
          SectionTitle(
            title: group.key,
            count: group.value.length,
            icon: Icons.circle,
          ),
          for (final reservation in group.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReservationTile(
                reservation: reservation,
                showActivity: false,
              ),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _errorText(Object error) {
  final text = error.toString();
  return text.replaceFirst('Bad state: ', '').replaceFirst('StateError: ', '');
}
