import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/inventory_provider.dart';
import 'package:amarna_club/providers/tickets_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/kpi_tile.dart';
import 'package:amarna_club/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final tickets = ref.watch(ticketsProvider);
    final inventoryItems = ref.watch(inventoryProvider);

    final openActivitiesCount =
        activities.where((a) => a.status == ActivityStatus.open).length;
    final activeAnomaliesCount = tickets
        .where((t) =>
            t.type == TicketType.anomaly && t.status != TicketStatus.resolved)
        .length;
    final now = DateTime.now();
    final overdueMaintenanceCount = tickets
        .where(
          (t) =>
              t.type != TicketType.anomaly &&
              t.status != TicketStatus.resolved &&
              t.dateDue != null &&
              t.dateDue!.isBefore(now),
        )
        .length;
    final lowStockItemsCount =
        inventoryItems.where((item) => item.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
        actions: [
          IconButton.filledTonal(
            icon: Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner QR/NFC',
            onPressed: () => context.push('/scan'),
          ),
          SizedBox(width: 8),
          IconButton.filledTonal(
            icon: Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1080),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _DashboardHeader(
                    openActivitiesCount: openActivitiesCount,
                    activeAnomaliesCount: activeAnomaliesCount,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 560
                              ? 3
                              : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio:
                            constraints.maxWidth >= 560 ? 1.45 : 1.08,
                        children: [
                          KPITile(
                            icon: Icons.grid_view_rounded,
                            iconColor: context.colors.accentSecondary,
                            value: '$openActivitiesCount',
                            title: 'Activites ouvertes',
                          ),
                          KPITile(
                            icon: Icons.report_problem_outlined,
                            iconColor: context.colors.danger,
                            value: '$activeAnomaliesCount',
                            title: 'Anomalies actives',
                          ),
                          KPITile(
                            icon: Icons.engineering_outlined,
                            iconColor: context.colors.warning,
                            value: '$overdueMaintenanceCount',
                            title: 'Maintenances en retard',
                          ),
                          KPITile(
                            icon: Icons.calendar_today_outlined,
                            iconColor: context.colors.pool,
                            value: '8',
                            title: "Reservations aujourd'hui",
                          ),
                          KPITile(
                            icon: Icons.inventory_2_outlined,
                            iconColor: context.colors.horses,
                            value: '$lowStockItemsCount',
                            title: 'Stocks bas',
                          ),
                          KPITile(
                            icon: Icons.groups_2_outlined,
                            iconColor: context.colors.padel,
                            value: '72%',
                            title: 'Occupation actuelle',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Statut des activites',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/activites'),
                        icon: Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text('Voir tout'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final activityColor =
                        resolveActivityColor(context, activity.id);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/activites/${activity.id}'),
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: activityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(resolveActivityIcon(activity.iconKey),
                                    color: activityColor),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.name,
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      activity.assignedStaff,
                                      style: TextStyle(
                                        color: context.colors.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              StatusBadge(status: activity.status),
                            ],
                          ),
                        ),
                      ),
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
}

class _DashboardHeader extends StatelessWidget {
  final int openActivitiesCount;
  final int activeAnomaliesCount;

  const _DashboardHeader({
    required this.openActivitiesCount,
    required this.activeAnomaliesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.accentPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: context.colors.accentPrimary.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, Operateur',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  '$openActivitiesCount activites ouvertes, $activeAnomaliesCount anomalies a suivre.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.insights_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
