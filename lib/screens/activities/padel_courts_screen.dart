import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/asset.dart';
import '../../providers/assets_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';

/// Padel courts. They are equipment records in Odoo (Équipements), tagged with
/// the activity. A court is free when `available`, busy when `inUse` (Odoo
/// stamps the start of the session), and out of service otherwise.
class PadelCourtsScreen extends ConsumerWidget {
  const PadelCourtsScreen({super.key, required this.activityId});

  /// Activity code from the route (`/activites/:id/...`).
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courts = ref
        .watch(assetsProvider)
        .where((asset) => asset.activityId == activityId)
        .toList();
    final free = courts.where((c) => c.status == AssetStatus.available).length;

    return AppPage(
      title: 'Terrains de Padel',
      subtitle: '$free/${courts.length} terrains libres',
      onRefresh: ref.read(assetsProvider.notifier).refreshFromOdoo,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Réservations',
          icon: const Icon(Icons.calendar_month_rounded),
          onPressed: () => context.push('/planning'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (courts.isEmpty)
            const AppEmptyState(
              icon: Icons.sports_tennis_rounded,
              title: 'Aucun terrain enregistré',
              message:
                  'Ajoutez les terrains dans Odoo (Équipements Club) avec l\'activité du padel.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 800
                    ? 3
                    : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final court in courts)
                      SizedBox(width: width, child: _CourtCard(court: court)),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          ActivityReservationsPanel(activityId: activityId),
          const SizedBox(height: 20),
          ActivityTicketsPanel(activityId: activityId),
        ],
      ),
    );
  }
}

class _CourtCard extends ConsumerWidget {
  const _CourtCard({required this.court});

  final Asset court;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(assetsProvider.notifier);
    final free = court.status == AssetStatus.available;
    final busy = court.status == AssetStatus.inUse;

    final Color statusColor = free
        ? colors.success
        : busy
            ? colors.padel
            : colors.warning;
    final String statusLabel = free
        ? 'Disponible'
        : busy
            ? 'Occupé'
            : 'Maintenance';
    final since = court.inUseSince;

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: statusColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    court.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppPill(label: statusLabel, color: statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                if (busy) ...[
                  Icon(Icons.timer_outlined, color: colors.padel, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    since == null
                        ? 'Session en cours'
                        : 'En cours depuis ${DateTime.now().difference(since).inMinutes} min',
                    style: TextStyle(color: colors.textSecondary, fontSize: 15),
                  ),
                ] else if (free) ...[
                  Icon(Icons.check_circle_outline,
                      color: colors.success, size: 32),
                  const SizedBox(height: 8),
                  Text('Prêt pour une session',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 15)),
                ] else ...[
                  Icon(Icons.build, color: colors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Intervention nécessaire',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 15)),
                ],
                const SizedBox(height: 16),
                if (free)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.padel,
                        foregroundColor: colors.textOnAccent,
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: () => notifier.updateAssetStatus(
                          court.id, AssetStatus.inUse),
                      child: const Text('Démarrer Session'),
                    ),
                  )
                else if (busy)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: () => notifier.updateAssetStatus(
                          court.id, AssetStatus.available),
                      child: const Text('Terminer Session'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.warning,
                        side: BorderSide(
                            color: colors.warning.withValues(alpha: 0.6)),
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: () => notifier.updateAssetStatus(
                          court.id, AssetStatus.available),
                      icon: const Icon(Icons.build_circle_outlined),
                      label: const Text('Marquer Réparé'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
