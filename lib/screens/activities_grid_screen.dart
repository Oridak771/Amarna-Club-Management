import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/activity.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/activity_ui_adapter.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/app_layout.dart';

/// « Activités » — every activity of the club with its live status.
///
/// Filter by operational status, then open an activity for its inventory,
/// equipment, interventions and occupancy.
class ActivitiesGridScreen extends ConsumerStatefulWidget {
  const ActivitiesGridScreen({super.key});

  @override
  ConsumerState<ActivitiesGridScreen> createState() =>
      _ActivitiesGridScreenState();
}

class _ActivitiesGridScreenState extends ConsumerState<ActivitiesGridScreen> {
  ActivityStatus? _filterStatus;

  static const _statusFilters = <(ActivityStatus?, String)>[
    (null, 'Toutes'),
    (ActivityStatus.open, 'Ouvertes'),
    (ActivityStatus.warning, 'Attention'),
    (ActivityStatus.maintenance, 'Maintenance'),
    (ActivityStatus.closed, 'Fermées'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(activitiesProvider);
    final tickets = ref.watch(ticketsProvider);
    final visible = _filterStatus == null
        ? all
        : all.where((a) => a.status == _filterStatus).toList();

    int openTicketsFor(String activityId) => tickets
        .where((t) =>
            t.activityId == activityId && t.status != TicketStatus.resolved)
        .length;

    return AppPage(
      title: 'Activités',
      subtitle: '${all.where((a) => a.status == ActivityStatus.open).length}'
          '/${all.length} ouvertes',
      onRefresh: () => ref.read(activitiesProvider.notifier).refreshFromOdoo(),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (status, label) = _statusFilters[index];
                return AppFilterChip(
                  label: label,
                  isSelected: _filterStatus == status,
                  count: status == null
                      ? all.length
                      : all.where((a) => a.status == status).length,
                  onTap: () => setState(() => _filterStatus = status),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (all.isEmpty)
            const AppEmptyState(
              icon: Icons.sports_rounded,
              title: 'Aucune activité synchronisée',
              message: 'Tirez vers le bas pour actualiser depuis Odoo.',
            )
          else if (visible.isEmpty)
            const AppEmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'Aucune activité dans ce filtre',
              message: 'Changez de filtre pour voir les autres activités.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 860
                    ? 3
                    : constraints.maxWidth >= 540
                        ? 2
                        : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final activity in visible)
                      SizedBox(
                        width: width,
                        child: _ActivityCard(
                          activity: activity,
                          openTickets: openTicketsFor(activity.id),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.openTickets});

  final Activity activity;
  final int openTickets;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = resolveActivityColor(context, activity.id);
    final statusColor = activity.status.resolveColor(context);
    final closed = activity.status == ActivityStatus.closed ||
        activity.status == ActivityStatus.maintenance;

    return AppPanel(
      onTap: () => context.go('/activites/${activity.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(resolveActivityIcon(activity.iconKey),
                    color: color, size: 26),
              ),
              const Spacer(),
              AppPill(label: activity.statusTextFrench, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activity.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.assignedStaff.isEmpty
                ? 'Aucun personnel affecté'
                : activity.assignedStaff,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.people_alt_outlined,
                  text: activity.maxCapacity > 0
                      ? '${activity.currentOccupancy}/${activity.maxCapacity}'
                      : '${activity.currentOccupancy} présents',
                  color: colors.textSecondary,
                ),
              ),
              _Metric(
                icon: openTickets > 0
                    ? Icons.assignment_late_outlined
                    : Icons.task_alt_rounded,
                text: openTickets > 0
                    ? '$openTickets ticket${openTickets > 1 ? 's' : ''}'
                    : 'Aucun ticket',
                color: openTickets > 0 ? colors.danger : colors.success,
              ),
            ],
          ),
          if (closed && activity.closureStart != null) ...[
            const SizedBox(height: 10),
            Text(
              activity.status == ActivityStatus.maintenance
                  ? 'Maintenance en cours'
                  : 'Fermeture en cours',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
