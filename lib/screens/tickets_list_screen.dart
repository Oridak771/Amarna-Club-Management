import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/offline_banner.dart';
import '../widgets/priority_indicator.dart';

/// Écran liste des tickets consolidés (Anomalies et Interventions de maintenance).
class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  String _selectedFilter = 'Tout';

  static const List<String> _filters = [
    'Tout',
    'Anomalies',
    'Maintenances',
    'En cours',
    'Résolus',
  ];

  List<WorkTicket> _applyFilter(List<WorkTicket> tickets) {
    switch (_selectedFilter) {
      case 'Anomalies':
        return tickets.where((t) => t.type == TicketType.anomaly).toList();
      case 'Maintenances':
        return tickets.where((t) => t.type == TicketType.preventive || t.type == TicketType.corrective).toList();
      case 'En cours':
        return tickets.where((t) => t.status == TicketStatus.inProgress).toList();
      case 'Résolus':
        return tickets.where((t) => t.status == TicketStatus.resolved).toList();
      default:
        return tickets;
    }
  }

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
    final allTickets = ref.watch(ticketsProvider);
    final filteredTickets = _applyFilter(allTickets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets d\'intervention'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const OfflineBanner(),

              // Create Ticket Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Créer un ticket',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.push('/tickets/nouveau'),
                  ),
                ),
              ),

              // Filter chips
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

              // Tickets list/grid
              Expanded(
                child: filteredTickets.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;
                          if (isWide) {
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.6,
                              ),
                              itemCount: filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = filteredTickets[index];
                                return _buildTicketCard(ticket);
                              },
                            );
                          } else {
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredTickets.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final ticket = filteredTickets[index];
                                return _buildTicketCard(ticket);
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              'Aucun ticket trouvé — Tout fonctionne! 🌟',
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

  Widget _buildTicketCard(WorkTicket ticket) {
    return GestureDetector(
      onTap: () => context.push('/tickets/${ticket.id}'),
      child: PriorityIndicator(
        priority: ticket.priority,
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
                      ticket.title,
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
                  _buildPriorityBadge(ticket),
                ],
              ),

              const SizedBox(height: 4),

              // Row 2: Type badge • Activity name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ticket.typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.typeTextFrench,
                      style: TextStyle(
                        color: ticket.typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.getActivityColor(ticket.activityId),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.activityName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 3: asset details or date info
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.assetName != null ? 'Équipement : ${ticket.assetName}' : 'Général',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _relativeTime(ticket.dateCreated),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 4: technician + status badge + sync icon
              Row(
                children: [
                  if (ticket.assignedTechnician != null) ...[
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.assignedTechnician!,
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
                  _buildStatusChip(ticket),
                  if (ticket.syncPending) ...[
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

  Widget _buildPriorityBadge(WorkTicket ticket) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ticket.priorityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ticket.priorityColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        ticket.priorityTextFrench,
        style: TextStyle(
          color: ticket.priorityColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkTicket ticket) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ticket.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ticket.statusTextFrench,
        style: TextStyle(
          color: ticket.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
