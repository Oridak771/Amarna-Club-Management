import 'package:amarna_club/ui/ticket_ui_adapter.dart';
import 'package:amarna_club/ui/asset_ui_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/work_ticket.dart';
import '../providers/assets_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

class AssetProfileScreen extends ConsumerWidget {
  final String id;
  const AssetProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final assets = ref.watch(assetsProvider);
    final asset = assets.firstWhere(
      (a) => a.id == id || a.serialNumber == id,
      orElse: () => Asset(
        id: id,
        serialNumber: id,
        name: 'Équipement non répertorié',
        category: 'Inconnu',
        activityId: '',
        status: AssetStatus.broken,
      ),
    );

    final isNotFound = asset.name == 'Équipement non répertorié';

    if (isNotFound) {
      return AppPage(
        title: 'Profil équipement',
        body: AppEmptyState(
          icon: Icons.warning_amber_rounded,
          title: 'Équipement introuvable',
          message: 'Le code "$id" ne correspond à aucun équipement enregistré.',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size(220, 52),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scanner à nouveau'),
            onPressed: () => context.pushReplacement('/scan'),
          ),
        ),
      );
    }

    // Load related tickets
    final tickets = ref.watch(ticketsProvider);
    final assetTickets = tickets
        .where((t) =>
            t.assetId == asset.id ||
            t.assetName == asset.name ||
            t.title.contains(asset.name) ||
            t.description.contains(asset.name))
        .toList();

    // Create a combined chronological history timeline
    final List<TimelineEvent> events = [];

    for (final ticket in assetTickets) {
      events.add(TimelineEvent(
        date: ticket.dateCreated,
        title: '${ticket.typeTextFrench} : ${ticket.title}',
        description: ticket.description,
        type: ticket.type == TicketType.anomaly
            ? TimelineEventType.incident
            : TimelineEventType.maintenance,
        statusLabel: ticket.statusTextFrench,
        color: ticket.status.resolveColor(context),
      ));
    }

    // Add generic historical events if list is empty
    if (events.isEmpty) {
      if (asset.lastMaintenance != null) {
        events.add(TimelineEvent(
          date: asset.lastMaintenance!,
          title: 'Dernière maintenance effectuée',
          description:
              'Maintenance préventive de routine approuvée et finalisée.',
          type: TimelineEventType.maintenance,
          statusLabel: 'Terminé',
          color: colors.success,
        ));
      }
      events.add(TimelineEvent(
        date: DateTime.now().subtract(const Duration(days: 60)),
        title: 'Mise en service de l\'équipement',
        description:
            'Installation initiale et configuration des paramètres de fonctionnement.',
        type: TimelineEventType.system,
        statusLabel: 'Actif',
        color: colors.success,
      ));
    }

    // Sort events by date descending
    events.sort((a, b) => b.date.compareTo(a.date));

    final dateFormat = DateFormat('dd MMMM yyyy HH:mm', 'fr_FR');
    final statusColor = asset.status.resolveColor(context);

    return AppPage(
      title: asset.name,
      subtitle: 'SN ${asset.serialNumber}  •  ID ${asset.id}',
      maxWidth: 800,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero card: category icon and current status
          AppPanel(
            padding: const EdgeInsets.all(18),
            color: statusColor.withValues(alpha: 0.07),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getCategoryIcon(asset.category),
                    size: 34,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.category,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppPill(
                        label: asset.statusTextFrench.toUpperCase(),
                        color: statusColor,
                        filled: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Technical specs
          if (asset.technicalSpecs != null &&
              asset.technicalSpecs!.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SectionTitle(
              title: 'Spécifications techniques',
              icon: Icons.memory_rounded,
            ),
            AppPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0;
                      index < asset.technicalSpecs!.length;
                      index++) ...[
                    if (index > 0) Divider(color: colors.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              asset.technicalSpecs!.entries
                                  .elementAt(index)
                                  .key,
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              asset.technicalSpecs!.entries
                                  .elementAt(index)
                                  .value,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 3. Maintenance dates
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  context,
                  'Dernière maintenance',
                  asset.lastMaintenance != null
                      ? DateFormat('dd/MM/yyyy').format(asset.lastMaintenance!)
                      : 'N/A',
                  Icons.settings_backup_restore_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTile(
                  context,
                  'Prochaine maintenance',
                  asset.nextMaintenance != null
                      ? DateFormat('dd/MM/yyyy').format(asset.nextMaintenance!)
                      : 'N/A',
                  Icons.event_rounded,
                ),
              ),
            ],
          ),

          // 4. Quick actions (glove-friendly, 56dp)
          const SizedBox(height: 22),
          const SectionTitle(
            title: 'Actions rapides',
            icon: Icons.bolt_rounded,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              final width =
                  isWide ? (constraints.maxWidth - 24) / 3 : double.infinity;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    context,
                    'Signaler un problème',
                    Icons.warning_amber_rounded,
                    colors.danger,
                    width: width,
                    onPressed: () {
                      context.push('/tickets/nouveau', extra: {
                        'prefilledAssetId': asset.id,
                        'prefilledAssetName': asset.name
                      });
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Créer maintenance',
                    Icons.build_outlined,
                    colors.info,
                    width: width,
                    onPressed: () {
                      context.push('/tickets/nouveau', extra: {
                        'prefilledAssetId': asset.id,
                        'prefilledAssetName': asset.name
                      });
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Modifier le statut',
                    Icons.sync_alt_rounded,
                    colors.warning,
                    width: width,
                    onPressed: () =>
                        _showStatusBottomSheet(context, ref, asset),
                  ),
                ],
              );
            },
          ),

          // 5. Chronological events timeline
          const SizedBox(height: 26),
          const SectionTitle(
            title: 'Historique de l\'équipement',
            icon: Icons.history_rounded,
          ),
          _buildTimelineList(context, events, dateFormat),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateTile(
      BuildContext context, String label, String value, IconData icon) {
    final colors = context.colors;
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    required double width,
    required VoidCallback onPressed,
  }) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          minimumSize: const Size(0, 56),
          backgroundColor: colors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('piscine') ||
        cat.contains('filtre') ||
        cat.contains('pompe')) {
      return Icons.pool;
    } else if (cat.contains('selle') ||
        cat.contains('box') ||
        cat.contains('stable') ||
        cat.contains('écurie')) {
      return Icons.pets;
    } else if (cat.contains('arme') ||
        cat.contains('pistolet') ||
        cat.contains('tir')) {
      return Icons.gps_fixed;
    } else if (cat.contains('gym') ||
        cat.contains('tapis') ||
        cat.contains('cardio')) {
      return Icons.fitness_center;
    } else if (cat.contains('padel') ||
        cat.contains('court') ||
        cat.contains('filet')) {
      return Icons.sports_tennis;
    }
    return Icons.build;
  }

  void _showStatusBottomSheet(
      BuildContext context, WidgetRef ref, Asset asset) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'Modifier le statut de l\'équipement',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Divider(color: colors.border, height: 1),
                _buildStatusSelectionRow(context, ref, asset,
                    AssetStatus.available, 'Disponible', colors.success),
                _buildStatusSelectionRow(context, ref, asset, AssetStatus.inUse,
                    'En utilisation', colors.info),
                _buildStatusSelectionRow(
                    context,
                    ref,
                    asset,
                    AssetStatus.maintenance,
                    'En maintenance',
                    colors.warning),
                _buildStatusSelectionRow(
                    context,
                    ref,
                    asset,
                    AssetStatus.broken,
                    'Hors service / En panne',
                    colors.danger),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSelectionRow(
    BuildContext context,
    WidgetRef ref,
    Asset asset,
    AssetStatus status,
    String label,
    Color color,
  ) {
    final colors = context.colors;
    final isSelected = asset.status == status;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? colors.textPrimary : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: colors.accentPrimary)
          : null,
      onTap: () {
        ref.read(assetsProvider.notifier).updateAssetStatus(asset.id, status);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de "${asset.name}" mis à jour : $label'),
            backgroundColor: color.withValues(alpha: 0.85),
          ),
        );
      },
    );
  }

  Widget _buildTimelineList(
      BuildContext context, List<TimelineEvent> events, DateFormat dateFormat) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < events.length; index++)
          _timelineRow(
            context,
            events[index],
            dateFormat,
            isLast: index == events.length - 1,
            colors: colors,
          ),
      ],
    );
  }

  Widget _timelineRow(
    BuildContext context,
    TimelineEvent ev,
    DateFormat dateFormat, {
    required bool isLast,
    required AppSemanticColors colors,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line & indicator
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: ev.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: ev.color, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(color: ev.color, shape: BoxShape.circle),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppPanel(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ev.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppPill(label: ev.statusLabel, color: ev.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(ev.date),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                    if (ev.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ev.description,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineEventType { incident, maintenance, system }

class TimelineEvent {
  final DateTime date;
  final String title;
  final String description;
  final TimelineEventType type;
  final String statusLabel;
  final Color color;

  TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.type,
    required this.statusLabel,
    required this.color,
  });
}
