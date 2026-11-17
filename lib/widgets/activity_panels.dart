import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/reservation.dart';
import '../models/work_ticket.dart';
import '../providers/reservations_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/ticket_ui_adapter.dart';
import 'app_layout.dart';
import 'reservation_tile.dart';

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
        SectionTitle(
          title: 'Interventions ouvertes',
          count: tickets.length,
          trailing: TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => context.go('/tickets/nouveau'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Signaler'),
          ),
        ),
        if (tickets.isEmpty)
          AppPanel(
            color: colors.success.withValues(alpha: 0.07),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: colors.success, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucune intervention en cours.',
                    style: TextStyle(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final ticket in tickets.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppPanel(
                onTap: () => context.go('/tickets/${ticket.id}'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ticket.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppPill(
                      label: ticket.statusTextFrench,
                      color: ticket.status.resolveColor(context,
                          type: ticket.type),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: colors.textMuted),
                  ],
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
  });

  /// Activity code (the same key as Odoo's `mobile_activity_code`).
  final String activityId;

  bool _matches(Reservation r) =>
      r.activityId.toLowerCase() == activityId.toLowerCase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(todaysReservationsProvider);

    return reservationsAsync.when(
      data: (items) {
        final sessions = items
            .where((r) =>
                r.status != ReservationStatus.cancelled && _matches(r))
            .toList();
        return _section(
          sessions.length,
          sessions.isEmpty
              ? _info(context, Icons.event_busy_rounded,
                  'Aucune session réservée aujourd\'hui.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final session in sessions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ReservationTile(
                          reservation: session,
                          showActivity: false,
                        ),
                      ),
                  ],
                ),
        );
      },
      loading: () => _section(
        null,
        const AppLoadingState(message: 'Chargement des sessions…'),
      ),
      error: (_, __) => _section(
        null,
        const AppErrorState(
          title: 'Réservations indisponibles',
          message: 'Réservations Odoo indisponibles (vérifiez la connexion).',
        ),
      ),
    );
  }

  Widget _section(int? count, Widget body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Sessions du jour',
          count: count,
          icon: Icons.event_available_rounded,
        ),
        body,
      ],
    );
  }

  Widget _info(BuildContext context, IconData icon, String message) {
    final colors = context.colors;
    return AppPanel(
      child: Row(
        children: [
          Icon(icon, color: colors.textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
