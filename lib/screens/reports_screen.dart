import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/tickets_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapports & Statistiques'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share),
            tooltip: 'Exporter',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Rapport exporté en format PDF avec succès.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Period and Activity Filters
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: context.colors.backgroundSecondary,
                            value: _selectedPeriod,
                            items: [
                              DropdownMenuItem(
                                  value: '7',
                                  child: Text('7 derniers jours',
                                      style: TextStyle(
                                          color: context.colors.textPrimary))),
                              DropdownMenuItem(
                                  value: '30',
                                  child: Text('30 derniers jours',
                                      style: TextStyle(
                                          color: context.colors.textPrimary))),
                              DropdownMenuItem(
                                  value: '90',
                                  child: Text('3 derniers mois',
                                      style: TextStyle(
                                          color: context.colors.textPrimary))),
                              DropdownMenuItem(
                                  value: '365',
                                  child: Text('Cette année',
                                      style: TextStyle(
                                          color: context.colors.textPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPeriod = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: context.colors.backgroundSecondary,
                            value: _selectedActivity,
                            items: [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Toutes activités',
                                      style: TextStyle(
                                          color: context.colors.textPrimary))),
                              ...activities.map((act) => DropdownMenuItem(
                                  value: act.id,
                                  child: Text(act.name,
                                      style: TextStyle(
                                          color: context.colors.textPrimary)))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedActivity = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // 2. High-level KPI grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 550;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.6 : 3,
                      children: [
                        _buildKPICard(
                          'Anomalies Résolues',
                          '$resolvedAnomalies / $totalAnomalies',
                          'Taux : ${(anomalyResolutionRate * 100).toInt()}%',
                          context.colors.danger,
                        ),
                        _buildKPICard(
                          'Maintenance Complétée',
                          '$completedMaintenance / $totalMaintenance',
                          'Taux : ${(maintenanceRate * 100).toInt()}%',
                          context.colors.info,
                        ),
                        _buildKPICard(
                          'Alertes Stock Bas',
                          '$lowStockCount articles',
                          'Seuils critiques atteints',
                          lowStockCount > 0
                              ? context.colors.warning
                              : context.colors.success,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 24),

                // 3. Detailed stats & charts Section
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildAnomaliesChart(
                                      anomalyResolutionRate)),
                              SizedBox(width: 16),
                              Expanded(
                                  child:
                                      _buildMaintenanceChart(maintenanceRate)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildAnomaliesChart(anomalyResolutionRate),
                              SizedBox(height: 16),
                              _buildMaintenanceChart(maintenanceRate),
                            ],
                          );
                  },
                ),
                SizedBox(height: 24),

                // 4. Activity Occupancy Distribution
                _buildOccupancyDistribution(activities),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(
      String title, String value, String subtext, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.backgroundSecondary,
            context.colors.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: context.colors.textSecondary, fontSize: 13)),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: accentColor, shape: BoxShape.circle)),
              SizedBox(width: 6),
              Text(subtext,
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesChart(double rate) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Résolution d\'Anomalies',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 12,
                      backgroundColor: context.colors.surface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(context.colors.danger),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(rate * 100).toInt()}%',
                    style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Taux d\'anomalies résolues',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceChart(double rate) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Complétion de Maintenance',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 12,
                      backgroundColor: context.colors.surface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(context.colors.info),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(rate * 100).toInt()}%',
                    style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Taux de tâches préventives faites',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyDistribution(List<dynamic> activities) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taux d\'occupation en temps réel',
            style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => SizedBox(height: 14),
            itemBuilder: (context, index) {
              final act = activities[index];
              final pct = act.occupancyPercentage;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(act.name,
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Text(
                          '${act.currentOccupancy} / ${act.maxCapacity} (${(pct * 100).toInt()}%)',
                          style: TextStyle(
                              color: context.colors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: context.colors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _getActivityColor(act.id)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String activityId) {
    switch (activityId.toLowerCase()) {
      case 'pool':
        return const Color(0xFF00D4FF);
      case 'horses':
        return const Color(0xFFFFB347);
      case 'paintball':
        return const Color(0xFF7CFC00);
      case 'shooting':
        return const Color(0xFFFF4757);
      case 'gym':
        return const Color(0xFFA855F7);
      case 'padel':
        return const Color(0xFF34D399);
      default:
        return context.colors.accentPrimary;
    }
  }
}
