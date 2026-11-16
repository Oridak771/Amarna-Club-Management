import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/reservations_provider.dart';
import '../providers/activities_provider.dart';
import '../models/activity.dart';
import '../models/reservation.dart';
import '../services/odoo_reservation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

/// « Nouvelle réservation » — a short form: activity, slot, client, people.
///
/// One sticky primary action at the bottom; every control is at least 48dp.
class CreateReservationScreen extends ConsumerStatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  ConsumerState<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends ConsumerState<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedActivity;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _clientNameCtrl = TextEditingController();
  int _peopleCount = 2;
  ReservationStatus _status = ReservationStatus.confirmed;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  static final _activities = [
    const _ActivityOption(id: 'pool', label: 'Piscine', icon: Icons.pool),
    const _ActivityOption(id: 'horses', label: 'Equitation', icon: Icons.pets),
    const _ActivityOption(
      id: 'shooting',
      label: 'Stand de Tir',
      icon: Icons.gps_fixed,
    ),
    const _ActivityOption(
      id: 'padel',
      label: 'Terrains de Padel',
      icon: Icons.sports_tennis,
    ),
    const _ActivityOption(id: 'paintball', label: 'Paintball', icon: Icons.adjust),
    const _ActivityOption(
      id: 'gym',
      label: 'Salle de Sport',
      icon: Icons.fitness_center,
    ),
  ];

  // A new booking is either confirmed or pending; cancelling is done on the
  // reservation itself.
  static const _statuses = [ReservationStatus.confirmed, ReservationStatus.pending];

  static String _statusLabel(ReservationStatus status) =>
      status == ReservationStatus.pending ? 'En attente' : 'Confirmée';

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startTime = picked;
        final startMinutes = picked.hour * 60 + picked.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          final newEnd = startMinutes + 60;
          _endTime = TimeOfDay(hour: (newEnd ~/ 60) % 24, minute: newEnd % 60);
        }
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedActivity == null) {
      _showSnack(
        'Veuillez sélectionner une activité',
        context.colors.danger,
      );
      return;
    }

    final activity =
        _activities.firstWhere((item) => item.id == _selectedActivity);
    final startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endAt.isAfter(startAt)) {
      _showSnack(
        'L\'heure de fin doit être après l\'heure de début.',
        context.colors.warning,
      );
      return;
    }

    // Check the same operational window locally as the Odoo constraint. The
    // server repeats this check, so stale mobile caches cannot create a
    // reservation for a closed activity.
    await ref.read(activitiesProvider.notifier).ensureLoaded();
    if (!mounted) return;
    final activities = ref.read(activitiesProvider);
    final liveActivity = activities.cast<Activity?>().firstWhere(
          (item) => item?.id == activity.id,
          orElse: () => null,
        );
    if (liveActivity == null) {
      _showSnack(
        'Activité indisponible : son état n’est pas encore synchronisé.',
        context.colors.warning,
      );
      return;
    }
    if (!liveActivity.isAvailableAt(startAt, endAt)) {
      final reason = liveActivity.status != ActivityStatus.open
          ? 'l’activité est ${liveActivity.statusTextFrench.toLowerCase()}'
          : 'le créneau chevauche sa période de fermeture';
      _showSnack('Réservation impossible : $reason.', context.colors.danger);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(odooReservationServiceProvider).createReservation(
            activityId: activity.id,
            activityName: activity.label,
            clientName: _clientNameCtrl.text.trim(),
            peopleCount: _peopleCount,
            status: _status,
            startAt: startAt,
            endAt: endAt,
            notes: _notesCtrl.text.trim(),
          );

      ref.read(reservationsRefreshProvider.notifier).state++;

      if (!mounted) {
        return;
      }
      _showSnack(
        'Réservation créée pour ${_clientNameCtrl.text.trim()}',
        context.colors.success,
      );
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Création impossible : $error',
        context.colors.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: context.colors.textOnAccent)),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPage(
      title: 'Nouvelle réservation',
      subtitle: 'Créneau, client et nombre de personnes',
      maxWidth: 760,
      leading: IconButton(
        tooltip: 'Fermer',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
      ),
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(_isSaving
            ? 'Enregistrement…'
            : 'Confirmer la réservation'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Activité *'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _activities.map((act) {
                final color = _activityColor(act.id);
                final isSelected = _selectedActivity == act.id;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: act.label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.16)
                          : colors.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusField),
                      border: Border.all(
                        color: isSelected ? color : colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusField),
                      onTap: () => setState(() => _selectedActivity = act.id),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                act.icon,
                                size: 20,
                                color: isSelected ? color : colors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                act.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : colors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Date *'),
            const SizedBox(height: 10),
            _FieldCard(
              onTap: _pickDate,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: colors.accentPrimary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                          .format(_selectedDate),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.textMuted, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Créneau horaire *'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FieldCard(
                    onTap: () => _pickTime(isStart: true),
                    child: _timeContent(
                      'Début',
                      _startTime.format(context),
                      Icons.access_time_rounded,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: colors.textMuted, size: 20),
                ),
                Expanded(
                  child: _FieldCard(
                    onTap: () => _pickTime(isStart: false),
                    child: _timeContent(
                      'Fin',
                      _endTime.format(context),
                      Icons.access_time_filled_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionLabel('Client / Groupe *'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _clientNameCtrl,
              hint: 'Ex: Groupe famille, client entreprise…',
              icon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Ce champ est requis'
                  : null,
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                // Two side-by-side fields on tablets; stacked on phones so the
                // 48dp counter buttons never overflow the field.
                final people = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Nb. personnes'),
                    const SizedBox(height: 10),
                    _FieldCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CounterButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'Retirer une personne',
                            onTap: () {
                              if (_peopleCount > 1) {
                                setState(() => _peopleCount--);
                              }
                            },
                          ),
                          Text(
                            '$_peopleCount pers.',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _CounterButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Ajouter une personne',
                            onTap: () => setState(() => _peopleCount++),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final status = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Statut'),
                    const SizedBox(height: 10),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusField),
                        border: Border.all(color: colors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ReservationStatus>(
                          value: _status,
                          isExpanded: true,
                          dropdownColor: colors.backgroundSecondary,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          items: _statuses
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_statusLabel(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _status = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      people,
                      const SizedBox(height: 22),
                      status,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: people),
                    const SizedBox(width: 12),
                    Expanded(child: status),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _sectionLabel('Notes'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _notesCtrl,
              hint: 'Besoins spéciaux, matériel requis…',
              icon: Icons.note_alt_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeContent(String label, String value, IconData icon) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: colors.accentPrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppTheme.radiusField);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
        prefixIcon: Icon(icon, color: colors.textMuted, size: 22),
        filled: true,
        fillColor: colors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Color _activityColor(String id) {
    switch (id) {
      case 'pool':
        return context.colors.pool;
      case 'horses':
        return context.colors.horses;
      case 'shooting':
        return context.colors.danger;
      case 'padel':
        return context.colors.padel;
      case 'paintball':
        return context.colors.paintball;
      case 'gym':
        return context.colors.gym;
      default:
        return context.colors.accentPrimary;
    }
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FieldCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(color: colors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: colors.textPrimary),
    );
  }
}

class _ActivityOption {
  final String id;
  final String label;
  final IconData icon;

  const _ActivityOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}
