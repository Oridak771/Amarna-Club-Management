import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/work_ticket.dart';
import '../providers/tickets_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assetNameController = TextEditingController();

  // Unified types: Anomaly vs Preventive vs Corrective
  TicketType _selectedType = TicketType.anomaly;
  String _selectedActivityId = 'pool';
  String _selectedActivityName = 'Piscine';
  TicketPriority _selectedPriority = TicketPriority.medium;

  // Media simulation
  int _mockPhotoCount = 0;
  bool _hasVoiceNote = false;
  bool _isRecording = false;

  String? _assignedTechnician = 'Karim (Technicien)';

  final List<String> _technicians = [
    'Karim (Technicien)',
    'Sami (Électricien)',
    'Mourad (Technicien)',
    'Non assigné',
  ];

  final Map<String, String> _activities = {
    'pool': 'Piscine',
    'horses': 'Équitation',
    'paintball': 'Paintball',
    'shooting': 'Stand de Tir',
    'gym': 'Salle de Gym',
    'padel': 'Terrains de Padel',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assetNameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final assetNameVal = _assetNameController.text.trim();
      final hasAsset = assetNameVal.isNotEmpty;

      ref.read(ticketsProvider.notifier).addTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            activityId: _selectedActivityId,
            activityName: _selectedActivityName,
            type: _selectedType,
            priority: _selectedPriority,
            assetId: hasAsset
                ? 'asset-${DateTime.now().millisecondsSinceEpoch}'
                : null,
            assetName: hasAsset ? assetNameVal : null,
            assignedTechnician: _selectedType == TicketType.anomaly
                ? null
                : (_assignedTechnician == 'Non assigné'
                    ? null
                    : _assignedTechnician),
            imageUrl: _mockPhotoCount > 0
                ? 'https://example.com/ticket-photo.jpg'
                : null,
            voiceNoteUrl:
                _hasVoiceNote ? 'https://example.com/voice-note.mp3' : null,
          );

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedType == TicketType.anomaly
              ? 'Signalement d\'anomalie enregistré ✓'
              : 'Tâche de maintenance créée ✓'),
          backgroundColor: _selectedType == TicketType.anomaly
              ? AppColors.danger
              : AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTechnicianAndAsset = _selectedType != TicketType.anomaly;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Ticket d\'intervention'),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Ticket Type Switch
                    const Text(
                      'Nature de l\'intervention',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppFilterChip(
                          label: 'Signalement d\'anomalie',
                          isSelected: _selectedType == TicketType.anomaly,
                          onTap: () => setState(
                              () => _selectedType = TicketType.anomaly),
                        ),
                        const SizedBox(width: 8),
                        AppFilterChip(
                          label: 'Maintenance Préventive',
                          isSelected: _selectedType == TicketType.preventive,
                          onTap: () => setState(
                              () => _selectedType = TicketType.preventive),
                        ),
                        const SizedBox(width: 8),
                        AppFilterChip(
                          label: 'Maintenance Corrective',
                          isSelected: _selectedType == TicketType.corrective,
                          onTap: () => setState(
                              () => _selectedType = TicketType.corrective),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Activity Selector
                    const Text(
                      'Activité concernée',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.backgroundSecondary,
                      initialValue: _selectedActivityId,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _activities.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedActivityId = val;
                            _selectedActivityName = _activities[val]!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Asset selector (conditional/optional)
                    const Text(
                      'Équipement / Asset (Optionnel)',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _assetNameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nom ou Code-barres de l\'équipement',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppColors.accentPrimary),
                          onPressed: () {
                            // Mock scan search
                            setState(() {
                              _assetNameController.text =
                                  _selectedActivityId == 'pool'
                                      ? 'Pompe de Filtration 2'
                                      : _selectedActivityId == 'horses'
                                          ? 'Selle Cuir Tornade'
                                          : 'Équipement Standard';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Équipement détecté : ${_assetNameController.text}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (showTechnicianAndAsset &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Veuillez saisir ou scanner un équipement pour planifier une maintenance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4. Title Field
                    const Text(
                      'Titre / Résumé',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ex: Filtre de pompe obstrué',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir un titre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 5. Description Field
                    const Text(
                      'Description',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText:
                            'Expliquez en détail le problème ou l\'intervention requise...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6. Priority Selector (Large Buttons)
                    const Text(
                      'Niveau de priorité',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPrioritySelector(),
                    const SizedBox(height: 20),

                    // 7. Technician Assignment (conditional)
                    if (showTechnicianAndAsset) ...[
                      const Text(
                        'Technicien assigné',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.backgroundSecondary,
                        initialValue: _assignedTechnician,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        items: _technicians.map((tech) {
                          return DropdownMenuItem<String>(
                            value: tech,
                            child: Text(tech),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _assignedTechnician = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 8. Media attachment (Anomalies)
                    if (_selectedType == TicketType.anomaly) ...[
                      const Text(
                        'Pièces jointes (Photos / Vocal)',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMediaRow(),
                      const SizedBox(height: 24),
                    ],

                    // 9. Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == TicketType.anomaly
                              ? AppColors.danger
                              : AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitForm,
                        child: Text(
                          _selectedType == TicketType.anomaly
                              ? 'Signaler l\'anomalie'
                              : 'Enregistrer la tâche',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 24) / 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: TicketPriority.values.map((prio) {
            final isSelected = _selectedPriority == prio;
            Color prioColor;
            String text;

            switch (prio) {
              case TicketPriority.low:
                prioColor = AppColors.priorityLow;
                text = 'Faible';
                break;
              case TicketPriority.medium:
                prioColor = AppColors.priorityMedium;
                text = 'Moyen';
                break;
              case TicketPriority.high:
                prioColor = AppColors.priorityHigh;
                text = 'Élevé';
                break;
              case TicketPriority.critical:
                prioColor = AppColors.priorityCritical;
                text = 'Critique';
                break;
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedPriority = prio),
              child: Container(
                width: width,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? prioColor.withValues(alpha: 0.25)
                      : AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? prioColor : AppColors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? prioColor : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMediaRow() {
    return Row(
      children: [
        // Camera button
        InkWell(
          onTap: () {
            setState(() {
              _mockPhotoCount++;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo capturée et jointe ✓'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.camera_alt_outlined,
                color: AppColors.textSecondary, size: 28),
          ),
        ),
        const SizedBox(width: 12),

        // Photo thumbnail preview (if attached)
        if (_mockPhotoCount > 0)
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/placeholder_pool.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _mockPhotoCount = 0),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'x$_mockPhotoCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(width: 12),

        // Voice recorder button
        GestureDetector(
          onLongPressStart: (_) {
            setState(() {
              _isRecording = true;
            });
          },
          onLongPressEnd: (_) {
            setState(() {
              _isRecording = false;
              _hasVoiceNote = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note vocale enregistrée ✓'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _isRecording
                  ? AppColors.danger.withValues(alpha: 0.25)
                  : AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecording ? AppColors.danger : AppColors.border,
                width: _isRecording ? 2.0 : 1.0,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: _isRecording ? AppColors.danger : AppColors.textSecondary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),

        if (_hasVoiceNote)
          Chip(
            backgroundColor: AppColors.backgroundSecondary,
            avatar: const Icon(Icons.play_arrow, color: AppColors.success),
            label: const Text('Vocal.mp3',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            onDeleted: () => setState(() => _hasVoiceNote = false),
            deleteIconColor: AppColors.textSecondary,
          ),
      ],
    );
  }
}
