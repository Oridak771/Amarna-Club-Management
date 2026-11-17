import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/assets_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/activity_ui_adapter.dart';
import '../ui/asset_ui_adapter.dart';
import '../ui/ticket_ui_adapter.dart';
import '../widgets/app_layout.dart';
import '../widgets/inventory_stepper.dart';

/// Detail of one activity: live status and occupancy, then four tabs with its
/// inventory, equipment and interventions.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.id});

  final String id;

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
        maxCapacity: 0,
        assignedStaff: '',
      ),
    );
    final known = activities.any((a) => a.id == id);
    final color = resolveActivityColor(context, activity.id);

    return DefaultTabController(
      length: 4,
      child: AppPage(
        title: activity.name,
        subtitle: known ? activity.statusTextFrench : 'Activité introuvable',
        scrollable: true,
        padding: EdgeInsets.zero,
        maxWidth: 1100,
        actions: [
          if (known) _StatusMenu(activity: activity),
          IconButton(
            tooltip: 'Scanner QR',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push('/scan'),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Vue d’ensemble'),
            Tab(text: 'Inventaire'),
            Tab(text: 'Équipements'),
            Tab(text: 'Interventions'),
          ],
        ),
        body: !known
            ? const AppErrorState(
                title: 'Activité introuvable',
                message:
                    'Cette activité n’est pas dans les données synchronisées.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _Header(activity: activity, color: color),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(activity: activity),
                        _InventoryTab(activityId: activity.id),
                        _EquipmentTab(activityId: activity.id),
                        _InterventionsTab(activityId: activity.id),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: occupancy control and the activity's own module

class _Header extends ConsumerWidget {
  const _Header({required this.activity, required this.color});

  final Activity activity;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final module = _moduleFor(activity);
    final isOpen = activity.status == ActivityStatus.open ||
        activity.status == ActivityStatus.warning;
    final max = activity.maxCapacity;

    return AppPanel(
      accentColor: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Présents',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      max > 0
                          ? '${activity.currentOccupancy} / $max'
                          : '${activity.currentOccupancy}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundButton(
                icon: Icons.remove_rounded,
                tooltip: 'Retirer une personne',
                onTap: activity.currentOccupancy > 0
                    ? () => ref
                        .read(activitiesProvider.notifier)
                        .updateOccupancy(
                            activity.id, activity.currentOccupancy - 1)
                    : null,
              ),
              const SizedBox(width: 10),
              _RoundButton(
                icon: Icons.add_rounded,
                tooltip: 'Ajouter une personne',
                filled: true,
                color: color,
                onTap: isOpen && (max == 0 || activity.currentOccupancy < max)
                    ? () => ref
                        .read(activitiesProvider.notifier)
                        .updateOccupancy(
                            activity.id, activity.currentOccupancy + 1)
                    : null,
              ),
            ],
          ),
          if (max > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: activity.occupancyPercentage.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: colors.surface,
              ),
            ),
          ],
          if (module != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
              onPressed: () => context.push(module.route),
              icon: Icon(module.icon),
              label: Text(module.label),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = color ?? colors.accentPrimary;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? (filled ? accent : colors.surface)
            : colors.surface.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              size: 28,
              color: !enabled
                  ? colors.textMuted
                  : filled
                      ? Colors.white
                      : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleLink {
  const _ModuleLink(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

/// Route slug and icon of each dedicated screen. Which screen an activity
/// opens, and the text of the shortcut, are set by the admin in Odoo
/// (activity > Application tablette).
const _screens = <String, ({String slug, IconData icon})>{
  'pool': (slug: 'pool-gauges', icon: Icons.speed_rounded),
  'horses': (slug: 'horses', icon: Icons.pets_outlined),
  'armory': (slug: 'weapon-list', icon: Icons.gps_fixed_rounded),
  'padel': (slug: 'padel-courts', icon: Icons.sports_tennis_rounded),
  'paintball': (slug: 'paintball-field', icon: Icons.adjust_rounded),
  'gym': (slug: 'gym-equipment', icon: Icons.fitness_center_rounded),
};

_ModuleLink? _moduleFor(Activity activity) {
  final screen = _screens[activity.screenKey];
  if (screen == null) return null;
  return _ModuleLink(
    screen.icon,
    activity.screenLabel.isEmpty ? activity.name : activity.screenLabel,
    '/activites/${activity.id}/${screen.slug}',
  );
}

// ---------------------------------------------------------------------------
// Status menu in the app bar

class _StatusMenu extends ConsumerWidget {
  const _StatusMenu({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ActivityStatus>(
      tooltip: 'Changer le statut',
      icon: const Icon(Icons.swap_vert_circle_outlined),
      onSelected: (status) async {
        await ref
            .read(activitiesProvider.notifier)
            .updateStatus(activity.id, status);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour ✓')),
        );
      },
      itemBuilder: (context) => [
        for (final status in ActivityStatus.values)
          PopupMenuItem(
            value: status,
            height: 48,
            child: Row(
              children: [
                Icon(
                  status == activity.status
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: status.resolveColor(context),
                ),
                const SizedBox(width: 10),
                Text(switch (status) {
                  ActivityStatus.open => 'Ouverte',
                  ActivityStatus.warning => 'Attention',
                  ActivityStatus.maintenance => 'En maintenance',
                  ActivityStatus.closed => 'Fermée',
                }),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: overview

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tickets = ref.watch(ticketsProvider)
        .where((t) => t.activityId == activity.id)
        .toList();
    final open = tickets.where((t) => t.status != TicketStatus.resolved).toList();
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        AppPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Personnel en service',
                value: activity.assignedStaff.isEmpty
                    ? 'Non renseigné'
                    : activity.assignedStaff,
              ),
              if (activity.closureStart != null) ...[
                Divider(height: 24, color: colors.border),
                _InfoRow(
                  icon: Icons.event_busy_outlined,
                  label: 'Fermeture depuis',
                  value: dateFormat.format(activity.closureStart!.toLocal()),
                  valueColor: colors.warning,
                ),
                if (activity.closureEnd != null) ...[
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Réouverture prévue',
                    value: dateFormat.format(activity.closureEnd!.toLocal()),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionTitle(
          title: 'Interventions ouvertes',
          count: open.length,
          icon: Icons.assignment_outlined,
        ),
        if (open.isEmpty)
          const AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Aucune intervention ouverte',
            message: 'Cette activité est à jour.',
          )
        else
          for (final ticket in open.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppPanel(
                accentColor: ticket.isOverdue
                    ? colors.danger
                    : ticket.priority.resolveColor(context),
                onTap: () => context.push('/tickets/${ticket.id}'),
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => context.go('/tickets/nouveau'),
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('Signaler un incident'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => context.go('/planning'),
          icon: const Icon(Icons.event_note_rounded),
          label: const Text('Voir le planning'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: inventory

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab({required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(inventoryProvider)
        .where((item) => item.activityId == activityId)
        .toList();

    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Aucun consommable pour cette activité',
        message: 'Les consommables apparaissent ici après synchronisation.',
      );
    }

    final low = items.where((i) => i.isLowStock).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (low > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppPill(
              label: '$low article${low > 1 ? 's' : ''} à réapprovisionner',
              color: context.colors.warning,
              icon: Icons.warning_amber_rounded,
            ),
          ),
        for (final InventoryItem item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InventoryStepper(
              item: item,
              onChanged: (delta) => ref
                  .read(inventoryProvider.notifier)
                  .adjustStock(item.id, delta),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: equipment

class _EquipmentTab extends ConsumerWidget {
  const _EquipmentTab({required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final assets = ref
        .watch(assetsProvider)
        .where((a) => a.activityId == activityId)
        .toList();

    if (assets.isEmpty) {
      return const AppEmptyState(
        icon: Icons.build_circle_outlined,
        title: 'Aucun équipement enregistré',
        message: 'Les équipements de cette activité apparaissent ici.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final Asset asset = assets[index];
        final statusColor = asset.status.resolveColor(context);
        return AppPanel(
          onTap: () => context.push('/asset/${asset.id}'),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (asset.category.isNotEmpty) asset.category,
                        if (asset.serialNumber.isNotEmpty)
                          'n° ${asset.serialNumber}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppPill(label: asset.statusTextFrench, color: statusColor),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: interventions

class _InterventionsTab extends ConsumerWidget {
  const _InterventionsTab({required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tickets = ref
        .watch(ticketsProvider)
        .where((t) => t.activityId == activityId)
        .toList()
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: colors.danger,
          ),
          onPressed: () => context.go('/tickets/nouveau'),
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('Signaler dans cette activité'),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          const AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Aucune intervention',
            message: 'Rien à signaler pour cette activité.',
          )
        else
          for (final ticket in tickets)
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
    final resolved = ticket.status == TicketStatus.resolved;
    return AppPanel(
      onTap: () => context.push('/tickets/${ticket.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                    fontWeight: FontWeight.w800,
                    color: resolved ? colors.textSecondary : colors.textPrimary,
                    decoration: resolved ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.statusTextFrench,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppPill(
            label: ticket.priorityTextFrench,
            color: ticket.priority.resolveColor(context),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    );
  }
}
