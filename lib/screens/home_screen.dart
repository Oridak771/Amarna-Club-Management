import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/reservation.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/reservations_provider.dart';
import '../services/odoo_jsonrpc_service.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';

/// « Ma journée » — the staff home page.
///
/// Action-first: urgent interventions, today's reservations with one-tap
/// check-in, quick actions and a glanceable activity strip. Global KPIs
/// live in Plus → Rapports.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final activities = ref.watch(activitiesProvider);
    final lowStockCount =
        ref.watch(inventoryProvider).where((i) => i.isLowStock).length;

    final urgentTickets = _urgentTickets(tickets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma journée'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner QR/NFC',
            onPressed: () => context.push('/scan'),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _SyncBanner(),
              _GreetingHeader(
                openCount: activities
                    .where((a) => a.status == ActivityStatus.open)
                    .length,
                totalCount: activities.length,
              ),
              const SizedBox(height: 16),
              _AlertStrip(
                tickets: tickets,
                activities: activities,
                lowStockCount: lowStockCount,
              ),
              const SizedBox(height: 20),
              const _QuickActions(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 860;
                  final urgent = _UrgentTicketsSection(tickets: urgentTickets);
                  const reservations = _TodayReservationsSection();
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        urgent,
                        const SizedBox(height: 24),
                        reservations,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: urgent),
                      const SizedBox(width: 20),
                      const Expanded(child: reservations),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _ActivitiesStrip(activities: activities),
            ],
          ),
        ),
      ),
    );
  }

  List<WorkTicket> _urgentTickets(List<WorkTicket> tickets) {
    final open =
        tickets.where((t) => t.status != TicketStatus.resolved).toList()
          ..sort((a, b) {
            if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
            final byPriority = b.priority.index.compareTo(a.priority.index);
            if (byPriority != 0) return byPriority;
            return b.dateCreated.compareTo(a.dateCreated);
          });
    return open.take(4).toList();
  }
}

