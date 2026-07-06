import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/ticket_ui_adapter.dart';
import '../widgets/priority_indicator.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TicketDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TicketDetailScreen> createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentController = TextEditingController();

  static const _technicians = [
    'Karim (Technicien)',
    'Mourad (Technicien)',
    'Sami (Électricien)',
    'Sophie (Coach Gym)',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final ticket = tickets.firstWhere(
      (t) => t.id == widget.id,
      orElse: () => WorkTicket(
        id: widget.id,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.type == TicketType.anomaly
            ? 'Détail incident'
            : 'Détail intervention'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(ticket),
                const SizedBox(height: 16),
                _buildInfoCard(ticket),
                if (ticket.photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPhotosCard(ticket),
                ],
                const SizedBox(height: 16),
                if (ticket.status != TicketStatus.resolved) ...[
                  _buildActions(ticket),
                  const SizedBox(height: 16),
                ],
                _buildTimelineCard(ticket),
                const SizedBox(height: 12),
                _buildCommentComposer(ticket),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Header -----------------------------------------------------------

  Widget _buildHeaderCard(WorkTicket ticket) {
    final colors = context.colors;
    return PriorityIndicator(
      priority: ticket.priority,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge(ticket.typeTextFrench,
                    ticket.type.resolveColor(context)),
                const SizedBox(width: 8),
                _badge(ticket.priorityTextFrench,
                    ticket.priority.resolveColor(context)),
                const Spacer(),
                _badge(ticket.statusTextFrench,
                    ticket.status.resolveColor(context)),
              ],
            ),
            const SizedBox(height: 12),
            Text(ticket.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _iconLabel(
                  Icons.grid_view_rounded,
                  ticket.activityName,
                  colors.getActivityColor(ticket.activityId),
                ),
                if (ticket.assetName != null)
                  _iconLabel(Icons.settings_rounded, ticket.assetName!,
                      colors.textSecondary),
                _iconLabel(
                  Icons.person_outline_rounded,
                  ticket.assignedTechnician ?? 'Non assigné',
                  ticket.assignedTechnician != null
                      ? colors.textSecondary
                      : colors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _iconLabel(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // -- Info -------------------------------------------------------------

  Widget _buildInfoCard(WorkTicket ticket) {
    final colors = context.colors;
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description',
              style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            ticket.description.isNotEmpty
                ? ticket.description
                : 'Aucune description fournie.',
            style: TextStyle(
                color: colors.textPrimary, fontSize: 14, height: 1.4),
          ),
          Divider(height: 24, color: colors.border),
          Row(
            children: [
              Expanded(
                child: _dateColumn(
                  'Créé le',
                  dateFormat.format(ticket.dateCreated),
                  Icons.calendar_today_rounded,
                  colors.textSecondary,
                ),
              ),
              if (ticket.dateDue != null)
                Expanded(
                  child: _dateColumn(
                    'Échéance',
                    dateFormat.format(ticket.dateDue!),
                    Icons.access_alarm_rounded,
                    ticket.isOverdue ? colors.danger : colors.textSecondary,
                  ),
                ),
              if (ticket.dateCompleted != null)
                Expanded(
                  child: _dateColumn(
                    'Clôturé le',
                    dateFormat.format(ticket.dateCompleted!),
                    Icons.check_circle_outline_rounded,
                    colors.success,
                  ),
                ),
            ],
          ),
          Divider(height: 24, color: colors.border),
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.assignedTechnician == null
                      ? 'Aucun technicien assigné'
                      : 'Assigné à ${ticket.assignedTechnician}',
                  style: TextStyle(
                    color: ticket.assignedTechnician == null
                        ? colors.textMuted
                        : colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTechnician(ticket),
                icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                label: Text(ticket.assignedTechnician == null
                    ? 'Assigner'
                    : 'Réassigner'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateColumn(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(value,
                style: TextStyle(
                    color: context.colors.textPrimary, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTechnician(WorkTicket ticket) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Assigner un technicien',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            for (final tech in _technicians)
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(tech),
                trailing: ticket.assignedTechnician == tech
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, tech),
              ),
          ],
        ),
      ),
    );

    if (selected != null && selected != ticket.assignedTechnician) {
      await ref
          .read(ticketsProvider.notifier)
          .assignTechnician(ticket.id, selected);
    }
  }

  // -- Photos -----------------------------------------------------------

  Widget _buildPhotosCard(WorkTicket ticket) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos (${ticket.photoPaths.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ticket.photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  ticket.photoPaths[index],
                  width: 160,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 120,
                    color: context.colors.surface,
                    child: Icon(Icons.broken_image_outlined,
                        color: context.colors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Actions ----------------------------------------------------------

  Widget _buildActions(WorkTicket ticket) {
    final colors = context.colors;
    final notifier = ref.read(ticketsProvider.notifier);

    return Row(
      children: [
        if (ticket.status == TicketStatus.open)
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.warning,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 52),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Prendre en charge'),
              onPressed: () {
                notifier.updateTicketStatus(
                    ticket.id, TicketStatus.inProgress);
                _snack('Ticket pris en charge ✓');
              },
            ),
          ),
        if (ticket.status == TicketStatus.inProgress)
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(ticket.type == TicketType.anomaly
                  ? 'Marquer résolu'
                  : 'Terminer l\'intervention'),
              onPressed: () {
                notifier.updateTicketStatus(ticket.id, TicketStatus.resolved);
                _snack('Ticket résolu ✓');
              },
            ),
          ),
      ],
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // -- Timeline & comments ----------------------------------------------

  Widget _buildTimelineCard(WorkTicket ticket) {
    final colors = context.colors;
    final events = ticket.events.reversed.toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historique', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Text(
              'Aucun évènement enregistré.',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            )
          else
            for (var i = 0; i < events.length; i++)
              _timelineRow(events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _eventStyle(TicketEventType type) {
    final colors = context.colors;
    switch (type) {
      case TicketEventType.created:
        return (icon: Icons.flag_rounded, color: colors.accentPrimary);
      case TicketEventType.statusChanged:
        return (icon: Icons.sync_rounded, color: colors.info);
      case TicketEventType.commented:
        return (icon: Icons.chat_bubble_outline_rounded, color: colors.accentSecondary);
      case TicketEventType.photoAdded:
        return (icon: Icons.photo_camera_outlined, color: colors.gym);
      case TicketEventType.assigned:
        return (icon: Icons.person_add_alt_rounded, color: colors.success);
    }
  }

  Widget _timelineRow(TicketEvent event, {required bool isLast}) {
    final colors = context.colors;
    final style = _eventStyle(event.type);
    final when = event.at != null
        ? DateFormat('dd/MM à HH:mm').format(event.at!)
        : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 16, color: style.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: colors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.message ?? '',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                      Text(when,
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 11)),
                    ],
                  ),
                  if (event.author != null && event.author!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.author!,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer(WorkTicket ticket) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              hintText: 'Ajouter un commentaire…',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
            ),
            onSubmitted: (_) => _sendComment(ticket),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: FilledButton(
            onPressed: () => _sendComment(ticket),
            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _sendComment(WorkTicket ticket) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await ref.read(ticketsProvider.notifier).addComment(ticket.id, text);
  }

  // -- Shared card decoration --------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}
