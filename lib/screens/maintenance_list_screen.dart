import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:amarna_club/models/maintenance_task.dart';
import 'package:amarna_club/providers/maintenance_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/app_filter_chip.dart';
import 'package:amarna_club/widgets/offline_banner.dart';
import 'package:amarna_club/widgets/priority_indicator.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  String _selectedFilter = 'Tout';

  static const List<String> _filters = [
    'Tout',
    'Préventif',
    'Correctif',
    'En retard',
  ];

  List<MaintenanceTask> _applyFilter(List<MaintenanceTask> tasks) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Préventif':
        return tasks
            .where((t) => t.type == MaintenanceType.preventive)
            .toList();
      case 'Correctif':
        return tasks
            .where((t) => t.type == MaintenanceType.corrective)
            .toList();
      case 'En retard':
        return tasks
            .where((t) =>
                t.status != MaintenanceStatus.done && t.dateDue.isBefore(now))
            .toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(maintenanceProvider);
    final filteredTasks = _applyFilter(tasks);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR/NFC',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: navigate to notification center
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Filter chips
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _filters[index];
                return AppFilterChip(
                  label: label,
                  isSelected: _selectedFilter == label,
                  onTap: () => setState(() => _selectedFilter = label),
                );
              },
            ),
          ),

          // Task list
          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isOverdue = task.status != MaintenanceStatus.done &&
                          task.dateDue.isBefore(now);

                      return GestureDetector(
                        onTap: () => context.push('/maintenance/${task.id}'),
                        child: PriorityIndicator(
                          priority: task.priority,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Type badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTypeBadge(task.type),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Asset name
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.layers_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task.assetName,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Due date & Assignee & Status badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Date
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 14,
                                          color: isOverdue
                                              ? AppColors.danger
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(task.dateDue),
                                          style: TextStyle(
                                            color: isOverdue
                                                ? AppColors.danger
                                                : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: isOverdue
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'RETARD',
                                              style: TextStyle(
                                                color: AppColors.danger,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Assignee
                                    if (task.assignedTechnician != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.assignedTechnician!.split(
                                                ' ')[0], // First name only
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: task.statusColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        task.statusTextFrench,
                                        style: TextStyle(
                                          color: task.statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.textOnAccent,
        onPressed: () => context.push('/maintenance/nouveau'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_suggest_outlined,
              size: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune maintenance en attente — Tout fonctionne! ⚙️',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(MaintenanceType type) {
    final label =
        type == MaintenanceType.preventive ? 'Préventif' : 'Correctif';
    final color = type == MaintenanceType.preventive
        ? AppColors.info
        : AppColors.accentSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
