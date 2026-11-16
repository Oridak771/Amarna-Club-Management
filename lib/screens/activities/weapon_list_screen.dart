import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../models/work_ticket.dart';
import '../../providers/assets_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';

class Weapon {
  final String id;
  final String serialNumber;
  final String model;
  final String status; // 'Disponible', 'En utilisation', 'Maintenance'
  final DateTime lastCleaned;

  Weapon({
    required this.id,
    required this.serialNumber,
    required this.model,
    required this.status,
    required this.lastCleaned,
  });
}

class WeaponListScreen extends ConsumerStatefulWidget {
  const WeaponListScreen({super.key});

  @override
  ConsumerState<WeaponListScreen> createState() => _WeaponListScreenState();
}

class _WeaponListScreenState extends ConsumerState<WeaponListScreen> {
  List<Weapon> weapons = [];

  Weapon _weaponFromAsset(Asset asset) {
    return Weapon(
      id: asset.id,
      serialNumber: asset.serialNumber,
      model: asset.name,
      status: asset.statusTextFrench,
      lastCleaned: asset.lastMaintenance ??
          DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  void _cleanWeapon(int index) {
    final weapon = weapons[index];
    // Updates the local asset cache and pushes to Odoo.
    ref.read(assetsProvider.notifier).markAssetCleaned(weapon.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('Nettoyage enregistré'),
          backgroundColor: context.colors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final weaponAssets = assets
        .where((a) =>
            a.activityId == 'shooting' &&
            a.category.toLowerCase().contains('arme'))
        .toList();
    weapons = weaponAssets.map(_weaponFromAsset).toList();
    final available = weapons.where((w) => w.status == 'Disponible').length;

    return AppPage(
      title: 'Liste des Armes',
      subtitle: '$available/${weapons.length} disponibles',
      onRefresh: () => ref.read(assetsProvider.notifier).refreshFromOdoo(),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner une arme',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildArmoryHeader(),
          const SizedBox(height: 16),
          if (weapons.isEmpty)
            const AppEmptyState(
              icon: Icons.gpp_maybe_outlined,
              title: 'Aucune arme synchronisée',
              message: 'Tirez vers le bas pour actualiser depuis Odoo.',
            )
          else
            for (var index = 0; index < weapons.length; index++) ...[
              _buildWeaponCard(index),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          const ActivityTicketsPanel(activityId: 'shooting'),
        ],
      ),
    );
  }

  Widget _buildArmoryHeader() {
    final colors = context.colors;
    final available = weapons.where((w) => w.status == 'Disponible').length;
    final needCleaning = weapons
        .where((w) => DateTime.now().difference(w.lastCleaned).inDays > 7)
        .length;

    return AppPanel(
      color: colors.shooting.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.gpp_good_outlined, color: colors.shooting, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$available/${weapons.length} armes disponibles',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  needCleaning > 0
                      ? '$needCleaning arme${needCleaning > 1 ? 's' : ''} en attente de nettoyage (scan QR obligatoire)'
                      : 'Tous les nettoyages sont à jour.',
                  style: TextStyle(
                    color: needCleaning > 0
                        ? colors.danger
                        : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: needCleaning > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponCard(int index) {
    final colors = context.colors;
    final weapon = weapons[index];

    Color statusColor;
    TicketPriority priority;
    if (weapon.status == 'Disponible') {
      statusColor = colors.success;
      priority = TicketPriority.low;
    } else if (weapon.status == 'En utilisation') {
      statusColor = colors.warning;
      priority = TicketPriority.medium;
    } else {
      statusColor = colors.danger;
      priority = TicketPriority.critical;
    }

    final bool needsCleaning =
        DateTime.now().difference(weapon.lastCleaned).inDays > 7;
    if (needsCleaning && priority == TicketPriority.low) {
      priority = TicketPriority.high; // bump priority if it needs cleaning
    }

    return AppPanel(
        accentColor: _priorityColor(colors, priority),
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          weapon.serialNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppPill(label: weapon.status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weapon.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.cleaning_services,
                        size: 15,
                        color: needsCleaning ? colors.danger : colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Dernier nettoyage : ${DateFormat('dd/MM/yyyy').format(weapon.lastCleaned)}',
                          style: TextStyle(
                            color: needsCleaning
                                ? colors.danger
                                : colors.textSecondary,
                            fontSize: 13,
                            fontWeight: needsCleaning
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              padding: const EdgeInsets.all(12),
              icon: Icon(Icons.more_vert, color: colors.textSecondary),
              color: colors.backgroundElevated,
              onSelected: (value) {
                if (value == 'clean') {
                  _cleanWeapon(index);
                } else {
                  context.go('/tickets/nouveau');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'clean',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services,
                          color: colors.textPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text('Marquer nettoyé',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'maintain',
                  child: Row(
                    children: [
                      Icon(Icons.build, color: colors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('Créer Maintenance',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Signaler Problème',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Color _priorityColor(AppSemanticColors colors, TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return colors.priorityLow;
      case TicketPriority.medium:
        return colors.priorityMedium;
      case TicketPriority.high:
        return colors.priorityHigh;
      case TicketPriority.critical:
        return colors.priorityCritical;
    }
  }
}
