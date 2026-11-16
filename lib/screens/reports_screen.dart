import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/tickets_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

/// « Rapports » — anomaly and maintenance rates, stock alerts and occupancy.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = '30'; // days
  String _selectedActivity = 'all';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activities = ref.watch(activitiesProvider);
    final tickets = ref.watch(ticketsProvider);
    final inventoryItems = ref.watch(inventoryProvider);

    // Filter by activity if not 'all'
    final filteredTickets = tickets
        .where((t) =>
            _selectedActivity == 'all' || t.activityId == _selectedActivity)
        .toList();
    final filteredInventory = inventoryItems
        .where((item) =>
            _selectedActivity == 'all' || item.activityId == _selectedActivity)
        .toList();

    // Separate calculations for anomalies (incidents) and planned maintenances
    final anomalies =
        filteredTickets.where((t) => t.type == TicketType.anomaly).toList();
    final totalAnomalies = anomalies.length;
    final resolvedAnomalies =
        anomalies.where((a) => a.status == TicketStatus.resolved).length;
    final anomalyResolutionRate =
        totalAnomalies > 0 ? (resolvedAnomalies / totalAnomalies) : 0.0;

    final maintenances =
        filteredTickets.where((t) => t.type != TicketType.anomaly).toList();
    final totalMaintenance = maintenances.length;
    final completedMaintenance =
        maintenances.where((m) => m.status == TicketStatus.resolved).length;
    final maintenanceRate =
        totalMaintenance > 0 ? (completedMaintenance / totalMaintenance) : 0.0;

    final lowStockCount = filteredInventory.where((i) => i.isLowStock).length;

    return AppPage(
      title: 'Rapports',
      subtitle: 'Anomalies, maintenance et stocks',
      actions: [
        IconButton.filledTonal(
          tooltip: 'Exporter',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Rapport exporté en format PDF avec succès.')),
            );
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Period and activity filters
          LayoutBuilder(
            builder: (context, constraints) {
              final periodField = _filterField(
                colors,
                DropdownButton<String>(
                  dropdownColor: colors.backgroundSecondary,
                  isExpanded: true,
                  value: _selectedPeriod,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('7 derniers jours')),
                    DropdownMenuItem(
                        value: '30', child: Text('30 derniers jours')),
                    DropdownMenuItem(
                        value: '90', child: Text('3 derniers mois')),
                    DropdownMenuItem(value: '365', child: Text('Cette année')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPeriod = val);
                    }
                  },
                ),
              );
              final activityField = _filterField(
                colors,
                DropdownButton<String>(
                  dropdownColor: colors.backgroundSecondary,
                  isExpanded: true,
                  value: _selectedActivity,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('Toutes les activités')),
                    ...activities.map((act) => DropdownMenuItem(
                        value: act.id, child: Text(act.name))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedActivity = val);
                    }
                  },
                ),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    periodField,
                    const SizedBox(height: 10),
                    activityField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: periodField),
                  const SizedBox(width: 12),
                  Expanded(child: activityField),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 2. High-level KPI tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                AppStatTile(
                  label: 'Anomalies résolues',
                  value: '$resolvedAnomalies / $totalAnomalies',
                  caption: 'Taux : ${(anomalyResolutionRate * 100).toInt()}%',
                  icon: Icons.report_problem_outlined,
                  color: colors.danger,
                ),
                AppStatTile(
                  label: 'Maintenance complétée',
                  value: '$completedMaintenance / $totalMaintenance',
                  caption: 'Taux : ${(maintenanceRate * 100).toInt()}%',
                  icon: Icons.build_outlined,
                  color: colors.info,
                ),
                AppStatTile(
                  label: 'Alertes stock bas',
                  value: '$lowStockCount',
                  caption: lowStockCount > 0
                      ? 'Articles sous le seuil critique'
                      : 'Aucune alerte',
                  icon: Icons.inventory_2_outlined,
                  color: lowStockCount > 0 ? colors.warning : colors.success,
                ),
              ];
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 3. Rates
          LayoutBuilder(
            builder: (context, constraints) {
              final anomaliesChart =
                  _buildRateChart('Résolution d\'anomalies', anomalyResolutionRate,
                      colors.danger, 'Taux d\'anomalies résolues');
              final maintenanceChart = _buildRateChart(
                  'Complétion de maintenance',
                  maintenanceRate,
                  colors.info,
                  'Taux de tâches préventives faites');
              if (constraints.maxWidth < 650) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    anomaliesChart,
                    const SizedBox(height: 12),
                    maintenanceChart,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: anomaliesChart),
                    const SizedBox(width: 12),
                    Expanded(child: maintenanceChart),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 4. Activity occupancy distribution
          _buildOccupancyDistribution(activities),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _filterField(AppSemanticColors colors, Widget dropdown) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(child: dropdown),
    );
  }

  Widget _buildRateChart(
      String title, double rate, Color color, String caption) {
    final colors = context.colors;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 104,
                      width: 104,
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 12,
                        backgroundColor: colors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(rate * 100).toInt()}%',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyDistribution(List<Activity> activities) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'Taux d\'occupation en temps réel',
          icon: Icons.groups_2_outlined,
        ),
        AppPanel(
          child: activities.isEmpty
              ? Text(
                  'Aucune activité synchronisée pour le moment.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < activities.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _occupancyRow(activities[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _occupancyRow(Activity act) {
    final colors = context.colors;
    final pct = act.occupancyPercentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                act.name,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${act.currentOccupancy} / ${act.maxCapacity} (${(pct * 100).toInt()}%)',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: colors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(_getActivityColor(act.id)),
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String activityId) {
    return context.colors.getActivityColor(activityId);
  }
}
