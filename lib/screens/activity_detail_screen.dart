import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/tickets_provider.dart';
import 'package:amarna_club/providers/inventory_provider.dart';
import 'package:amarna_club/providers/assets_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/inventory_stepper.dart';
import 'package:amarna_club/widgets/priority_indicator.dart';
import 'package:amarna_club/widgets/status_badge.dart';
import 'package:amarna_club/widgets/quick_action_button.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String id;
  ActivityDetailScreen({super.key, required this.id});

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

    final activityColor = Theme.of(context).extension<AppSemanticColors>()!.getActivityColor(activity.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // Immersive Photographic / Gradient Header
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.backgroundPrimary,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () => context.push('/scan'),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    activity.name,
                    style: TextStyle(
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
                              Theme.of(context).extension<AppSemanticColors>()!.backgroundPrimary,
                            ],
                          ),
                        ),
                      ),
                      // Overlay Icon
                      Center(
                        child: Opacity(
                          opacity: 0.15,
                          child: Icon(
                            resolveActivityIcon(activity.iconKey),
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
                              Theme.of(context).extension<AppSemanticColors>()!.backgroundPrimary
                                  .withValues(alpha: 0.8),
                              Theme.of(context).extension<AppSemanticColors>()!.backgroundPrimary,
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Statut actuel : ',
                                style: TextStyle(
                                    color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                    fontSize: 14),
                              ),
                              StatusBadge(status: activity.status),
                            ],
                          ),
                          if (activity.maxCapacity > 0)
                            Text(
                              'Occupation : ${activity.currentOccupancy}/${activity.maxCapacity}',
                              style: TextStyle(
                                color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Quick Actions Row (Horizontal Scroll)
                    SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        children: _buildQuickActions(context, activity.id),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Inner Tabs
                    TabBar(
                      isScrollable: true,
                      indicatorColor: Theme.of(context).extension<AppSemanticColors>()!.accentPrimary,
                      labelColor: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                      unselectedLabelColor: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                      tabs: [
                        Tab(text: "Vue d'ensemble"),
                        Tab(text: "Inventaire"),
                        Tab(text: "Équipement"),
                        Tab(text: "Tickets"),
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
              _buildTicketsTab(context, ref, activity.id),
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
        color: Theme.of(context).extension<AppSemanticColors>()!.success,
        onTap: () => context.push('/activites/$activityId/checklist'),
      ),
    );
    actions.add(SizedBox(width: 12));

    // Activity Specific Actions
    if (activityId == 'pool') {
      actions.add(
        QuickActionButton(
          icon: Icons.speed,
          label: 'Gauges Eau',
          color: Theme.of(context).extension<AppSemanticColors>()!.pool,
          onTap: () => context.push('/activites/pool/pool-gauges'),
        ),
      );
      actions.add(SizedBox(width: 12));
    } else if (activityId == 'horses') {
      actions.add(
        QuickActionButton(
          icon: Icons.pets,
          label: 'Chevaux',
          color: Theme.of(context).extension<AppSemanticColors>()!.horses,
          onTap: () => context.push('/activites/horses/horses'),
        ),
      );
      actions.add(SizedBox(width: 12));
    } else if (activityId == 'shooting') {
      actions.add(
        QuickActionButton(
          icon: Icons.gps_fixed,
          label: 'Armes',
          color: Theme.of(context).extension<AppSemanticColors>()!.danger,
          onTap: () => context.push('/activites/shooting/weapon-list'),
        ),
      );
      actions.add(SizedBox(width: 12));
    } else if (activityId == 'padel') {
      actions.add(
        QuickActionButton(
          icon: Icons.sports_tennis,
          label: 'Terrains',
          color: Theme.of(context).extension<AppSemanticColors>()!.padel,
          onTap: () => context.push('/activites/padel/padel-courts'),
        ),
      );
      actions.add(SizedBox(width: 12));
    } else if (activityId == 'paintball') {
      actions.add(
        QuickActionButton(
          icon: Icons.adjust,
          label: 'Terrain',
          color: Theme.of(context).extension<AppSemanticColors>()!.paintball,
          onTap: () => context.push('/activites/paintball/paintball-field'),
        ),
      );
      actions.add(SizedBox(width: 12));
    } else if (activityId == 'gym') {
      actions.add(
        QuickActionButton(
          icon: Icons.fitness_center,
          label: 'Équipements',
          color: Theme.of(context).extension<AppSemanticColors>()!.gym,
          onTap: () => context.push('/activites/gym/gym-equipment'),
        ),
      );
      actions.add(SizedBox(width: 12));
    }

    // Common standard report buttons
    actions.add(
      QuickActionButton(
        icon: Icons.warning_amber_rounded,
        label: 'Signaler Panne',
        color: Theme.of(context).extension<AppSemanticColors>()!.danger,
        onTap: () => context.push('/tickets/nouveau'),
      ),
    );

    // Also add a quick reservation shortcut
    actions.add(SizedBox(width: 12));
    actions.add(
      QuickActionButton(
        icon: Icons.calendar_month_outlined,
        label: 'Réservation',
        color: Theme.of(context).extension<AppSemanticColors>()!.accentPrimary,
        onTap: () => context.push('/plus/reservations'),
      ),
    );

    return actions;
  }

  // ── Tab 1: Vue d'ensemble ──────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, Activity activity) {
    final activityColor = Theme.of(context).extension<AppSemanticColors>()!.getActivityColor(activity.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Assignment Card
          Card(
            color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).extension<AppSemanticColors>()!.border),
            ),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: activityColor),
              ),
              title: Text(
                'Personnel en service',
                style: TextStyle(
                    color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                activity.assignedStaff,
                style: TextStyle(
                    color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 13),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Occupancy Progress Box
          Card(
            color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).extension<AppSemanticColors>()!.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Occupation en Temps Réel',
                    style: TextStyle(
                      color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capacité actuelle : ${activity.currentOccupancy} / ${activity.maxCapacity}',
                        style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 13),
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
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activity.occupancyPercentage,
                      backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(activityColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Today's Reservations List Mock
          Text(
            "Réservations d'aujourd'hui",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          _buildReservationRow(
              '09:00 - 10:30', 'Entraînement Club junior', '12 pers.'),
          SizedBox(height: 8),
          _buildReservationRow(
              '14:00 - 16:00', 'Réservation Groupe Privé', '8 pers.'),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReservationRow(String time, String title, String count) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<AppSemanticColors>()!.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 16, color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary),
              SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(
                  color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            count,
            style: TextStyle(
              color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Inventaire ──────────────────────────────────────
  Widget _buildInventoryTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final inventoryItems = ref.watch(inventoryProvider);
    final items =
        inventoryItems.where((item) => item.activityId == activityId).toList();

    if (items.isEmpty) {
      return _buildEmptyState(context, 
        Icons.inventory_2_outlined,
        'Aucun consommable enregistré pour cette activité.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 8.0),
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
  Widget _buildEquipmentTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final allAssets = ref.watch(assetsProvider);
    final assets = allAssets.where((a) => a.activityId == activityId).toList();

    if (assets.isEmpty) {
      return _buildEmptyState(context, 
        Icons.construction,
        'Aucun équipement enregistré pour cette activité.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];

        return Card(
          color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).extension<AppSemanticColors>()!.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/asset/${asset.id}'),
            child: Padding(
              padding: EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'S/N: ${asset.serialNumber} • ${asset.category}',
                          style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: asset.status.resolveColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asset.statusTextFrench,
                      style: TextStyle(
                        color: asset.status.resolveColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).extension<AppSemanticColors>()!.textMuted,
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

  // ── Tab 4: Tickets ─────────────────────────────────────────
  Widget _buildTicketsTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final allTickets = ref.watch(ticketsProvider);
    final activityTickets =
        allTickets.where((t) => t.activityId == activityId).toList();

    if (activityTickets.isEmpty) {
      return _buildEmptyState(context, 
        Icons.assignment_outlined,
        'Aucun ticket (anomalie ou maintenance) pour cette activité.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: activityTickets.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ticket = activityTickets[index];
        final isOverdue = ticket.status != TicketStatus.resolved &&
            ticket.dateDue != null &&
            ticket.dateDue!.isBefore(DateTime.now());

        return GestureDetector(
          onTap: () => context.push('/tickets/${ticket.id}'),
          child: PriorityIndicator(
            priority: ticket.priority,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        ticket.statusTextFrench,
                        style: TextStyle(
                          color: ticket.status.resolveColor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: ticket.type.resolveColor(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket.typeTextFrench,
                          style: TextStyle(
                              color: ticket.type.resolveColor(context),
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (ticket.assetName != null) ...[
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Équipement: ${ticket.assetName}',
                            style: TextStyle(
                                color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (ticket.dateDue != null) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: isOverdue
                              ? Theme.of(context).extension<AppSemanticColors>()!.danger
                              : Theme.of(context).extension<AppSemanticColors>()!.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(ticket.dateDue!),
                          style: TextStyle(
                            color: isOverdue
                                ? Theme.of(context).extension<AppSemanticColors>()!.danger
                                : Theme.of(context).extension<AppSemanticColors>()!.textMuted,
                            fontSize: 11,
                            fontWeight:
                                isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper empty state
  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).extension<AppSemanticColors>()!.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
