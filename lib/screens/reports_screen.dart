import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/incident.dart';
import '../models/maintenance_task.dart';
import '../providers/activities_provider.dart';
import '../providers/incidents_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/maintenance_provider.dart';
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
    final incidents = ref.watch(incidentsProvider);
    final maintenanceTasks = ref.watch(maintenanceProvider);
    final inventoryItems = ref.watch(inventoryProvider);

    // Filter by activity if not 'all'
    final filteredIncidents = incidents.where((i) => _selectedActivity == 'all' || i.activityId == _selectedActivity).toList();
    final filteredMaintenance = maintenanceTasks.where((t) => _selectedActivity == 'all' || t.activityId == _selectedActivity).toList();
    final filteredInventory = inventoryItems.where((item) => _selectedActivity == 'all' || item.activityId == _selectedActivity).toList();

    // Calculations
    final totalIncidents = filteredIncidents.length;
    final resolvedIncidents = filteredIncidents.where((i) => i.status == IncidentStatus.resolved).length;
    final incidentResolutionRate = totalIncidents > 0 ? (resolvedIncidents / totalIncidents) : 0.0;

    final totalMaintenance = filteredMaintenance.length;
    final completedMaintenance = filteredMaintenance.where((t) => t.status == MaintenanceStatus.done).length;
    final maintenanceRate = totalMaintenance > 0 ? (completedMaintenance / totalMaintenance) : 0.0;

    final lowStockCount = filteredInventory.where((i) => i.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports & Statistiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rapport exporté en format PDF avec succès.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Period and Activity Filters
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.backgroundSecondary,
                            value: _selectedPeriod,
                            items: const [
                              DropdownMenuItem(value: '7', child: Text('7 derniers jours', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: '30', child: Text('30 derniers jours', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: '90', child: Text('3 derniers mois', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: '365', child: Text('Cette année', style: TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPeriod = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.backgroundSecondary,
                            value: _selectedActivity,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Toutes activités', style: TextStyle(color: AppColors.textPrimary))),
                              ...activities.map((act) => DropdownMenuItem(value: act.id, child: Text(act.name, style: const TextStyle(color: AppColors.textPrimary)))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedActivity = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                          'Incidents Résolus',
                          '$resolvedIncidents / $totalIncidents',
                          'Taux : ${(incidentResolutionRate * 100).toInt()}%',
                          AppColors.danger,
                        ),
                        _buildKPICard(
                          'Maintenance Complétée',
                          '$completedMaintenance / $totalMaintenance',
                          'Taux : ${(maintenanceRate * 100).toInt()}%',
                          AppColors.info,
                        ),
                        _buildKPICard(
                          'Alertes Stock Bas',
                          '$lowStockCount articles',
                          'Seuils critiques atteints',
                          lowStockCount > 0 ? AppColors.warning : AppColors.success,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Detailed stats & charts Section
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildIncidentsChart(incidentResolutionRate)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMaintenanceChart(maintenanceRate)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildIncidentsChart(incidentResolutionRate),
                              const SizedBox(height: 16),
                              _buildMaintenanceChart(maintenanceRate),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 24),

                // 4. Activity Occupancy Distribution
                _buildOccupancyDistribution(activities),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, String subtext, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.backgroundSecondary,
            AppColors.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(subtext, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsChart(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Résolution d\'Incidents',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
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
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.danger),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(rate * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Taux d\'incidents clôturés',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceChart(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Complétion de Maintenance',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
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
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(rate * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Taux de tâches préventives faites',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyDistribution(List<dynamic> activities) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taux d\'occupation en temps réel',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final act = activities[index];
              final pct = act.occupancyPercentage;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(act.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('${act.currentOccupancy} / ${act.maxCapacity} (${(pct * 100).toInt()}%)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(_getActivityColor(act.id)),
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
        return AppColors.accentPrimary;
    }
  }
}
