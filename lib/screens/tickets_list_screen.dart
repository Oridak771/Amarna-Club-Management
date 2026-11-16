import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/app_layout.dart';

/// « Interventions » — incidents and maintenance tickets, most urgent first.
///
/// Filters sit above the list with live counts, so staff can jump straight to
/// what is overdue. Tapping a card opens the ticket; the extended button
/// reports a new incident in one step.
class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

enum _TicketFilter {
  all('Tout'),
  incidents('Incidents'),
  maintenance('Maintenances'),
  overdue('En retard'),
  inProgress('En cours'),
  resolved('Résolus');

  const _TicketFilter(this.label);
  final String label;

  bool matches(WorkTicket ticket) {
    switch (this) {
      case _TicketFilter.all:
        return true;
      case _TicketFilter.incidents:
        return ticket.type == TicketType.anomaly;
      case _TicketFilter.maintenance:
        return ticket.type == TicketType.preventive ||
            ticket.type == TicketType.corrective;
      case _TicketFilter.overdue:
        return ticket.isOverdue;
      case _TicketFilter.inProgress:
        return ticket.status == TicketStatus.inProgress;
      case _TicketFilter.resolved:
        return ticket.status == TicketStatus.resolved;
    }
  }
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  _TicketFilter _filter = _TicketFilter.all;

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final colors = context.colors;

    final open = tickets.where((t) => t.status != TicketStatus.resolved);
    final overdue = open.where((t) => t.isOverdue).length;

    final visible = tickets.where(_filter.matches).toList()
      ..sort(_urgencyOrder);

    return AppPage(
      title: 'Interventions',
      subtitle: overdue > 0
          ? '${open.length} ouverts · $overdue en retard'
          : '${open.length} ouverts',
      onRefresh: () => ref.read(ticketsProvider.notifier).pullFromOdoo(),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.danger,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/tickets/nouveau'),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Signaler'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _TicketFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _TicketFilter.values[index];
                final count = tickets.where(filter.matches).length;
                return AppFilterChip(
                  label: filter.label,
                  count: count,
                  isSelected: _filter == filter,
                  onTap: () => setState(() => _filter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            AppEmptyState(
              icon: Icons.task_alt_rounded,
              title: tickets.isEmpty
                  ? 'Aucune intervention'
                  : 'Aucun ticket dans ce filtre',
              message: tickets.isEmpty
                  ? 'Signalez un incident dès qu’un problème est constaté.'
                  : 'Changez de filtre pour voir les autres tickets.',
              action: tickets.isEmpty
                  ? FilledButton.icon(
                      onPressed: () => context.push('/tickets/nouveau'),
                      icon: const Icon(Icons.add_alert_rounded),
                      label: const Text('Signaler un incident'),
                    )
                  : null,
            )
          else
            for (final ticket in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TicketCard(ticket: ticket),
              ),
        ],
      ),
    );
  }

  /// Overdue first, then resolved last, then priority, then newest.
  static int _urgencyOrder(WorkTicket a, WorkTicket b) {
    int rank(WorkTicket t) {
      if (t.status == TicketStatus.resolved) return 3;
      if (t.isOverdue) return 0;
      return 1;
    }

    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) return byPriority;
    return b.dateCreated.compareTo(a.dateCreated);
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

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
    final resolved = ticket.status == TicketStatus.resolved;
    final statusColor = switch (ticket.status) {
      TicketStatus.open => colors.info,
      TicketStatus.inProgress => colors.warning,
      TicketStatus.resolved => colors.success,
    };

    return AppPanel(
      accentColor: ticket.isOverdue ? colors.danger : priorityColor,
      onTap: () => context.push('/tickets/${ticket.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: resolved ? colors.textSecondary : colors.textPrimary,
                    decoration: resolved ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppPill(label: ticket.statusTextFrench, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPill(
                label: ticket.priorityTextFrench,
                color: priorityColor,
                icon: Icons.flag_rounded,
              ),
              if (ticket.isOverdue)
                AppPill(
                  label: 'En retard',
                  color: colors.danger,
                  icon: Icons.schedule_rounded,
                  filled: true,
                ),
              Text(
                [
                  if (ticket.activityName.isNotEmpty) ticket.activityName,
                  if (ticket.assetName != null) ticket.assetName!,
                ].join(' · '),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 15, color: colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _relativeTime(ticket.dateCreated),
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
              if (ticket.assignedTechnician != null) ...[
                Icon(Icons.person_outline_rounded,
                    size: 15, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  ticket.assignedTechnician!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime dateCreated) {
    final diff = DateTime.now().difference(dateCreated);
    if (diff.inMinutes < 1) return 'à l’instant';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'il y a $m min';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'il y a $h h';
    }
    final d = diff.inDays;
    return 'il y a $d j';
  }
}
