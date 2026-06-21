import 'package:amarna_club/ui/ticket_ui_adapter.dart';
import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/priority_indicator.dart';

/// Ecran liste des tickets consolidés (Anomalies et Interventions de maintenance).
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
    'Resolus',
  ];

  List<WorkTicket> _applyFilter(List<WorkTicket> tickets) {
    switch (_selectedFilter) {
      case 'Anomalies':
        return tickets.where((t) => t.type == TicketType.anomaly).toList();
      case 'Maintenances':
        return tickets
            .where((t) =>
                t.type == TicketType.preventive ||
                t.type == TicketType.corrective)
            .toList();
      case 'En cours':
        return tickets
            .where((t) => t.status == TicketStatus.inProgress)
            .toList();
      case 'Resolus':
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
        title: Text('Tickets d\'intervention'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Create Ticket Button
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.add_circle_outline, size: 22),
                    label: Text(
                      'Creer un ticket',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.push('/tickets/nouveau'),
                  ),
                ),
              ),

              // Filter chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
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

              SizedBox(height: 8),

              // Tickets list/grid
              Expanded(
                child: filteredTickets.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;
                          if (isWide) {
                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: filteredTickets.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 12),
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
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: context.colors.success.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              'Aucun ticket trouve - tout fonctionne.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: title + priority badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildPriorityBadge(ticket),
                ],
              ),

              SizedBox(height: 4),

              // Row 2: Type badge • Activity name
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ticket.type.resolveColor(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.typeTextFrench,
                      style: TextStyle(
                        color: ticket.type.resolveColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: resolveActivityColor(context, ticket.activityId),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    ticket.activityName,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 6),

              // Row 3: asset details or date info
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.assetName != null
                          ? 'Equipement : ${ticket.assetName}'
                          : 'General',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _relativeTime(ticket.dateCreated),
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 6),

              // Row 4: technician + status badge + sync icon
              Row(
                children: [
                  if (ticket.assignedTechnician != null) ...[
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: context.colors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.assignedTechnician!,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        'Non assigne',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  _buildStatusChip(ticket),
                  if (ticket.syncPending) ...[
                    SizedBox(width: 8),
                    Tooltip(
                      message: 'En attente de synchronisation',
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: context.colors.warning.withValues(alpha: 0.8),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ticket.priority.resolveColor(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ticket.priority.resolveColor(context).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        ticket.priorityTextFrench,
        style: TextStyle(
          color: ticket.priority.resolveColor(context),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkTicket ticket) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ticket.status.resolveColor(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ticket.statusTextFrench,
        style: TextStyle(
          color: ticket.status.resolveColor(context),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
