import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/tickets_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:amarna_club/widgets/app_filter_chip.dart';

class ActivitiesGridScreen extends ConsumerStatefulWidget {
  const ActivitiesGridScreen({super.key});

  @override
  ConsumerState<ActivitiesGridScreen> createState() =>
      _ActivitiesGridScreenState();
}

class _ActivitiesGridScreenState extends ConsumerState<ActivitiesGridScreen> {
  ActivityStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final allActivities = ref.watch(activitiesProvider);
    final tickets = ref.watch(ticketsProvider);

    final filtered = _filterStatus == null
        ? allActivities
        : allActivities.where((a) => a.status == _filterStatus).toList();

    int openTicketsFor(String activityId) => tickets
        .where((t) =>
            t.activityId == activityId && t.status != TicketStatus.resolved)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      AppFilterChip(
                        label: 'Toutes (${allActivities.length})',
                        isSelected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      const SizedBox(width: 8),
                      for (final status in ActivityStatus.values) ...[
                        AppFilterChip(
                          label: _statusLabel(status,
                              allActivities.where((a) => a.status == status).length),
                          isSelected: _filterStatus == status,
                          onTap: () => setState(() => _filterStatus =
                              _filterStatus == status ? null : status),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 560
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio:
                                  crossAxisCount == 1 ? 2.1 : 1.35,
                            ),
                            itemBuilder: (context, index) {
                              final activity = filtered[index];
                              return _ActivityCard(
                                activity: activity,
                                openTickets: openTicketsFor(activity.id),
                                onTap: () => context
                                    .push('/activites/${activity.id}'),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ActivityStatus status, int count) {
    final name = switch (status) {
      ActivityStatus.open => 'Ouvertes',
      ActivityStatus.warning => 'Alerte',
      ActivityStatus.closed => 'Fermées',
      ActivityStatus.maintenance => 'Maintenance',
    };
    return '$name ($count)';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Aucune activité dans ce filtre',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _filterStatus = null),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.openTickets,
    required this.onTap,
  });

  final Activity activity;
  final int openTickets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = colors.getActivityColor(activity.id);
    final isUnavailable = activity.status == ActivityStatus.closed ||
        activity.status == ActivityStatus.maintenance;
    final statusColor = switch (activity.status) {
      ActivityStatus.open => colors.success,
      ActivityStatus.warning => colors.warning,
      ActivityStatus.closed => colors.danger,
      ActivityStatus.maintenance => colors.info,
    };

    return Material(
      color: colors.backgroundSecondary,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tinted header band
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color.withValues(alpha: isUnavailable ? 0.06 : 0.16),
                    color.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(
                      resolveActivityIcon(activity.iconKey),
                      color: isUnavailable ? colors.textMuted : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          activity.statusTextFrench,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (openTickets > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.build_outlined,
                                    size: 12, color: colors.danger),
                                const SizedBox(width: 4),
                                Text(
                                  '$openTickets',
                                  style: TextStyle(
                                    color: colors.danger,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 13, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.assignedStaff,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isUnavailable)
                      Row(
                        children: [
                          Icon(
                            activity.status == ActivityStatus.maintenance
                                ? Icons.build_circle_outlined
                                : Icons.lock_outline_rounded,
                            size: 13,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activity.status == ActivityStatus.maintenance
                                ? 'En maintenance'
                                : 'Accès fermé',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Occupation',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 11.5),
                          ),
                          Text(
                            '${activity.currentOccupancy}/${activity.maxCapacity}',
                            style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: activity.occupancyPercentage,
                          minHeight: 6,
                          backgroundColor: colors.surfaceHover,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            activity.occupancyPercentage > 0.85
                                ? colors.warning
                                : color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
