import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/providers/tickets_provider.dart';
import 'package:amarna_club/providers/inventory_provider.dart';
import 'package:amarna_club/providers/assets_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:amarna_club/ui/asset_ui_adapter.dart';
import 'package:amarna_club/ui/ticket_ui_adapter.dart';
import 'package:amarna_club/widgets/activity_panels.dart';
import 'package:amarna_club/widgets/inventory_stepper.dart';
import 'package:amarna_club/widgets/priority_indicator.dart';
import 'package:amarna_club/widgets/status_badge.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String id;
  const ActivityDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
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
        closureStart: null,
        closureEnd: null,
      ),
    );
    final color = colors.getActivityColor(activity.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildHeader(context, activity, color),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _buildStatusRow(context, ref, activity),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _buildQuickActions(context, activity.id),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: color,
                    labelColor: colors.textPrimary,
                    unselectedLabelColor: colors.textSecondary,
                    tabs: const [
                      Tab(text: "Vue d'ensemble"),
                      Tab(text: 'Inventaire'),
                      Tab(text: 'Équipement'),
                      Tab(text: 'Interventions'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildOverviewTab(context, ref, activity, color),
              _buildInventoryTab(context, ref, activity.id),
              _buildEquipmentTab(context, ref, activity.id),
              _buildTicketsTab(context, ref, activity.id),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  SliverAppBar _buildHeader(
      BuildContext context, Activity activity, Color color) {
    final colors = context.colors;
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: colors.backgroundPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scanner QR',
          onPressed: () => context.push('/scan'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsets.only(left: 56, bottom: 14, right: 56),
        title: Text(
          activity.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.28),
                    colors.backgroundPrimary,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: 10,
              child: Icon(
                resolveActivityIcon(activity.iconKey),
                size: 140,
                color: color.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status + occupancy row ─────────────────────────────────

  Widget _buildStatusRow(
      BuildContext context, WidgetRef ref, Activity activity) {
    final colors = context.colors;
    return Row(
      children: [
        StatusBadge(status: activity.status),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 15, color: colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activity.assignedStaff,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<ActivityStatus>(
          tooltip: 'Changer le statut',
          icon: Icon(Icons.swap_horiz_rounded, color: colors.textSecondary),
          onSelected: (status) {
            ref
                .read(activitiesProvider.notifier)
                .updateStatus(activity.id, status);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statut mis à jour ✓')),
            );
          },
          itemBuilder: (context) => [
            for (final status in ActivityStatus.values)
              PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    if (status == activity.status)
                      const Icon(Icons.check_rounded, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(switch (status) {
                      ActivityStatus.open => 'Ouvrir',
                      ActivityStatus.warning => 'Mettre en alerte',
                      ActivityStatus.maintenance => 'En maintenance',
                      ActivityStatus.closed => 'Fermer',
                    }),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Quick actions ──────────────────────────────────────────

  List<Widget> _buildQuickActions(BuildContext context, String activityId) {
    final colors = context.colors;

    final (moduleIcon, moduleLabel, moduleRoute) = switch (activityId) {
      'pool' => (
          Icons.speed_rounded,
          'Qualité de l\'eau',
          '/activites/pool/pool-gauges'
        ),
      'horses' => (
          Icons.bedroom_baby_outlined,
          'Écurie',
          '/activites/horses/horses'
        ),
      'shooting' => (
          Icons.gps_fixed_rounded,
          'Armurerie',
          '/activites/shooting/weapon-list'
        ),
      'padel' => (
          Icons.sports_tennis_rounded,
          'Terrains',
          '/activites/padel/padel-courts'
        ),
      'paintball' => (
          Icons.adjust_rounded,
          'Terrain',
          '/activites/paintball/paintball-field'
        ),
      'gym' => (
          Icons.fitness_center_rounded,
          'Machines',
          '/activites/gym/gym-equipment'
        ),
      _ => (null, null, null),
    };

    Widget chip(IconData icon, String label, Color color, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ActionChip(
          avatar: Icon(icon, size: 18, color: color),
          label: Text(label),
          labelStyle: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          backgroundColor: color.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          onPressed: onTap,
        ),
      );
    }

    return [
      if (moduleRoute != null)
        chip(moduleIcon!, moduleLabel!, colors.getActivityColor(activityId),
            () => context.push(moduleRoute)),
      chip(Icons.report_problem_rounded, 'Signaler', colors.danger,
          () => context.go('/tickets/nouveau')),
      chip(Icons.event_available_rounded, 'Réservations', colors.info,
          () => context.go('/plus/reservations')),
    ];
  }

  // ── Tab 1 : Vue d'ensemble ─────────────────────────────────

  Widget _buildOverviewTab(
      BuildContext context, WidgetRef ref, Activity activity, Color color) {
    final colors = context.colors;
    final isOpen = activity.status == ActivityStatus.open ||
        activity.status == ActivityStatus.warning;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Occupancy control
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Occupation en temps réel',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    '${(activity.occupancyPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: activity.occupancyPercentage,
                  minHeight: 8,
                  backgroundColor: colors.surfaceHover,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    activity.occupancyPercentage > 0.85
                        ? colors.warning
                        : color,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _OccupancyButton(
                    icon: Icons.remove_rounded,
                    enabled: isOpen && activity.currentOccupancy > 0,
                    onTap: () => ref
                        .read(activitiesProvider.notifier)
                        .updateOccupancy(
                            activity.id, activity.currentOccupancy - 1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${activity.currentOccupancy} / ${activity.maxCapacity}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  _OccupancyButton(
                    icon: Icons.add_rounded,
                    enabled: isOpen &&
                        activity.currentOccupancy < activity.maxCapacity,
                    onTap: () => ref
                        .read(activitiesProvider.notifier)
                        .updateOccupancy(
                            activity.id, activity.currentOccupancy + 1),
                  ),
                ],
              ),
              if (!isOpen) ...[
                const SizedBox(height: 8),
                Text(
                  'Activité ${activity.statusTextFrench.toLowerCase()} — comptage désactivé.',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live reservations from Odoo
        ActivityReservationsPanel(
          activityId: activity.id,
          activityName: activity.name,
        ),
        const SizedBox(height: 20),

        ActivityTicketsPanel(activityId: activity.id),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Tab 2 : Inventaire ─────────────────────────────────────

  Widget _buildInventoryTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final items = ref
        .watch(inventoryProvider)
        .where((item) => item.activityId == activityId)
        .toList();

    if (items.isEmpty) {
      return _emptyState(context, Icons.inventory_2_outlined,
          'Aucun consommable enregistré pour cette activité.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => InventoryStepper(
        item: items[index],
        onChanged: (delta) => ref
            .read(inventoryProvider.notifier)
            .adjustStock(items[index].id, delta),
      ),
    );
  }

  // ── Tab 3 : Équipement ─────────────────────────────────────

  Widget _buildEquipmentTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final colors = context.colors;
    final assets = ref
        .watch(assetsProvider)
        .where((a) => a.activityId == activityId)
        .toList();

    if (assets.isEmpty) {
      return _emptyState(context, Icons.construction,
          'Aucun équipement enregistré pour cette activité.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Material(
          color: colors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/asset/${asset.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/N : ${asset.serialNumber} · ${asset.category}',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: asset.status
                          .resolveColor(context)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asset.statusTextFrench,
                      style: TextStyle(
                        color: asset.status.resolveColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: colors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4 : Interventions ──────────────────────────────────

  Widget _buildTicketsTab(
      BuildContext context, WidgetRef ref, String activityId) {
    final colors = context.colors;
    final tickets = ref
        .watch(ticketsProvider)
        .where((t) => t.activityId == activityId)
        .toList();

    if (tickets.isEmpty) {
      return _emptyState(context, Icons.assignment_outlined,
          'Aucune intervention pour cette activité.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return GestureDetector(
          onTap: () => context.go('/tickets/${ticket.id}'),
          child: PriorityIndicator(
            priority: ticket.priority,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket.statusTextFrench,
                        style: TextStyle(
                          color: ticket.status
                              .resolveColor(context, type: ticket.type),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ticket.type
                              .resolveColor(context)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          ticket.typeTextFrench,
                          style: TextStyle(
                            color: ticket.type.resolveColor(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (ticket.dateDue != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: ticket.isOverdue
                              ? colors.danger
                              : colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(ticket.dateDue!),
                          style: TextStyle(
                            color: ticket.isOverdue
                                ? colors.danger
                                : colors.textMuted,
                            fontSize: 11,
                            fontWeight: ticket.isOverdue
                                ? FontWeight.w800
                                : FontWeight.w400,
                          ),
                        ),
                      ],
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

  Widget _emptyState(BuildContext context, IconData icon, String message) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancyButton extends StatelessWidget {
  const _OccupancyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: enabled
          ? colors.accentPrimary.withValues(alpha: 0.1)
          : colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            size: 28,
            color: enabled ? colors.accentPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
