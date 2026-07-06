import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';
import '../models/work_ticket.dart';
import '../providers/checkin_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/ticket_ui_adapter.dart';

/// Open interventions for one activity — shared across activity module
/// screens so live ticket data is visible where the work happens.
class ActivityTicketsPanel extends ConsumerWidget {
  const ActivityTicketsPanel({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tickets = ref
        .watch(ticketsProvider)
        .where((t) =>
            t.activityId == activityId && t.status != TicketStatus.resolved)
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Interventions ouvertes (${tickets.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: () => context.go('/tickets/nouveau'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Signaler'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (tickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: colors.success, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Aucune intervention en cours.',
                  style: TextStyle(
                    color: colors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          for (final ticket in tickets.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.border),
                ),
                child: InkWell(
                  onTap: () => context.go('/tickets/${ticket.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ticket.priority.resolveColor(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ticket.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Text(
                          ticket.statusTextFrench,
                          style: TextStyle(
                            color: ticket.status.resolveColor(context,
                                type: ticket.type),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Today's reservations for one activity, live from Odoo, with check-in.
class ActivityReservationsPanel extends ConsumerWidget {
  const ActivityReservationsPanel({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  final String activityId;
  final String activityName;

  bool _matches(Reservation r) {
    final id = activityId.toLowerCase();
    final name = activityName.toLowerCase();
    return r.activityId.toLowerCase() == id ||
        r.activityName.toLowerCase().contains(name) ||
        name.contains(r.activityName.toLowerCase());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final reservationsAsync = ref.watch(todaysReservationsProvider);
    ref.watch(checkinProvider);
    final checkin = ref.read(checkinProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sessions du jour',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        reservationsAsync.when(
          data: (items) {
            final sessions = items
                .where((r) =>
                    r.status != ReservationStatus.cancelled && _matches(r))
                .toList();
            if (sessions.isEmpty) {
              return _info(context, Icons.event_busy_rounded,
                  'Aucune session réservée aujourd\'hui.');
            }
            return Column(
              children: [
                for (final session in sessions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${DateFormat('HH:mm').format(session.startAt)}–${DateFormat('HH:mm').format(session.endAt)}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              session.peopleCount > 0
                                  ? '${session.clientName} · ${session.peopleCount} pers.'
                                  : session.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (checkin.isCheckedIn(session))
                            Icon(Icons.check_circle_rounded,
                                color: colors.success, size: 22)
                          else
                            TextButton(
                              onPressed: () => checkin.checkIn(session),
                              child: const Text('Check-in'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _info(context, Icons.cloud_off_rounded,
              'Réservations Odoo indisponibles (configuration .env).'),
        ),
      ],
    );
  }

  Widget _info(BuildContext context, IconData icon, String message) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
