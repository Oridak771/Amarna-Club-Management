import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_indicator.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String id;
  TicketDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final ticket = tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => WorkTicket(
        id: id,
        title: 'Ticket inconnu',
        description: 'Aucune description disponible.',
        activityId: '',
        activityName: 'Inconnu',
        type: TicketType.anomaly,
        priority: TicketPriority.low,
        status: TicketStatus.open,
        dateCreated: DateTime.now(),
      ),
    );

    final String createdDateStr =
        DateFormat('dd/MM/yyyy à HH:mm').format(ticket.dateCreated);
    final String? dueDateStr = ticket.dateDue != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(ticket.dateDue!)
        : null;
    final bool isOverdue = ticket.status != TicketStatus.resolved &&
        ticket.dateDue != null &&
        ticket.dateDue!.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.type == TicketType.anomaly
            ? 'Détail Anomalie'
            : 'Détail Maintenance'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator & title card
                  PriorityIndicator(
                    priority: ticket.priority,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTypeBadge(context, ticket),
                              _buildStatusBadge(context, ticket),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            ticket.title,
                            style: TextStyle(
                              color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Activité : ${ticket.activityName}',
                            style: TextStyle(
                              color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (ticket.assetName != null) ...[
                            SizedBox(height: 4),
                            Text(
                              'Équipement : ${ticket.assetName}',
                              style: TextStyle(
                                color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Detail section
                  Text(
                    'Détails du ticket',
                    style: TextStyle(
                        color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).extension<AppSemanticColors>()!.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                              color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Text(
                          ticket.description.isNotEmpty
                              ? ticket.description
                              : 'Aucune description fournie.',
                          style: TextStyle(
                              color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                              fontSize: 14,
                              height: 1.4),
                        ),
                        Divider(height: 24, color: Theme.of(context).extension<AppSemanticColors>()!.border),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date de création',
                                    style: TextStyle(
                                        color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                        fontSize: 12),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 14,
                                          color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary),
                                      SizedBox(width: 6),
                                      Text(
                                        createdDateStr,
                                        style: TextStyle(
                                            color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (dueDateStr != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Échéance',
                                      style: TextStyle(
                                        color: isOverdue
                                            ? Theme.of(context).extension<AppSemanticColors>()!.danger
                                            : Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_alarm,
                                          size: 14,
                                          color: isOverdue
                                              ? Theme.of(context).extension<AppSemanticColors>()!.danger
                                              : Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          dueDateStr,
                                          style: TextStyle(
                                            color: isOverdue
                                                ? Theme.of(context).extension<AppSemanticColors>()!.danger
                                                : Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                                            fontSize: 13,
                                            fontWeight: isOverdue
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Divider(height: 24, color: Theme.of(context).extension<AppSemanticColors>()!.border),
                        Text(
                          'Technicien assigné',
                          style: TextStyle(
                              color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 16, color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              ticket.assignedTechnician ?? 'Non assigné',
                              style: TextStyle(
                                color: ticket.assignedTechnician != null
                                    ? Theme.of(context).extension<AppSemanticColors>()!.textPrimary
                                    : Theme.of(context).extension<AppSemanticColors>()!.textMuted,
                                fontSize: 14,
                                fontStyle: ticket.assignedTechnician != null
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Media attachments (photos / voice)
                  if (ticket.imageUrl != null ||
                      ticket.voiceNoteUrl != null) ...[
                    Text(
                      'Pièces jointes',
                      style: TextStyle(
                          color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).extension<AppSemanticColors>()!.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ticket.imageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/placeholder_pool.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                          if (ticket.voiceNoteUrl != null)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).extension<AppSemanticColors>()!.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_circle_outline,
                                        color: Theme.of(context).extension<AppSemanticColors>()!.success, size: 32),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Lecture de la note vocale...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Note vocale.mp3',
                                            style: TextStyle(
                                                color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                                                fontSize: 13)),
                                        SizedBox(height: 4),
                                        Text('Durée : 0:14',
                                            style: TextStyle(
                                                color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Action Buttons based on status
                  if (ticket.status != TicketStatus.resolved) ...[
                    Row(
                      children: [
                        if (ticket.status == TicketStatus.open)
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.warning,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.play_arrow),
                                label: Text('Prendre en charge',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ref
                                      .read(ticketsProvider.notifier)
                                      .updateTicketStatus(
                                          ticket.id, TicketStatus.inProgress);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Ticket pris en charge (En cours) ✓')),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (ticket.status == TicketStatus.inProgress) ...[
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.check),
                                label: Text(
                                    ticket.type == TicketType.anomaly
                                        ? 'Résoudre'
                                        : 'Terminer',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ref
                                      .read(ticketsProvider.notifier)
                                      .updateTicketStatus(
                                          ticket.id, TicketStatus.resolved);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Ticket résolu avec succès ✓')),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 24),
                  ],

                  // Event Log Timeline (Odoo style)
                  Text(
                    'Historique d\'intervention',
                    style: TextStyle(
                        color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _buildTimeline(context, ticket),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, WorkTicket ticket) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ticket.type.resolveColor(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ticket.typeTextFrench,
        style: TextStyle(
          color: ticket.type.resolveColor(context),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, WorkTicket ticket) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ticket.status.resolveColor(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ticket.statusTextFrench,
        style: TextStyle(
          color: ticket.status.resolveColor(context),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, WorkTicket ticket) {
    final bool hasStarted = ticket.status == TicketStatus.inProgress ||
        ticket.status == TicketStatus.resolved;
    final bool hasResolved = ticket.status == TicketStatus.resolved;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppSemanticColors>()!.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<AppSemanticColors>()!.border),
      ),
      child: Column(
        children: [
          _buildTimelineItem(context: context, 
            title: 'Création du ticket',
            time: DateFormat('dd/MM/yyyy à HH:mm').format(ticket.dateCreated),
            subtitle: 'Ticket signalé par l\'opérateur',
            isActive: true,
            isLast: !hasStarted,
          ),
          if (hasStarted)
            _buildTimelineItem(context: context, 
              title: 'Pris en charge',
              time: DateFormat('dd/MM/yyyy à HH:mm')
                  .format(ticket.dateCreated.add(Duration(minutes: 15))),
              subtitle:
                  'Assigné à ${ticket.assignedTechnician ?? "Karim (Technicien)"}',
              isActive: true,
              isLast: !hasResolved,
            ),
          if (hasResolved)
            _buildTimelineItem(context: context, 
              title: ticket.type == TicketType.anomaly ? 'Résolu' : 'Terminé',
              time: DateFormat('dd/MM/yyyy à HH:mm')
                  .format(ticket.dateCompleted ?? DateTime.now()),
              subtitle: 'Intervention validée sur le terrain',
              isActive: true,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required BuildContext context, 
    required String title,
    required String time,
    required String subtitle,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).extension<AppSemanticColors>()!.success : Theme.of(context).extension<AppSemanticColors>()!.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive
                    ? Theme.of(context).extension<AppSemanticColors>()!.success.withValues(alpha: 0.5)
                    : Theme.of(context).extension<AppSemanticColors>()!.border,
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  Text(time,
                      style: TextStyle(
                          color: Theme.of(context).extension<AppSemanticColors>()!.textMuted, fontSize: 11)),
                ],
              ),
              SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary, fontSize: 12)),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
