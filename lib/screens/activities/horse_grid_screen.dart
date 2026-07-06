import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_filter_chip.dart';

class HorseGridScreen extends ConsumerStatefulWidget {
  const HorseGridScreen({super.key});

  @override
  ConsumerState<HorseGridScreen> createState() => _HorseGridScreenState();
}

class _HorseGridScreenState extends ConsumerState<HorseGridScreen> {
  HorseStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allHorses = ref.watch(horsesProvider);
    final horses = _filter == null
        ? allHorses
        : allHorses.where((h) => h.status == _filter).toList();

    final availableCount =
        allHorses.where((h) => h.status == HorseStatus.available).length;
    final careAlerts = allHorses
        .where((h) => h.farrierDue || h.dewormingDue || h.vetNote != null)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écurie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stable summary
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.bedroom_baby_outlined,
                      color: colors.horses,
                      value: '$availableCount/${allHorses.length}',
                      label: 'Disponibles pour la monte',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
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
              const SizedBox(height: 14),

              // Status filters
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppFilterChip(
                      label: 'Tous',
                      isSelected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final status in HorseStatus.values) ...[
                      AppFilterChip(
                        label: status.labelFrench,
                        isSelected: _filter == status,
                        onTap: () => setState(
                            () => _filter = _filter == status ? null : status),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800
                      ? 4
                      : (constraints.maxWidth > 600 ? 3 : 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: horses.length,
                    itemBuilder: (context, index) =>
                        _HorseCard(horse: horses[index]),
                  );
                },
              ),
              const SizedBox(height: 24),

              const ActivityReservationsPanel(
                activityId: 'horses',
                activityName: 'Équitation',
              ),
              const SizedBox(height: 20),
              const ActivityTicketsPanel(activityId: 'horses'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorseCard extends ConsumerWidget {
  const _HorseCard({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final statusColor = switch (horse.status) {
      HorseStatus.available => colors.success,
      HorseStatus.resting => colors.warning,
      HorseStatus.injured => colors.danger,
    };
    final needsCare = horse.farrierDue || horse.dewormingDue;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/activites/horses/horses/${horse.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: statusColor.withValues(alpha: 0.08),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.bedroom_baby_outlined,
                          size: 44,
                          color: statusColor.withValues(alpha: 0.6)),
                    ),
                    if (needsCare)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tooltip(
                          message: horse.farrierDue
                              ? 'Maréchal-ferrant à prévoir'
                              : 'Vermifuge à prévoir',
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.healing_outlined,
                                size: 14, color: colors.warning),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${horse.breed} · ${horse.age} ans · ${horse.boxNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        horse.status.labelFrench,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (horse.nextVetVisit != null) ...[
                      Row(
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 11, color: colors.info),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Véto : ${DateFormat('dd/MM HH:mm').format(horse.nextVetVisit!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: colors.info, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text('Fatigue',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 10)),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: horse.fatigue,
                        backgroundColor: colors.surfaceHover,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          horse.fatigue > 0.7 ? colors.danger : colors.horses,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
