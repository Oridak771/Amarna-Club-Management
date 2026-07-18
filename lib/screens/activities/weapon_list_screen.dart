import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../models/work_ticket.dart';
import '../../providers/assets_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/priority_indicator.dart';

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
  /// Offline demo armory, shown only when no weapon asset is available
  /// from the synced asset cache (e.g. Odoo not configured).
  final List<Weapon> _demoWeapons = [
    Weapon(
        id: 'w1',
        serialNumber: 'SN-GLOCK-001',
        model: 'Glock 17',
        status: 'Disponible',
        lastCleaned: DateTime.now().subtract(const Duration(days: 1))),
    Weapon(
        id: 'w2',
        serialNumber: 'SN-GLOCK-002',
        model: 'Glock 17',
        status: 'En utilisation',
        lastCleaned: DateTime.now().subtract(const Duration(days: 5))),
    Weapon(
        id: 'w3',
        serialNumber: 'SN-AR15-001',
        model: 'AR-15',
        status: 'Maintenance',
        lastCleaned: DateTime.now().subtract(const Duration(days: 30))),
    Weapon(
        id: 'w4',
        serialNumber: 'SN-BERETTA-001',
        model: 'Beretta 92FS',
        status: 'Disponible',
        lastCleaned: DateTime.now().subtract(const Duration(days: 2))),
  ];

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
    setState(() {
      final demoIndex = _demoWeapons.indexWhere((w) => w.id == weapon.id);
      if (demoIndex != -1) {
        final w = _demoWeapons[demoIndex];
        _demoWeapons[demoIndex] = Weapon(
          id: w.id,
          serialNumber: w.serialNumber,
          model: w.model,
          status: w.status,
          lastCleaned: DateTime.now(),
        );
      }
    });
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
    weapons = weaponAssets.isNotEmpty
        ? weaponAssets.map(_weaponFromAsset).toList()
        : _demoWeapons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Armes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
            tooltip: 'Scanner une arme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildArmoryHeader(),
          const SizedBox(height: 14),
          for (var index = 0; index < weapons.length; index++) ...[
            _buildWeaponCard(index),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.shooting.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: colors.shooting.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_good_outlined, color: colors.shooting, size: 26),
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
                    fontSize: 14,
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
                    fontSize: 12.5,
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
    final weapon = weapons[index];

          Color statusColor;
          TicketPriority priority;
          if (weapon.status == 'Disponible') {
            statusColor = context.colors.success;
            priority = TicketPriority.low;
          } else if (weapon.status == 'En utilisation') {
            statusColor = context.colors.warning;
            priority = TicketPriority.medium;
          } else {
            statusColor = context.colors.danger;
            priority = TicketPriority.critical;
          }

          final bool needsCleaning =
              DateTime.now().difference(weapon.lastCleaned).inDays > 7;
          if (needsCleaning && priority == TicketPriority.low) {
            priority =
                TicketPriority.high; // bump priority if it needs cleaning
          }

          return PriorityIndicator(
            priority: priority,
            child: Card(
              color: context.colors.backgroundSecondary,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      weapon.serialNumber,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        weapon.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(weapon.model,
                        style: TextStyle(color: context.colors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.cleaning_services,
                          size: 14,
                          color: needsCleaning
                              ? context.colors.danger
                              : context.colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dernier nettoyage : ${DateFormat('dd/MM/yyyy').format(weapon.lastCleaned)}',
                          style: TextStyle(
                            color: needsCleaning
                                ? context.colors.danger
                                : context.colors.textSecondary,
                            fontSize: 12,
                            fontWeight: needsCleaning
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: context.colors.textSecondary),
                  color: context.colors.backgroundElevated,
                  onSelected: (value) {
                    if (value == 'clean') {
                      _cleanWeapon(index);
                    } else {
                      context.go('/tickets/nouveau');
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'clean',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services,
                              color: context.colors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text('Marquer nettoyé',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'maintain',
                      child: Row(
                        children: [
                          Icon(Icons.build, color: context.colors.warning, size: 20),
                          const SizedBox(width: 8),
                          Text('Créer Maintenance',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: context.colors.danger, size: 20),
                          const SizedBox(width: 8),
                          Text('Signaler Problème',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
