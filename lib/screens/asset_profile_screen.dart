import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/work_ticket.dart';
import '../providers/assets_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';

class AssetProfileScreen extends ConsumerWidget {
  final String id;
  const AssetProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Équipement')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text(
                  'Équipement introuvable',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le code "$id" ne correspond à aucun équipement enregistré.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner à nouveau'),
                  onPressed: () => context.pushReplacement('/scan'),
                ),
              ],
            ),
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
        color: ticket.statusColor,
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
          color: AppColors.success,
        ));
      }
      events.add(TimelineEvent(
        date: DateTime.now().subtract(const Duration(days: 60)),
        title: 'Mise en service de l\'équipement',
        description:
            'Installation initiale et configuration des paramètres de fonctionnement.',
        type: TimelineEventType.system,
        statusLabel: 'Actif',
        color: AppColors.success,
      ));
    }

    // Sort events by date descending
    events.sort((a, b) => b.date.compareTo(a.date));

    final dateFormat = DateFormat('dd MMMM yyyy HH:mm', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche Équipement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Photo Card
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.surface,
                        AppColors.backgroundSecondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Center Placeholder icon or actual image
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(asset.category),
                              size: 56,
                              color: asset.statusColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              asset.category,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Pill
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: asset.statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: asset.statusColor, width: 1),
                          ),
                          child: Text(
                            asset.statusTextFrench.toUpperCase(),
                            style: TextStyle(
                              color: asset.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Asset Name & ID Strip
                Text(
                  asset.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${asset.serialNumber}  •  ID: ${asset.id}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Technical Specs Matrix
                if (asset.technicalSpecs != null &&
                    asset.technicalSpecs!.isNotEmpty) ...[
                  const Text(
                    'Spécifications Techniques',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: asset.technicalSpecs!.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final entry =
                            asset.technicalSpecs!.entries.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14)),
                              Text(entry.value,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. Maintenance Dates Strip
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTile(
                        context,
                        'Dernière Maintenance',
                        asset.lastMaintenance != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(asset.lastMaintenance!)
                            : 'N/A',
                        Icons.settings_backup_restore,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTile(
                        context,
                        'Prochaine Maintenance',
                        asset.nextMaintenance != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(asset.nextMaintenance!)
                            : 'N/A',
                        Icons.event,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Quick Actions Row (glove-friendly minimum touch bounds)
                const Text(
                  'Actions Rapides',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          context,
                          'Signaler Problème',
                          Icons.warning_amber_rounded,
                          AppColors.danger,
                          width: isWide
                              ? (constraints.maxWidth - 24) / 3
                              : double.infinity,
                          onPressed: () {
                            context.push('/tickets/nouveau', extra: {
                              'prefilledAssetId': asset.id,
                              'prefilledAssetName': asset.name
                            });
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Créer Maintenance',
                          Icons.build_outlined,
                          AppColors.info,
                          width: isWide
                              ? (constraints.maxWidth - 24) / 3
                              : double.infinity,
                          onPressed: () {
                            context.push('/tickets/nouveau', extra: {
                              'prefilledAssetId': asset.id,
                              'prefilledAssetName': asset.name
                            });
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Modifier Statut',
                          Icons.sync_alt,
                          AppColors.warning,
                          width: isWide
                              ? (constraints.maxWidth - 24) / 3
                              : double.infinity,
                          onPressed: () =>
                              _showStatusBottomSheet(context, ref, asset),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // 6. Chronological Events Timeline
                const Text(
                  'Historique de l\'équipement',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTimelineList(events, dateFormat),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
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
    return SizedBox(
      width: width,
      height: 52, // glove friendly minimum 48px touch bound
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundSecondary,
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Modifier le statut de l\'équipement',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                _buildStatusSelectionRow(context, ref, asset,
                    AssetStatus.available, 'Disponible', AppColors.success),
                _buildStatusSelectionRow(context, ref, asset, AssetStatus.inUse,
                    'En utilisation', AppColors.info),
                _buildStatusSelectionRow(
                    context,
                    ref,
                    asset,
                    AssetStatus.maintenance,
                    'En maintenance',
                    AppColors.warning),
                _buildStatusSelectionRow(
                    context,
                    ref,
                    asset,
                    AssetStatus.broken,
                    'Hors-service / En panne',
                    AppColors.danger),
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
    final isSelected = asset.status == status;
    return InkWell(
      onTap: () {
        ref.read(assetsProvider.notifier).updateAssetStatus(asset.id, status);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de "${asset.name}" mis à jour : $label'),
            backgroundColor: color.withValues(alpha: 0.8),
          ),
        );
      },
      child: Container(
        height: 52, // glove friendly minimum 48px
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.accentPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<TimelineEvent> events, DateFormat dateFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final isLast = index == events.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line & indicator
            Column(
              children: [
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
                      decoration: BoxDecoration(
                          color: ev.color, shape: BoxShape.circle),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ev.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ev.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ev.statusLabel,
                              style: TextStyle(
                                  color: ev.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(ev.date),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (ev.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ev.description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
