import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/asset.dart';
import '../models/work_ticket.dart';
import '../providers/activities_provider.dart';
import '../providers/assets_provider.dart';
import '../providers/club_config_provider.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../ui/activity_ui_adapter.dart';
import '../widgets/app_layout.dart';

/// « Nouvelle intervention » — report an incident or plan a maintenance task.
///
/// Activities and equipment come from the synced Odoo data, so the ticket is
/// always linked to a real record. The form is short on purpose: type,
/// activity, equipment, priority, then what happened.
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketType _type = TicketType.anomaly;
  TicketPriority _priority = TicketPriority.medium;
  String? _activityId;
  String? _assetId;
  DateTime? _dueDate;
  String? _technician;
  bool _prefillApplied = false;
  bool _saving = false;

  // Staff from Odoo (Configuration > Personnel du club).
  List<String> get _staff =>
      ref.watch(assignableStaffProvider).valueOrNull ?? const [];

  // Due date proposed when none is picked: the club's delay setting.
  DateTime get _defaultDueDate => DateTime.now().add(Duration(
      days: ref.read(clubConfigProvider).requireValue.tickets.dueDays));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isIncident => _type == TicketType.anomaly;

  /// Applies `extra` passed by the asset screen once, on first build.
  void _applyPrefill(List<Asset> assets, List<Activity> activities) {
    if (_prefillApplied) return;
    _prefillApplied = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return;
    final assetId = extra['prefilledAssetId'] as String?;
    if (assetId == null) return;
    final asset = assets.where((a) => a.id == assetId).firstOrNull;
    if (asset != null) {
      _assetId = asset.id;
      _activityId = asset.activityId;
    }
  }

  Future<void> _submit(List<Asset> assets, List<Activity> activities) async {
    if (!_formKey.currentState!.validate()) return;
    final activityId = _activityId;
    if (activityId == null) return;
    final activity = activities.where((a) => a.id == activityId).firstOrNull;
    final asset = _assetId == null
        ? null
        : assets.where((a) => a.id == _assetId).firstOrNull;

    setState(() => _saving = true);
    try {
      await ref.read(ticketsProvider.notifier).addTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            activityId: activityId,
            activityName: activity?.name ?? '',
            type: _type,
            priority: _priority,
            assetId: asset?.id,
            assetName: asset?.name,
            dateDue: _isIncident ? null : (_dueDate ?? _defaultDueDate),
            assignedTechnician: _isIncident ? null : _technician,
          );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/tickets');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isIncident
              ? 'Incident signalé ✓'
              : 'Intervention planifiée ✓'),
          backgroundColor:
              _isIncident ? context.colors.danger : context.colors.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activities = ref.watch(activitiesProvider);
    final assets = ref.watch(assetsProvider);
    _applyPrefill(assets, activities);

    final activityId = _activityId;
    final activityAssets = activityId == null
        ? const <Asset>[]
        : assets.where((a) => a.activityId == activityId).toList();
    if (_assetId != null &&
        !activityAssets.any((a) => a.id == _assetId)) {
      _assetId = null;
    }

    return AppPage(
      title: _isIncident ? 'Signaler un incident' : 'Planifier une intervention',
      subtitle: _isIncident
          ? 'Un technicien sera alerté'
          : 'Maintenance préventive ou corrective',
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _isIncident ? colors.danger : colors.accentPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
        ),
        onPressed: _saving || activities.isEmpty
            ? null
            : () => _submit(assets, activities),
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Icon(_isIncident
                ? Icons.add_alert_rounded
                : Icons.event_available_rounded),
        label: Text(_isIncident ? 'Signaler l’incident' : 'Enregistrer'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel('Nature'),
            SegmentedButton<TicketType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TicketType.anomaly,
                  label: Text('Incident'),
                  icon: Icon(Icons.warning_amber_rounded),
                ),
                ButtonSegment(
                  value: TicketType.preventive,
                  label: Text('Préventive'),
                  icon: Icon(Icons.event_repeat_rounded),
                ),
                ButtonSegment(
                  value: TicketType.corrective,
                  label: Text('Corrective'),
                  icon: Icon(Icons.build_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Activité'),
            if (activities.isEmpty)
              const AppEmptyState(
                icon: Icons.sports_rounded,
                title: 'Aucune activité disponible',
                message: 'Synchronisez les données depuis l’accueil.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final activity in activities)
                    ChoiceChip(
                      avatar: Icon(
                        resolveActivityIcon(activity.iconKey),
                        size: 18,
                        color: resolveActivityColor(context, activity.id),
                      ),
                      label: Text(activity.name),
                      selected: _activityId == activity.id,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _activityId == activity.id
                            ? colors.accentPrimary
                            : colors.textPrimary,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() {
                        _activityId = activity.id;
                        _assetId = null;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 22),
            const _FieldLabel('Équipement (facultatif)'),
            if (activityId == null)
              Text(
                'Choisissez d’abord une activité.',
                style: TextStyle(color: colors.textMuted),
              )
            else if (activityAssets.isEmpty)
              Text(
                'Aucun équipement enregistré pour cette activité.',
                style: TextStyle(color: colors.textMuted),
              )
            else
              DropdownButtonFormField<String?>(
                initialValue: _assetId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.settings_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Aucun équipement précis'),
                  ),
                  for (final asset in activityAssets)
                    DropdownMenuItem<String?>(
                      value: asset.id,
                      child: Text(
                        asset.serialNumber.isEmpty
                            ? asset.name
                            : '${asset.name} · ${asset.serialNumber}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _assetId = value),
              ),
            const SizedBox(height: 22),
            const _FieldLabel('Priorité'),
            _PriorityPicker(
              value: _priority,
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Ce qui se passe'),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex. Fuite sur le filtre n°2',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Le titre est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Détails',
                hintText: 'Ce qui a été observé, depuis quand, action immédiate…',
                alignLabelWithHint: true,
              ),
            ),
            if (!_isIncident) ...[
              const SizedBox(height: 22),
              const _FieldLabel('Planification'),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _dueDate == null
                      ? 'Choisir une échéance'
                      : 'Échéance : ${DateFormat('EEEE d MMMM', 'fr_FR').format(_dueDate!)}',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _technician,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                hint: const Text('Technicien (facultatif)'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Non assigné'),
                  ),
                  for (final tech in _staff)
                    DropdownMenuItem<String?>(value: tech, child: Text(tech)),
                ],
                onChanged: (value) => setState(() => _technician = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// Four large priority tiles in a row (2×2 on narrow screens).
class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.value, required this.onChanged});

  final TicketPriority value;
  final ValueChanged<TicketPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final options = [
      (TicketPriority.low, 'Faible', colors.priorityLow),
      (TicketPriority.medium, 'Moyen', colors.priorityMedium),
      (TicketPriority.high, 'Élevé', colors.priorityHigh),
      (TicketPriority.critical, 'Critique', colors.priorityCritical),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (priority, label, color) in options)
              SizedBox(
                width: width,
                child: _PriorityTile(
                  label: label,
                  color: color,
                  selected: value == priority,
                  onTap: () => onChanged(priority),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        onTap: onTap,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(
              color: selected ? color : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
