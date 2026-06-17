import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/incident.dart';
import 'package:amarna_club/providers/incidents_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';

class QuickIncidentReportScreen extends ConsumerStatefulWidget {
  const QuickIncidentReportScreen({super.key});

  @override
  ConsumerState<QuickIncidentReportScreen> createState() =>
      _QuickIncidentReportScreenState();
}

class _QuickIncidentReportScreenState
    extends ConsumerState<QuickIncidentReportScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedActivityId = 'pool';
  String _selectedActivityName = 'Piscine';
  IncidentPriority _selectedPriority = IncidentPriority.medium;

  // S12b Extended State
  bool _showMoreDetails = false;
  bool _isRecording = false;
  bool _hasVoiceNote = false;
  int _mockPhotoCount = 0;
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
    _locationController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      ref.read(incidentsProvider.notifier).addIncident(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            activityId: _selectedActivityId,
            activityName: _selectedActivityName,
            priority: _selectedPriority,
            imageUrl: _mockPhotoCount > 0
                ? 'https://example.com/incident-photo.jpg'
                : null,
            voiceNoteUrl:
                _hasVoiceNote ? 'https://example.com/voice-note.mp3' : null,
          );

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident signalé avec succès ✓'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showMoreDetails
            ? 'Rapport Incident Détaillé'
            : 'Rapport Incident Rapide'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Selector
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

                // Title field
                const Text(
                  'Titre / Résumé du problème',
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
                    hintText: 'Ex: Fuite d\'eau pompe 2',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description field
                const Text(
                  'Description du problème',
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
                    hintText: 'Décrivez précisément le problème constaté...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Priority Selection buttons
                const Text(
                  'Priorité',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3.5,
                      children: [
                        _buildPriorityButton(IncidentPriority.low, 'Faible',
                            AppColors.priorityLow),
                        _buildPriorityButton(IncidentPriority.medium, 'Moyen',
                            AppColors.priorityMedium),
                        _buildPriorityButton(IncidentPriority.high, 'Élevé',
                            AppColors.priorityHigh),
                        _buildPriorityButton(IncidentPriority.critical,
                            'Critique', AppColors.priorityCritical),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Photos Attachment Grid Mock
                const Text(
                  'Photos / Pièces jointes',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mockPhotoCount + 1,
                    itemBuilder: (context, index) {
                      if (index == _mockPhotoCount) {
                        // Add Button
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _mockPhotoCount++;
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.border, width: 1),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined,
                                color: AppColors.accentPrimary),
                          ),
                        );
                      }
                      // Mock Image Thumbnail
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                                child: Icon(Icons.image,
                                    color: AppColors.textSecondary)),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _mockPhotoCount--;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── S12b Expandable More Details ──────────────────
                if (!_showMoreDetails)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showMoreDetails = true),
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.accentPrimary),
                      label: const Text('Ajouter plus de détails (S12b)'),
                    ),
                  )
                else ...[
                  const Divider(height: 32, color: AppColors.border),
                  const Text(
                    'Détails supplémentaires (S12b)',
                    style: TextStyle(
                        color: AppColors.accentSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Location field
                  const Text(
                    'Localisation / Zone',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Zone Bassin 3, Écurie Box A',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Voice Recorder Mock
                  const Text(
                    'Note Vocale',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_isRecording) {
                              setState(() {
                                _isRecording = false;
                                _hasVoiceNote = true;
                              });
                            } else {
                              setState(() {
                                _isRecording = true;
                                _hasVoiceNote = false;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: _isRecording
                                ? AppColors.danger
                                : AppColors.accentPrimary,
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic_none,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRecording
                                    ? 'Enregistrement en cours...'
                                    : (_hasVoiceNote
                                        ? 'Note vocale enregistrée ✓'
                                        : 'Appuyer pour enregistrer'),
                                style: TextStyle(
                                  color: _isRecording
                                      ? AppColors.danger
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (_isRecording) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('0:05',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ] else if (_hasVoiceNote) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Durée: 0:12',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11)),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _hasVoiceNote = false),
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Technician Assignee
                  const Text(
                    'Technicien suggéré / assigné',
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _technicians.map((String tech) {
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
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showMoreDetails = false),
                      child: const Text('Masquer les détails supplémentaires'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitReport,
                  child: const Text('Signaler l\'Incident'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(
      IncidentPriority priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
