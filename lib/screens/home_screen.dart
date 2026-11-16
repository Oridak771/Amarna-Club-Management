import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/inventory_item.dart';
import '../models/reservation.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/tickets_provider.dart';
import '../services/odoo_jsonrpc_service.dart';
import '../theme/app_theme.dart';
import '../ui/activity_ui_adapter.dart';
import '../widgets/app_layout.dart';
import '../widgets/reservation_tile.dart';

/// « Ma journée » — the staff home page.
///
/// Reads top to bottom in the order staff act: what needs attention now,
/// the day's arrivals with one-tap check-in, the open tickets, then the state
/// of each activity. The four most common actions sit within reach at the top.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final activities = ref.watch(activitiesProvider);
    final inventory = ref.watch(inventoryProvider);
    final reservations = ref.watch(todaysReservationsProvider);

    final openTickets =
        tickets.where((t) => t.status != TicketStatus.resolved).toList();
    final overdueCount = openTickets.where((t) => t.isOverdue).length;
    final lowStock = inventory.where((i) => i.isLowStock).toList();
    final openActivities =
        activities.where((a) => a.status == ActivityStatus.open).length;

    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return AppPage(
      title: _greeting(now),
      subtitle: dateLabel[0].toUpperCase() + dateLabel.substring(1),
      onRefresh: () async {
        await Future.wait([
          ref.read(ticketsProvider.notifier).pullFromOdoo(),
          ref.read(activitiesProvider.notifier).refreshFromOdoo(),
          ref.read(inventoryProvider.notifier).refreshFromOdoo(),
        ]);
        ref.invalidate(todaysReservationsProvider);
      },
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Scanner un QR ou une carte',
          onPressed: () => context.push('/scan'),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SyncBanner(),
          _QuickActions(lowStockCount: lowStock.length),
          const SizedBox(height: 20),
          _KpiRow(
            openTickets: openTickets.length,
            overdueCount: overdueCount,
            lowStockCount: lowStock.length,
            openActivities: openActivities,
            totalActivities: activities.length,
            reservations: reservations.valueOrNull,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final planning = _PlanningSection(reservations: reservations);
              final urgent = _UrgentSection(tickets: openTickets);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [planning, const SizedBox(height: 24), urgent],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: planning),
                  const SizedBox(width: 20),
                  Expanded(child: urgent),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _ActivitiesSection(activities: activities),
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 24),
            _LowStockSection(items: lowStock),
          ],
        ],
      ),
    );
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Bonjour';
    if (now.hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

// ---------------------------------------------------------------------------
// Sync state

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: odooSyncIssue,
      builder: (context, issue, _) {
        if (issue == null) return const SizedBox.shrink();
        final colors = context.colors;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppPanel(
            color: colors.warning.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: colors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Synchronisation Odoo interrompue — $issue\n'
                    'Les données affichées peuvent être anciennes.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Masquer',
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () => odooSyncIssue.value = null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions: the four most frequent tasks, one tap each

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.lowStockCount});

  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actions = [
      _QuickAction(
        icon: Icons.add_alert_rounded,
        label: 'Signaler',
        color: colors.danger,
        onTap: () => context.go('/tickets/nouveau'),
      ),
      _QuickAction(
        icon: Icons.how_to_reg_rounded,
        label: 'Arrivée',
        color: colors.accentPrimary,
        onTap: () => context.go('/planning'),
      ),
      _QuickAction(
        icon: Icons.event_available_rounded,
        label: 'Réserver',
        color: colors.pool,
        onTap: () => context.go('/planning/nouvelle'),
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Stock',
        color: colors.accentSecondary,
        badge: lowStockCount > 0 ? '$lowStockCount' : null,
        onTap: () => context.go('/plus/inventaire'),
      ),
    ];
    return Row(
      children: [
        for (final action in actions) ...[
          Expanded(child: action),
          if (action != actions.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPIs

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.openTickets,
    required this.overdueCount,
    required this.lowStockCount,
    required this.openActivities,
    required this.totalActivities,
    required this.reservations,
  });

  final int openTickets;
  final int overdueCount;
  final int lowStockCount;
  final int openActivities;
  final int totalActivities;
  final List<Reservation>? reservations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final arrived = reservations
            ?.where((r) => r.status == ReservationStatus.checkedIn)
            .length ??
        0;
    final expected = reservations?.length ?? 0;

    final tiles = [
      AppStatTile(
        label: 'Tickets ouverts',
        value: '$openTickets',
        caption: overdueCount > 0 ? '$overdueCount en retard' : 'Rien en retard',
        icon: Icons.assignment_outlined,
        color: overdueCount > 0 ? colors.danger : colors.info,
        onTap: () => context.go('/tickets'),
      ),
      AppStatTile(
        label: 'Arrivées du jour',
        value: reservations == null ? '—' : '$arrived/$expected',
        caption: 'Réservations pointées',
        icon: Icons.how_to_reg_outlined,
        color: colors.accentPrimary,
        onTap: () => context.go('/planning'),
      ),
      AppStatTile(
        label: 'Stock bas',
        value: '$lowStockCount',
        caption: lowStockCount == 0 ? 'Tout est au niveau' : 'À réapprovisionner',
        icon: Icons.inventory_2_outlined,
        color: lowStockCount > 0 ? colors.warning : colors.success,
        onTap: () => context.go('/plus/inventaire'),
      ),
      AppStatTile(
        label: 'Activités ouvertes',
        value: '$openActivities/$totalActivities',
        caption: 'Statut opérationnel',
        icon: Icons.sports_tennis_rounded,
        color: colors.pool,
        onTap: () => context.go('/activites'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Planning of the day

class _PlanningSection extends ConsumerWidget {
  const _PlanningSection({required this.reservations});

  final AsyncValue<List<Reservation>> reservations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = reservations.valueOrNull;

    Widget content;
    if (reservations.isLoading && list == null) {
      content = const AppLoadingState(message: 'Chargement du planning…');
    } else if (reservations.hasError && list == null) {
      content = AppErrorState(
        message: _errorText(reservations.error),
        onRetry: () => ref.invalidate(todaysReservationsProvider),
      );
    } else if (list == null || list.isEmpty) {
      content = AppEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Aucune réservation aujourd’hui',
        action: FilledButton.icon(
          onPressed: () => context.go('/planning/nouvelle'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvelle réservation'),
        ),
      );
    } else {
      final upcoming = list
          .where((r) => r.status != ReservationStatus.cancelled)
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      content = Column(
        children: [
          for (final r in upcoming.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReservationTile(reservation: r),
            ),
          if (upcoming.length > 6)
            TextButton(
              onPressed: () => context.go('/planning'),
              child: Text('Voir les ${upcoming.length} réservations'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Planning du jour',
          icon: Icons.event_note_rounded,
          count: list?.length,
          trailing: TextButton(
            onPressed: () => context.go('/planning'),
            child: const Text('Tout voir'),
          ),
        ),
        content,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tickets needing attention

class _UrgentSection extends StatelessWidget {
  const _UrgentSection({required this.tickets});

  final List<WorkTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final sorted = [...tickets]..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        final byPriority = b.priority.index.compareTo(a.priority.index);
        if (byPriority != 0) return byPriority;
        return b.dateCreated.compareTo(a.dateCreated);
      });
    final urgent = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Tickets à traiter',
          icon: Icons.priority_high_rounded,
          count: tickets.length,
          trailing: TextButton(
            onPressed: () => context.go('/tickets'),
            child: const Text('Tout voir'),
          ),
        ),
        if (urgent.isEmpty)
          const AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Aucun ticket ouvert',
            message: 'Tout est à jour pour le moment.',
          )
        else
          for (final ticket in urgent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TicketRow(ticket: ticket),
            ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final WorkTicket ticket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priorityColor = switch (ticket.priority) {
      TicketPriority.critical => colors.priorityCritical,
      TicketPriority.high => colors.priorityHigh,
      TicketPriority.medium => colors.priorityMedium,
      TicketPriority.low => colors.priorityLow,
    };
    return AppPanel(
      accentColor: priorityColor,
      onTap: () => context.go('/tickets/${ticket.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (ticket.activityName.isNotEmpty) ticket.activityName,
                    if (ticket.assetName != null) ticket.assetName!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppPill(
            label: ticket.isOverdue ? 'En retard' : ticket.priorityTextFrench,
            color: ticket.isOverdue ? colors.danger : priorityColor,
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activities

class _ActivitiesSection extends StatelessWidget {
  const _ActivitiesSection({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const AppEmptyState(
        icon: Icons.sports_rounded,
        title: 'Aucune activité synchronisée',
        message: 'Vérifiez la connexion à Odoo puis tirez pour actualiser.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Activités',
          icon: Icons.grid_view_rounded,
          trailing: TextButton(
            onPressed: () => context.go('/activites'),
            child: const Text('Tout voir'),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 860
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
            const gap = 12.0;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final activity in activities)
                  SizedBox(
                    width: width,
                    child: _ActivityCard(activity: activity),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = resolveActivityColor(context, activity.id);
    final statusColor = activity.status.resolveColor(context);
    final ratio = activity.occupancyPercentage.clamp(0.0, 1.0);

    return AppPanel(
      onTap: () => context.go('/activites/${activity.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(resolveActivityIcon(activity.iconKey),
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colors.textPrimary),
                ),
              ),
              AppPill(label: activity.statusTextFrench, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          if (activity.maxCapacity > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: color,
                backgroundColor: colors.surface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${activity.currentOccupancy}/${activity.maxCapacity} présents',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary),
            ),
          ] else
            Text(
              'Occupation non renseignée',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Low stock

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Stock à réapprovisionner',
          icon: Icons.warning_amber_rounded,
          count: items.length,
        ),
        AppPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length && i < 6; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                ListTile(
                  minVerticalPadding: 12,
                  title: Text(items[i].name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                  subtitle: Text(items[i].activityName,
                      style: TextStyle(color: colors.textSecondary)),
                  trailing: AppPill(
                    label: '${items[i].currentStock} ${items[i].unitName}'
                        .trim(),
                    color: items[i].isOutOfStock
                        ? colors.danger
                        : colors.warning,
                  ),
                  onTap: () => context.go('/plus/inventaire'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _errorText(Object? error) {
  if (error is OdooException) return error.message;
  return 'Vérifiez la connexion au serveur puis réessayez.';
}
