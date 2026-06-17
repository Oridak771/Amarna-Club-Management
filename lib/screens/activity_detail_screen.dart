import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/maintenance_task.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/incidents_provider.dart';
import 'package:amarna_club/providers/inventory_provider.dart';
import 'package:amarna_club/providers/maintenance_provider.dart';
import 'package:amarna_club/providers/assets_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/inventory_stepper.dart';
import 'package:amarna_club/widgets/priority_indicator.dart';
import 'package:amarna_club/widgets/status_badge.dart';
import 'package:amarna_club/widgets/quick_action_button.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String id;
  const ActivityDetailScreen({super.key, required this.id});

  // Mock list of assets/equipment by activity
  // Refactored to use Isar via assetsProvider

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final activity = activities.firstWhere(
      (a) => a.id == id,
      orElse: () => Activity(
        id: id,
        name: id.toUpperCase(),
        iconKey: 'help',
        status: ActivityStatus.closed,
        currentOccupancy: 0,
        maxCapacity: 100,
        assignedStaff: 'Non assigné',
      ),
    );

    final activityColor = AppColors.getActivityColor(activity.id);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // Immersive Photographic / Gradient Header
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.backgroundPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => context.push('/scan'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    activity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Decorative Gradient mimicking brand photos
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              activityColor.withValues(alpha: 0.8),
                              AppColors.backgroundPrimary,
                            ],
                          ),
                        ),
                      ),
                      // Overlay Icon
                      Center(
                        child: Opacity(
                          opacity: 0.15,
                          child: Icon(
                            activity.iconData,
                            size: 110,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Bottom Shadow overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.backgroundPrimary.withValues(alpha: 0.8),
                              AppColors.backgroundPrimary,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions & Tab Selection Header
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Bar details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Statut actuel : ',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              StatusBadge(status: activity.status),
                            ],
                          ),
                          if (activity.maxCapacity > 0)
                            Text(
                              'Occupation : ${activity.currentOccupancy}/${activity.maxCapacity}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Quick Actions Row (Horizontal Scroll)
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _buildQuickActions(context, activity.id),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Inner Tabs
                    const TabBar(
                      isScrollable: true,
                      indicatorColor: AppColors.accentPrimary,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: [
                        Tab(text: "Vue d'ensemble"),
                        Tab(text: "Inventaire"),
                        Tab(text: "Équipement"),
                        Tab(text: "Maintenance"),
                        Tab(text: "Incidents"),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildOverviewTab(context, activity),
              _buildInventoryTab(context, ref, activity.id),
              _buildEquipmentTab(context, ref, activity.id),
              _buildMaintenanceTab(context, ref, activity.id),
              _buildIncidentsTab(context, ref, activity.id),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build Quick Actions based on Activity ID ────────────────
  List<Widget> _buildQuickActions(BuildContext context, String activityId) {
    final List<Widget> actions = [];

    // Common Checklist Quick Action
    actions.add(
      QuickActionButton(
        icon: Icons.checklist_rounded,
        label: 'Checklist',
        color: AppColors.success,
        onTap: () => context.push('/activites/$activityId/checklist'),
      ),
    );
    actions.add(const SizedBox(width: 12));

    // Activity Specific Actions
    if (activityId == 'pool') {
      actions.add(
        QuickActionButton(
          icon: Icons.speed,
          label: 'Gauges Eau',
          color: AppColors.pool,
          onTap: () => context.push('/activites/pool/pool-gauges'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    } else if (activityId == 'horses') {
      actions.add(
        QuickActionButton(
          icon: Icons.pets,
          label: 'Chevaux',
          color: AppColors.horses,
          onTap: () => context.push('/activites/horses/horses'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    } else if (activityId == 'shooting') {
      actions.add(
        QuickActionButton(
          icon: Icons.gps_fixed,
          label: 'Armes',
          color: AppColors.danger,
          onTap: () => context.push('/activites/shooting/weapon-list'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    } else if (activityId == 'padel') {
      actions.add(
        QuickActionButton(
          icon: Icons.sports_tennis,
          label: 'Terrains',
          color: AppColors.padel,
          onTap: () => context.push('/activites/padel/padel-courts'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    } else if (activityId == 'paintball') {
      actions.add(
        QuickActionButton(
          icon: Icons.adjust,
          label: 'Terrain',
          color: AppColors.paintball,
          onTap: () => context.push('/activites/paintball/paintball-field'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    } else if (activityId == 'gym') {
      actions.add(
        QuickActionButton(
          icon: Icons.fitness_center,
          label: 'Équipements',
          color: AppColors.gym,
          onTap: () => context.push('/activites/gym/gym-equipment'),
        ),
      );
      actions.add(const SizedBox(width: 12));
    }

    // Common standard report buttons
    actions.add(
      QuickActionButton(
        icon: Icons.warning_amber_rounded,
        label: 'Incident',
        color: AppColors.danger,
        onTap: () => context.push('/incidents/nouveau'),
      ),
    );
    actions.add(const SizedBox(width: 12));

    actions.add(
      QuickActionButton(
        icon: Icons.build_outlined,
        label: 'Maintenance',
        color: AppColors.warning,
        onTap: () => context.push('/maintenance/nouveau'),
      ),
    );

    return actions;
  }

  // ── Tab 1: Vue d'ensemble ──────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, Activity activity) {
    final activityColor = AppColors.getActivityColor(activity.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Assignment Card
          Card(
            color: AppColors.backgroundSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: activityColor),
              ),
              title: const Text(
                'Personnel en service',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                activity.assignedStaff,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Occupancy Progress Box
          Card(
            color: AppColors.backgroundSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Occupation en Temps Réel',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capacité actuelle : ${activity.currentOccupancy} / ${activity.maxCapacity}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${(activity.occupancyPercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: activityColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activity.occupancyPercentage,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(activityColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Today's Reservations List Mock
          const Text(
            "Réservations d'aujourd'hui",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildReservationRow('09:00 - 10:30', 'Entraînement Club junior', '12 pers.'),
          const SizedBox(height: 8),
          _buildReservationRow('14:00 - 16:00', 'Réservation Groupe Privé', '8 pers.'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReservationRow(String time, String title, String count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            count,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Inventaire ──────────────────────────────────────
  Widget _buildInventoryTab(BuildContext context, WidgetRef ref, String activityId) {
    final inventoryItems = ref.watch(inventoryProvider);
    final items = inventoryItems.where((item) => item.activityId == activityId).toList();

    if (items.isEmpty) {
      return _buildEmptyState(
        Icons.inventory_2_outlined,
        'Aucun consommable enregistré pour cette activité.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InventoryStepper(
            item: item,
            onChanged: (delta) {
              ref.read(inventoryProvider.notifier).adjustStock(item.id, delta);
            },
          ),
        );
      },
    );
  }

  // ── Tab 3: Équipement ──────────────────────────────────────
  Widget _buildEquipmentTab(BuildContext context, WidgetRef ref, String activityId) {
    final allAssets = ref.watch(assetsProvider);
    final assets = allAssets.where((a) => a.activityId == activityId).toList();

    if (assets.isEmpty) {
      return _buildEmptyState(
        Icons.construction,
        'Aucun équipement enregistré pour cette activité.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];

        return Card(
          color: AppColors.backgroundSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/asset/${asset.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/N: ${asset.serialNumber} • ${asset.category}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: asset.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asset.statusTextFrench,
                      style: TextStyle(
                        color: asset.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Maintenance ─────────────────────────────────────
  Widget _buildMaintenanceTab(BuildContext context, WidgetRef ref, String activityId) {
    final tasks = ref.watch(maintenanceProvider);
    final activityTasks = tasks.where((t) => t.activityId == activityId).toList();

    if (activityTasks.isEmpty) {
      return _buildEmptyState(
        Icons.build_circle_outlined,
        'Aucune tâche de maintenance pour cette activité.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activityTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = activityTasks[index];
        final now = DateTime.now();
        final isOverdue = task.status != MaintenanceStatus.done && task.dateDue.isBefore(now);

        return GestureDetector(
          onTap: () => context.push('/maintenance/${task.id}'),
          child: PriorityIndicator(
            priority: task.priority,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.statusTextFrench,
                        style: TextStyle(
                          color: task.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Asset: ${task.assetName}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: isOverdue ? AppColors.danger : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(task.dateDue),
                        style: TextStyle(
                          color: isOverdue ? AppColors.danger : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 5: Incidents ───────────────────────────────────────
  Widget _buildIncidentsTab(BuildContext context, WidgetRef ref, String activityId) {
    final allIncidents = ref.watch(incidentsProvider);
    final activityIncidents = allIncidents.where((i) => i.activityId == activityId).toList();

    if (activityIncidents.isEmpty) {
      return _buildEmptyState(
        Icons.warning_amber_rounded,
        'Aucun incident signalé pour cette activité.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activityIncidents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final incident = activityIncidents[index];

        return GestureDetector(
          onTap: () => context.push('/incidents/${incident.id}'),
          child: PriorityIndicator(
            priority: incident.priority,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          incident.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        incident.statusTextFrench,
                        style: TextStyle(
                          color: incident.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Priorité: ${incident.priorityTextFrench}',
                    style: TextStyle(color: incident.priorityColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper empty state
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
