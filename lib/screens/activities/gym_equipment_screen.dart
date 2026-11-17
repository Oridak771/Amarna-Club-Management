import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/asset.dart';
import '../../providers/assets_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';

/// Machines of the gym. They are equipment records in Odoo (Équipements),
/// tagged with the activity: a machine is "out of order" when its status is
/// `broken`, and "cleaned today" when its last maintenance date is today.
class GymEquipmentScreen extends ConsumerWidget {
  const GymEquipmentScreen({super.key, required this.activityId});

  /// Activity code from the route (`/activites/:id/...`).
  final String activityId;

  static bool _isBroken(Asset machine) => machine.status == AssetStatus.broken;

  static bool _isCleanedToday(Asset machine) {
    final last = machine.lastMaintenance;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final machines = ref
        .watch(assetsProvider)
        .where((asset) => asset.activityId == activityId)
        .toList();
    final notifier = ref.read(assetsProvider.notifier);

    Future<void> markAllCleaned() async {
      for (final machine in machines) {
        if (!_isBroken(machine) && !_isCleanedToday(machine)) {
          await notifier.markAssetCleaned(machine.id);
        }
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text(
                'Toutes les machines fonctionnelles marquées comme nettoyées'),
            backgroundColor: colors.success),
      );
    }

    return AppPage(
      title: 'Équipement Gym',
      subtitle: 'Nettoyage et pannes du jour',
      onRefresh: notifier.refreshFromOdoo,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      bottomBar: machines.isEmpty
          ? null
          : FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: colors.success,
                foregroundColor: colors.textOnAccent,
              ),
              onPressed: markAllCleaned,
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Tout marquer nettoyé'),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (machines.isEmpty)
            const AppEmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'Aucune machine enregistrée',
              message:
                  'Ajoutez les machines dans Odoo (Équipements Club) avec l\'activité de la salle.',
            )
          else ...[
            _CleaningHeader(machines: machines),
            const SizedBox(height: 16),
            for (final machine in machines) ...[
              _MachineCard(
                machine: machine,
                cleaned: _isCleanedToday(machine),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 14),
          ActivityTicketsPanel(activityId: activityId),
        ],
      ),
    );
  }
}

class _CleaningHeader extends StatelessWidget {
  const _CleaningHeader({required this.machines});

  final List<Asset> machines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final working = machines.where((m) => !GymEquipmentScreen._isBroken(m)).toList();
    final total = working.length;
    final cleaned = working.where(GymEquipmentScreen._isCleanedToday).length;
    final brokenCount = machines.length - total;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nettoyage du jour : $cleaned/$total machines',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (brokenCount > 0)
                AppPill(
                  label: '$brokenCount HS',
                  color: colors.danger,
                  icon: Icons.build_circle_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? cleaned / total : 0,
              minHeight: 8,
              backgroundColor: colors.surfaceHover,
              valueColor: AlwaysStoppedAnimation(
                cleaned == total ? colors.success : colors.gym,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineCard extends ConsumerWidget {
  const _MachineCard({required this.machine, required this.cleaned});

  final Asset machine;
  final bool cleaned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final broken = GymEquipmentScreen._isBroken(machine);
    final notifier = ref.read(assetsProvider.notifier);

    return AppPanel(
      accentColor: broken ? colors.danger : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        machine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: broken ? colors.textSecondary : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: broken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (broken) ...[
                      const SizedBox(width: 8),
                      AppPill(label: 'HS', color: colors.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  machine.category,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!broken) ...[
            Icon(
              cleaned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: cleaned ? colors.success : colors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text('Nettoyé',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            // A cleaning is recorded once; the switch only turns it on.
            Switch(
              value: cleaned,
              onChanged: cleaned
                  ? null
                  : (_) => notifier.markAssetCleaned(machine.id),
              activeThumbColor: colors.success,
            ),
          ] else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => context.go('/tickets/nouveau'),
              icon: Icon(Icons.build, size: 18, color: colors.warning),
              label: const Text('Réparer'),
            ),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            padding: const EdgeInsets.all(12),
            icon: Icon(Icons.more_vert, color: colors.textSecondary),
            color: colors.backgroundElevated,
            onSelected: (value) {
              if (value == 'report') {
                notifier.updateAssetStatus(machine.id, AssetStatus.broken);
                context.go('/tickets/nouveau');
              } else if (value == 'resolve') {
                notifier.updateAssetStatus(machine.id, AssetStatus.available);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (!broken)
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Signaler Panne',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                )
              else
                PopupMenuItem<String>(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: colors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('Marquer Fonctionnel',
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
}
