import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/ticket_ui_adapter.dart';
import '../widgets/app_layout.dart';

/// Detail of one incident or maintenance ticket.
///
/// The primary action (take over, then resolve) is pinned to the bottom bar.
/// Everything else scrolls: details, technician, photos, timeline, comments.
class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentController = TextEditingController();

  // Technicians known to the tablet. Odoo has the users, but the app does not
  // read them yet (see the report: res.users needs a read endpoint).
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
        title: 'Ticket introuvable',
        description: '',
        activityId: '',
        activityName: '',
        type: TicketType.anomaly,
        priority: TicketPriority.low,
        status: TicketStatus.open,
        dateCreated: DateTime.now(),
      ),
    );
    final isKnown = tickets.any((t) => t.id == widget.id);
    final colors = context.colors;
    final priorityColor = switch (ticket.priority) {
      TicketPriority.critical => colors.priorityCritical,
      TicketPriority.high => colors.priorityHigh,
      TicketPriority.medium => colors.priorityMedium,
      TicketPriority.low => colors.priorityLow,
    };

    final isIncident = ticket.type == TicketType.anomaly;

    return AppPage(
      title: isIncident ? 'Incident' : 'Intervention',
      subtitle: ticket.activityName.isEmpty ? null : ticket.activityName,
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go('/tickets'),
      ),
      actions: [
        IconButton(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      bottomBar: isKnown && ticket.status != TicketStatus.resolved
          ? _PrimaryAction(ticket: ticket, isIncident: isIncident)
          : null,
      body: !isKnown
          ? const AppErrorState(
              title: 'Ticket introuvable',
              message:
                  'Ce ticket n’est plus dans la liste synchronisée. Revenez à la liste et actualisez.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  accentColor: ticket.isOverdue ? colors.danger : priorityColor,
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: _Header(ticket: ticket),
                ),
                const SizedBox(height: 14),
                AppPanel(child: _Details(ticket: ticket, technicians: _technicians)),
                if (ticket.photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _PhotosPanel(paths: ticket.photoPaths),
                ],
                const SizedBox(height: 14),
                AppPanel(child: _Timeline(events: ticket.events)),
                const SizedBox(height: 14),
                _CommentComposer(
                  controller: _commentController,
                  onSend: () => _sendComment(ticket),
                ),
              ],
            ),
    );
  }

  Future<void> _sendComment(WorkTicket ticket) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await ref.read(ticketsProvider.notifier).addComment(ticket.id, text);
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.ticket});

  final WorkTicket ticket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = ticket.status.resolveColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            AppPill(
              label: ticket.typeTextFrench,
              color: ticket.type.resolveColor(context),
            ),
            AppPill(
              label: ticket.priorityTextFrench,
              color: ticket.priority.resolveColor(context),
              icon: Icons.flag_rounded,
            ),
            AppPill(label: ticket.statusTextFrench, color: statusColor),
            if (ticket.isOverdue)
              AppPill(
                label: 'En retard',
                color: colors.danger,
                icon: Icons.schedule_rounded,
                filled: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ticket.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _IconLabel(
              icon: Icons.grid_view_rounded,
              label: ticket.activityName.isEmpty
                  ? 'Activité non renseignée'
                  : ticket.activityName,
              color: colors.getActivityColor(ticket.activityId),
            ),
            if (ticket.assetName != null)
              _IconLabel(
                icon: Icons.settings_rounded,
                label: ticket.assetName!,
                color: colors.textSecondary,
              ),
          ],
        ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _Details extends ConsumerWidget {
  const _Details({required this.ticket, required this.technicians});

  final WorkTicket ticket;
  final List<String> technicians;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');
    final assigned = ticket.assignedTechnician;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ticket.description.isNotEmpty
              ? ticket.description
              : 'Aucune description fournie.',
          style: TextStyle(
            color: ticket.description.isNotEmpty
                ? colors.textPrimary
                : colors.textMuted,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        Divider(height: 28, color: colors.border),
        Wrap(
          spacing: 24,
          runSpacing: 14,
          children: [
            _DateItem(
              label: 'Créé le',
              value: dateFormat.format(ticket.dateCreated),
              icon: Icons.calendar_today_rounded,
              color: colors.textSecondary,
            ),
            if (ticket.dateDue != null)
              _DateItem(
                label: 'Échéance',
                value: dateFormat.format(ticket.dateDue!),
                icon: Icons.alarm_rounded,
                color: ticket.isOverdue ? colors.danger : colors.textSecondary,
              ),
            if (ticket.dateCompleted != null)
              _DateItem(
                label: 'Clôturé le',
                value: dateFormat.format(ticket.dateCompleted!),
                icon: Icons.check_circle_outline_rounded,
                color: colors.success,
              ),
          ],
        ),
        Divider(height: 28, color: colors.border),
        Row(
          children: [
            Icon(Icons.person_outline_rounded, color: colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                assigned ?? 'Aucun technicien assigné',
                style: TextStyle(
                  color: assigned == null ? colors.textMuted : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickTechnician(context, ref),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(assigned == null ? 'Assigner' : 'Changer'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTechnician(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Assigner un technicien',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final tech in technicians)
              ListTile(
                minVerticalPadding: 14,
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
}

class _DateItem extends StatelessWidget {
  const _DateItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.ticket, required this.isIncident});

  final WorkTicket ticket;
  final bool isIncident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(ticketsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (ticket.status == TicketStatus.open) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: colors.warning,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 26),
        label: const Text('Prendre en charge'),
        onPressed: () {
          notifier.updateTicketStatus(ticket.id, TicketStatus.inProgress);
          messenger.showSnackBar(
            const SnackBar(content: Text('Ticket pris en charge ✓')),
          );
        },
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colors.success,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
      ),
      icon: const Icon(Icons.check_rounded, size: 26),
      label: Text(isIncident ? 'Marquer résolu' : 'Terminer l’intervention'),
      onPressed: () {
        notifier.updateTicketStatus(ticket.id, TicketStatus.resolved);
        messenger.showSnackBar(
          const SnackBar(content: Text('Ticket résolu ✓')),
        );
      },
    );
  }
}

class _PhotosPanel extends StatelessWidget {
  const _PhotosPanel({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos (${paths.length})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  paths[index],
                  width: 170,
                  height: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 170,
                    height: 128,
                    color: colors.surface,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined,
                        color: colors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<TicketEvent> events;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ordered = events.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        if (ordered.isEmpty)
          Text(
            'Aucun évènement enregistré.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          )
        else
          for (var i = 0; i < ordered.length; i++)
            _TimelineRow(event: ordered[i], isLast: i == ordered.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final TicketEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = _styleFor(context, event.type);
    final when = event.at != null
        ? DateFormat('dd/MM · HH:mm').format(event.at!)
        : '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 16, color: style.color),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.message ?? '',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.author != null && event.author!.isNotEmpty)
                        event.author!,
                      when,
                    ].join(' · '),
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static ({IconData icon, Color color}) _styleFor(
      BuildContext context, TicketEventType type) {
    final colors = context.colors;
    switch (type) {
      case TicketEventType.created:
        return (icon: Icons.flag_rounded, color: colors.accentPrimary);
      case TicketEventType.statusChanged:
        return (icon: Icons.sync_rounded, color: colors.info);
      case TicketEventType.commented:
        return (
          icon: Icons.chat_bubble_outline_rounded,
          color: colors.accentSecondary
        );
      case TicketEventType.photoAdded:
        return (icon: Icons.photo_camera_outlined, color: colors.gym);
      case TicketEventType.assigned:
        return (icon: Icons.person_add_alt_rounded, color: colors.success);
    }
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              hintText: 'Ajouter un commentaire…',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          height: 56,
          child: FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(56, 56),
            ),
            child: const Icon(Icons.send_rounded, size: 22),
          ),
        ),
      ],
    );
  }
}
