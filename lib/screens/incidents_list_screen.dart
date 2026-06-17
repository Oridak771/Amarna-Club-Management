import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/incident.dart';
import 'package:amarna_club/providers/incidents_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/app_filter_chip.dart';
import 'package:amarna_club/widgets/offline_banner.dart';
import 'package:amarna_club/widgets/priority_indicator.dart';

/// Écran liste des incidents avec filtres et indicateurs de priorité.
class IncidentsListScreen extends ConsumerStatefulWidget {
  const IncidentsListScreen({super.key});

  @override
  ConsumerState<IncidentsListScreen> createState() =>
      _IncidentsListScreenState();
}

class _IncidentsListScreenState extends ConsumerState<IncidentsListScreen> {
  String _selectedFilter = 'Tout';

  static const List<String> _filters = [
    'Tout',
    'Ouvert',
    'En cours',
    'Résolu',
    'Critique',
  ];

  /// Filters the incident list based on the currently selected chip.
  List<Incident> _applyFilter(List<Incident> incidents) {
    switch (_selectedFilter) {
      case 'Ouvert':
        return incidents
            .where((i) => i.status == IncidentStatus.open)
            .toList();
      case 'En cours':
        return incidents
            .where((i) => i.status == IncidentStatus.inProgress)
            .toList();
      case 'Résolu':
        return incidents
            .where((i) => i.status == IncidentStatus.resolved)
            .toList();
      case 'Critique':
        return incidents
            .where((i) => i.priority == IncidentPriority.critical)
            .toList();
      default:
        return incidents;
    }
  }

  /// Returns a human-readable French relative time string.
  String _relativeTime(DateTime dateCreated) {
    final diff = DateTime.now().difference(dateCreated);

    if (diff.inSeconds < 60) {
      return 'il y a quelques secondes';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'il y a $m minute${m > 1 ? 's' : ''}';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'il y a $h heure${h > 1 ? 's' : ''}';
    } else {
      final d = diff.inDays;
      return 'il y a $d jour${d > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents = ref.watch(incidentsProvider);
    final filteredIncidents = _applyFilter(allIncidents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: navigate to notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Offline banner ────────────────────────────────
          const OfflineBanner(),

          // ── Report button ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 22),
                label: const Text(
                  'Signaler un incident',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.push('/incidents/nouveau'),
              ),
            ),
          ),

          // ── Filter chips ──────────────────────────────────
          SizedBox(
            height: 48,
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

          const SizedBox(height: 8),

          // ── Incident list ─────────────────────────────────
          Expanded(
            child: filteredIncidents.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filteredIncidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];
                      return _buildIncidentCard(incident);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: AppColors.success.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun incident en cours — Tout va bien! 🌟',
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

  // ── Incident card ─────────────────────────────────────────
  Widget _buildIncidentCard(Incident incident) {
    return GestureDetector(
      onTap: () => context.push('/incidents/${incident.id}'),
      child: PriorityIndicator(
        priority: incident.priority,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: title + priority badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.title,
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
                  _buildPriorityBadge(incident),
                ],
              ),

              const SizedBox(height: 6),

              // Row 2: activity name • time ago
              Row(
                children: [
                  // Activity color dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.getActivityColor(incident.activityId),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    incident.activityName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(incident.dateCreated),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 3: technician + sync icon
              Row(
                children: [
                  if (incident.assignedTechnician != null) ...[
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.assignedTechnician!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Text(
                        'Non assigné',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Status badge
                  _buildStatusChip(incident),
                  // Sync pending indicator
                  if (incident.syncPending) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'En attente de synchronisation',
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: AppColors.warning.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Priority badge chip ───────────────────────────────────
  Widget _buildPriorityBadge(Incident incident) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: incident.priorityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incident.priorityColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        incident.priorityTextFrench,
        style: TextStyle(
          color: incident.priorityColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Status chip ───────────────────────────────────────────
  Widget _buildStatusChip(Incident incident) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: incident.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        incident.statusTextFrench,
        style: TextStyle(
          color: incident.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
