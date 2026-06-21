import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Screen to create a new reservation.
class CreateReservationScreen extends StatefulWidget {
  CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  String? _selectedActivity;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _clientNameCtrl = TextEditingController();
  int _peopleCount = 2;
  String _status = 'Confirmé';
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  static _activities = [
    _ActivityOption(id: 'pool', label: 'Piscine', icon: Icons.pool),
    _ActivityOption(id: 'horses', label: 'Équitation', icon: Icons.pets),
    _ActivityOption(
        id: 'shooting', label: 'Stand de Tir', icon: Icons.gps_fixed),
    _ActivityOption(
        id: 'padel', label: 'Terrains de Padel', icon: Icons.sports_tennis),
    _ActivityOption(id: 'paintball', label: 'Paintball', icon: Icons.adjust),
    _ActivityOption(
        id: 'gym', label: 'Salle de Sport', icon: Icons.fitness_center),
  ];

  static _statuses = ['Confirmé', 'En attente', 'Annulé'];

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
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: context.colors.accentPrimary,
            surface: context.colors.backgroundSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: context.colors.accentPrimary,
            surface: context.colors.backgroundSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-advance end time by 1 hour if it's before/same start
          final startMinutes = picked.hour * 60 + picked.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            final newEnd = startMinutes + 60;
            _endTime =
                TimeOfDay(hour: (newEnd ~/ 60) % 24, minute: newEnd % 60);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une activité'),
          backgroundColor: context.colors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(Duration(milliseconds: 600)); // Simulate save

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Réservation créée pour ${_clientNameCtrl.text}',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: context.colors.success,
        duration: Duration(seconds: 3),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Réservation'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: context.colors.accentPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? constraints.maxWidth * 0.15 : 16,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Activity Selector ──────────────────────────────
                  _sectionLabel('Activité *'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activities.map((act) {
                      final color = _activityColor(act.id);
                      final isSelected = _selectedActivity == act.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedActivity = act.id),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : context.colors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : context.colors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                act.icon,
                                size: 16,
                                color: isSelected ? color : context.colors.textMuted,
                              ),
                              SizedBox(width: 6),
                              Text(
                                act.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : context.colors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),

                  // ── Date ──────────────────────────────────────────
                  _sectionLabel('Date *'),
                  SizedBox(height: 8),
                  _FieldCard(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: context.colors.accentPrimary, size: 20),
                        SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                              .format(_selectedDate),
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right,
                            color: context.colors.textMuted, size: 18),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // ── Time slot ─────────────────────────────────────
                  _sectionLabel('Créneau horaire *'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldCard(
                          onTap: () => _pickTime(isStart: true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Début',
                                style: TextStyle(
                                    color: context.colors.textMuted, fontSize: 11),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      color: context.colors.accentPrimary, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    _startTime.format(context),
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            color: context.colors.textMuted, size: 18),
                      ),
                      Expanded(
                        child: _FieldCard(
                          onTap: () => _pickTime(isStart: false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fin',
                                style: TextStyle(
                                    color: context.colors.textMuted, fontSize: 11),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_filled,
                                      color: context.colors.accentPrimary, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    _endTime.format(context),
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // ── Client Name ───────────────────────────────────
                  _sectionLabel('Client / Groupe *'),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: _clientNameCtrl,
                    hint: 'Ex: M. Ahmed Bennani, Groupe famille…',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ce champ est requis'
                        : null,
                  ),
                  SizedBox(height: 24),

                  // ── People count & Status ─────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // People count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Nb. personnes'),
                            SizedBox(height: 8),
                            _FieldCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CounterButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (_peopleCount > 1) {
                                        setState(() => _peopleCount--);
                                      }
                                    },
                                  ),
                                  Text(
                                    '$_peopleCount pers.',
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _CounterButton(
                                    icon: Icons.add,
                                    onTap: () => setState(() => _peopleCount++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      // Status dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Statut'),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.colors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _status,
                                  isExpanded: true,
                                  dropdownColor: context.colors.backgroundSecondary,
                                  style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 14),
                                  items: _statuses
                                      .map((s) => DropdownMenuItem(
                                          value: s, child: Text(s)))
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // ── Notes ─────────────────────────────────────────
                  _sectionLabel('Notes (facultatif)'),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: _notesCtrl,
                    hint: 'Besoins spéciaux, matériel requis…',
                    icon: Icons.note_alt_outlined,
                    maxLines: 3,
                  ),
                  SizedBox(height: 32),

                  // ── Save Button ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.check_circle_outline,
                              color: Colors.white),
                      label: Text(
                        _isSaving
                            ? 'Enregistrement…'
                            : 'Confirmer la réservation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accentPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: context.colors.textMuted, size: 20),
        filled: true,
        fillColor: context.colors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.colors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.danger, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

/// Simple tappable card wrapper for form "fields" that open a picker.
class _FieldCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  _FieldCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// +/- counter button
class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.0),
          child: Icon(icon, size: 18, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

class _ActivityOption {
  final String id;
  final String label;
  final IconData icon;

  _ActivityOption(
      {required this.id, required this.label, required this.icon});
}
