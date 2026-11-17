import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/club_config.dart';
import '../../providers/club_config_provider.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_filter_chip.dart';
import '../../widgets/app_layout.dart';

/// « Écurie » — every horse with availability, care alerts and fatigue.
class HorseGridScreen extends ConsumerStatefulWidget {
  const HorseGridScreen({super.key, required this.activityId});

  /// Activity code from the route (`/activites/:id/...`).
  final String activityId;


  @override
  ConsumerState<HorseGridScreen> createState() => _HorseGridScreenState();
}

class _HorseGridScreenState extends ConsumerState<HorseGridScreen> {
  HorseStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allHorses = ref.watch(horsesProvider);
    final rules = ref.watch(clubConfigProvider).requireValue.horses;
    final horses = _filter == null
        ? allHorses
        : allHorses.where((h) => h.status == _filter).toList();

    final availableCount =
        allHorses.where((h) => h.status == HorseStatus.available).length;
    final careAlerts = allHorses
        .where((h) => h.farrierDue(rules) || h.dewormingDue(rules) || h.vetNote != null)
        .length;

    return AppPage(
      title: 'Écurie',
      subtitle: '$availableCount/${allHorses.length} disponibles',
      onRefresh: () => ref.read(horsesProvider.notifier).refreshFromOdoo(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stable summary
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  icon: Icons.bedroom_baby_outlined,
                  color: colors.horses,
                  value: '$availableCount/${allHorses.length}',
                  label: 'Disponibles pour la monte',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatTile(
                  icon: Icons.medical_services_outlined,
                  color: careAlerts > 0 ? colors.warning : colors.success,
                  value: '$careAlerts',
                  label: careAlerts > 0
                      ? 'Soins à prévoir'
                      : 'Aucun soin en attente',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status filters
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppFilterChip(
                  label: 'Tous',
                  count: allHorses.length,
                  isSelected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final status in HorseStatus.values) ...[
                  AppFilterChip(
                    label: status.labelFrench,
                    count: allHorses.where((h) => h.status == status).length,
                    isSelected: _filter == status,
                    onTap: () => setState(
                        () => _filter = _filter == status ? null : status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (allHorses.isEmpty)
            const AppEmptyState(
              icon: Icons.bedroom_baby_outlined,
              title: 'Aucun cheval synchronisé',
              message: 'Tirez vers le bas pour actualiser depuis Odoo.',
            )
          else if (horses.isEmpty)
            const AppEmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'Aucun cheval dans ce filtre',
              message: 'Changez de filtre pour voir les autres chevaux.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 860
                    ? 4
                    : constraints.maxWidth >= 560
                        ? 3
                        : 2;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final horse in horses)
                      SizedBox(
                        width: width,
                        child: _HorseCard(horse: horse, rules: rules),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),

          ActivityReservationsPanel(
            activityId: widget.activityId,
          ),
          const SizedBox(height: 20),
          ActivityTicketsPanel(activityId: widget.activityId),
        ],
      ),
    );
  }
}

class _HorseCard extends StatelessWidget {
  const _HorseCard({required this.horse, required this.rules});

  final Horse horse;
  final HorseRules rules;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (horse.status) {
      HorseStatus.available => colors.success,
      HorseStatus.resting => colors.warning,
      HorseStatus.injured => colors.danger,
    };
    final needsCare = horse.farrierDue(rules) || horse.dewormingDue(rules);

    return AppPanel(
      onTap: () => context.push('/activites/horses/horses/${horse.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 96,
            color: statusColor.withValues(alpha: 0.08),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.bedroom_baby_outlined,
                      size: 44, color: statusColor.withValues(alpha: 0.6)),
                ),
                if (needsCare)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: horse.farrierDue(rules)
                          ? 'Maréchal-ferrant à prévoir'
                          : 'Vermifuge à prévoir',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.healing_outlined,
                            size: 16, color: colors.warning),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horse.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${horse.breed} · ${horse.age} ans · ${horse.boxNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                AppPill(label: horse.status.labelFrench, color: statusColor),
                const SizedBox(height: 10),
                if (horse.nextVetVisit != null) ...[
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 14, color: colors.info),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Véto : ${DateFormat('dd/MM HH:mm').format(horse.nextVetVisit!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.info, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text('Fatigue',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: horse.fatigue,
                    backgroundColor: colors.surfaceHover,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      horse.fatigue > rules.fatigueAlert ? colors.danger : colors.horses,
                    ),
                    minHeight: 6,
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
