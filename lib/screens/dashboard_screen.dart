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
        title: const Text('Accueil'),
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
          constraints: const BoxConstraints(maxWidth: 1080),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _DashboardHeader(
                    openActivitiesCount: openActivitiesCount,
                    activeAnomaliesCount: activeAnomaliesCount,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            iconColor: AppColors.accentSecondary,
                            value: '$openActivitiesCount',
                            title: 'Activites ouvertes',
                          ),
                          KPITile(
                            icon: Icons.report_problem_outlined,
                            iconColor: AppColors.danger,
                            value: '$activeAnomaliesCount',
                            title: 'Anomalies actives',
                          ),
                          KPITile(
                            icon: Icons.engineering_outlined,
                            iconColor: AppColors.warning,
                            value: '$overdueMaintenanceCount',
                            title: 'Maintenances en retard',
                          ),
                          const KPITile(
                            icon: Icons.calendar_today_outlined,
                            iconColor: AppColors.pool,
                            value: '8',
                            title: "Reservations aujourd'hui",
                          ),
                          KPITile(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.horses,
                            value: '$lowStockItemsCount',
                            title: 'Stocks bas',
                          ),
                          const KPITile(
                            icon: Icons.groups_2_outlined,
                            iconColor: AppColors.padel,
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
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
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
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Voir tout'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final activityColor =
                        AppColors.getActivityColor(activity.id);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/activites/${activity.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: activityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(activity.iconData,
                                    color: activityColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.assignedStaff,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.16),
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
                const SizedBox(height: 8),
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
            child: const Icon(Icons.insights_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
