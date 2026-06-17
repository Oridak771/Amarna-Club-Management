import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/tickets_provider.dart';
import 'package:amarna_club/providers/inventory_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/kpi_tile.dart';
import 'package:amarna_club/widgets/offline_banner.dart';
import 'package:amarna_club/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final tickets = ref.watch(ticketsProvider);
    final inventoryItems = ref.watch(inventoryProvider);

    // Compute metrics
    final openActivitiesCount = activities.where((a) => a.status == ActivityStatus.open).length;
    final activeAnomaliesCount = tickets.where((t) => t.type == TicketType.anomaly && t.status != TicketStatus.resolved).length;
    final now = DateTime.now();
    final overdueMaintenanceCount = tickets.where((t) =>
        t.type != TicketType.anomaly &&
        t.status != TicketStatus.resolved &&
        t.dateDue != null &&
        t.dateDue!.isBefore(now)).length;
    final lowStockItemsCount = inventoryItems.where((item) => item.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonjour, Opérateur 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR/NFC',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Key Performance Indicators (KPIs)
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final colsCount = constraints.maxWidth > 600 ? 3 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: colsCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth > 600 ? 1.35 : 1.1,
                        children: [
                          KPITile(
                            icon: Icons.flash_on,
                            iconColor: AppColors.accentSecondary,
                            value: '$openActivitiesCount',
                            title: 'Activités ouvertes',
                          ),
                          KPITile(
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.danger,
                            value: '$activeAnomaliesCount',
                            title: 'Anomalies actives',
                          ),
                          KPITile(
                            icon: Icons.build_outlined,
                            iconColor: AppColors.warning,
                            value: '$overdueMaintenanceCount',
                            title: 'Maintenances en retard',
                          ),
                          const KPITile(
                            icon: Icons.calendar_today_outlined,
                            iconColor: AppColors.pool,
                            value: '8',
                            title: "Réservations d'aujourd'hui",
                          ),
                          KPITile(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.horses,
                            value: '$lowStockItemsCount',
                            title: 'Articles en stock bas',
                          ),
                          const KPITile(
                            icon: Icons.people_outline,
                            iconColor: AppColors.padel,
                            value: '72%',
                            title: 'Occupation actuelle',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section: Activity Status List
                  const Text(
                    'Statut des Activités',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final activityColor = AppColors.getActivityColor(activity.id);

                      return Card(
                        color: AppColors.backgroundSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/activites/${activity.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: activityColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    activity.iconData,
                                    color: activityColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Name & Staff info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activity.assignedStaff,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status
                                StatusBadge(status: activity.status),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