// ---------------------------------------------------------------------------

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.openCount, required this.totalCount});

  final int openCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    final date = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                date[0].toUpperCase() + date.substring(1),
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.accentPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.sports_tennis_rounded,
                  size: 18, color: context.colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                '$openCount/$totalCount activités ouvertes',
                style: TextStyle(
                  color: context.colors.accentPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _AlertStrip extends ConsumerWidget {
  const _AlertStrip({
    required this.tickets,
    required this.activities,
    required this.lowStockCount,
  });

  final List<WorkTicket> tickets;
  final List<Activity> activities;
  final int lowStockCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalCount = tickets
        .where((t) =>
            t.status != TicketStatus.resolved &&
            t.priority == TicketPriority.critical)
        .length;
    final overdueCount = tickets.where((t) => t.isOverdue).length;
    final warningActivities = activities
        .where((a) =>
            a.status == ActivityStatus.warning ||
            a.status == ActivityStatus.maintenance)
        .toList();

    final alerts = <Widget>[
      if (criticalCount > 0)
        _AlertCard(
          icon: Icons.error_outline_rounded,
          color: context.colors.danger,
          label:
              '$criticalCount incident${criticalCount > 1 ? 's' : ''} critique${criticalCount > 1 ? 's' : ''}',
          onTap: () => context.go('/tickets'),
        ),
      if (overdueCount > 0)
        _AlertCard(
          icon: Icons.schedule_rounded,
          color: context.colors.warning,
          label: '$overdueCount intervention${overdueCount > 1 ? 's' : ''} en retard',
          onTap: () => context.go('/tickets'),
        ),
      if (lowStockCount > 0)
        _AlertCard(
          icon: Icons.inventory_2_outlined,
          color: context.colors.accentSecondary,
          label: '$lowStockCount stock${lowStockCount > 1 ? 's' : ''} bas',
          onTap: () => context.go('/plus/inventaire'),
        ),
      for (final activity in warningActivities)
        _AlertCard(
          icon: activity.status == ActivityStatus.maintenance
              ? Icons.build_circle_outlined
              : Icons.warning_amber_rounded,
          color: activity.status == ActivityStatus.maintenance
              ? context.colors.info
              : context.colors.warning,
          label: '${activity.name} : ${activity.statusTextFrench}',
          onTap: () => context.go('/activites/${activity.id}'),
        ),
    ];

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.success.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: context.colors.success, size: 20),
            const SizedBox(width: 10),
            Text(
              'Tout est sous contrôle — aucune alerte en cours.',
              style: TextStyle(
                color: context.colors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => alerts[index],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.report_problem_rounded,
        'Signaler',
        'Incident ou panne',
        context.colors.danger,
        () => context.go('/tickets/nouveau'),
      ),
      (
        Icons.qr_code_scanner_rounded,
        'Scanner',
        'QR / NFC équipement',
        context.colors.accentPrimary,
        () => context.push('/scan'),
      ),
      (
        Icons.event_available_rounded,
        'Réserver',
        'Nouvelle réservation',
        context.colors.info,
        () => context.go('/plus/reservations/nouvelle'),
      ),
      (
        Icons.inventory_2_rounded,
        'Stocks',
        'Ajuster l\'inventaire',
        context.colors.accentSecondary,
        () => context.go('/plus/inventaire'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 2.1 : 2.4,
          children: [
            for (final (icon, title, subtitle, color, onTap) in actions)
              Material(
                color: context.colors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: context.colors.border),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.colors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _UrgentTicketsSection extends StatelessWidget {
  const _UrgentTicketsSection({required this.tickets});

  final List<WorkTicket> tickets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'À traiter en priorité',
          actionLabel: 'Tous les tickets',
          onAction: () => context.go('/tickets'),
        ),
        const SizedBox(height: 8),
        if (tickets.isEmpty)
          const _EmptyCard(
            icon: Icons.task_alt_rounded,
            message: 'Aucune intervention ouverte. Belle journée !',
          )
        else
          for (final ticket in tickets) ...[
            _TicketCard(ticket: ticket),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final WorkTicket ticket;

  Color _priorityColor(BuildContext context) {
    switch (ticket.priority) {
      case TicketPriority.low:
        return context.colors.priorityLow;
      case TicketPriority.medium:
        return context.colors.priorityMedium;
      case TicketPriority.high:
        return context.colors.priorityHigh;
      case TicketPriority.critical:
        return context.colors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(context);
    final activityColor = context.colors.getActivityColor(ticket.activityId);

    return Material(
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.border),
      ),
      child: InkWell(
        onTap: () => context.go('/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: activityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.activityName,
                            style: TextStyle(
                              color: activityColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket.priorityTextFrench,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (ticket.isOverdue) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule_rounded,
                              size: 13, color: context.colors.danger),
                          const SizedBox(width: 3),
                          Text(
                            'En retard',
                            style: TextStyle(
                              color: context.colors.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TodayReservationsSection extends ConsumerWidget {
  const _TodayReservationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(todaysReservationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Réservations du jour',
          actionLabel: 'Planning',
          onAction: () => context.go('/plus/reservations'),
        ),
        const SizedBox(height: 8),
        reservationsAsync.when(
          data: (items) {
            final upcoming = items
                .where((r) => r.status != ReservationStatus.cancelled)
                .toList();
            if (upcoming.isEmpty) {
              return const _EmptyCard(
                icon: Icons.event_busy_rounded,
                message: 'Aucune réservation aujourd\'hui.',
              );
            }
            return Column(
              children: [
                for (final reservation in upcoming.take(5)) ...[
                  _ReservationRow(reservation: reservation),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => const _EmptyCard(
            icon: Icons.cloud_off_rounded,
            message:
                'Réservations Odoo indisponibles.\nVérifiez la connexion au serveur.',
          ),
        ),
      ],
    );
  }
}

class _ReservationRow extends ConsumerWidget {
  const _ReservationRow({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(checkinProvider);
    final notifier = ref.read(checkinProvider.notifier);
    final checkedIn = notifier.isCheckedIn(reservation);
    final activityColor =
        context.colors.getActivityColor(reservation.activityId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                DateFormat('HH:mm').format(reservation.startAt),
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(reservation.endAt),
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: activityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reservation.peopleCount > 0
                      ? '${reservation.activityName} · ${reservation.peopleCount} pers.'
                      : reservation.activityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          checkedIn
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded,
                          size: 16, color: context.colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Arrivé',
                        style: TextStyle(
                          color: context.colors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton.icon(
                  key: ValueKey('checkin-${reservation.remoteId}'),
                  onPressed: () async {
                    await runCheckIn(context, notifier, reservation);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Check-in'),
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActivitiesStrip extends StatelessWidget {
  const _ActivitiesStrip({required this.activities});

  final List<Activity> activities;

  Color _statusColor(BuildContext context, ActivityStatus status) {
    switch (status) {
      case ActivityStatus.open:
        return context.colors.success;
      case ActivityStatus.closed:
        return context.colors.danger;
      case ActivityStatus.warning:
        return context.colors.warning;
      case ActivityStatus.maintenance:
        return context.colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Mes activités',
          actionLabel: 'Voir tout',
          onAction: () => context.go('/activites'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final color =
                  context.colors.getActivityColor(activity.id);
              final statusColor = _statusColor(context, activity.status);
              return Container(
                width: 190,
                decoration: BoxDecoration(
                  color: context.colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => context.go('/activites/${activity.id}'),
                    child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.statusTextFrench,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: activity.occupancyPercentage,
                            minHeight: 6,
                            backgroundColor: context.colors.surfaceHover,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${activity.currentOccupancy}/${activity.maxCapacity} présents',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.colors.textMuted, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells staff when the last exchange with Odoo failed, so stale figures are
/// not mistaken for live ones. Dismissing it only hides the message.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: odooSyncIssue,
      builder: (context, issue, _) {
        if (issue == null) return const SizedBox.shrink();
        final colors = context.colors;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Synchronisation Odoo interrompue — $issue\n'
                  'Les données affichées peuvent être anciennes.',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Masquer',
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                onPressed: () => odooSyncIssue.value = null,
              ),
            ],
          ),
        );
      },
    );
  }
}
