import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/incident.dart';
import 'package:amarna_club/models/maintenance_task.dart';
import 'package:amarna_club/providers/maintenance_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';
import 'package:amarna_club/widgets/app_filter_chip.dart';

class CreateMaintenanceScreen extends ConsumerStatefulWidget {
  const CreateMaintenanceScreen({super.key});

  @override
  ConsumerState<CreateMaintenanceScreen> createState() => _CreateMaintenanceScreenState();
}

class _CreateMaintenanceScreenState extends ConsumerState<CreateMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assetNameController = TextEditingController();

  MaintenanceType _selectedType = MaintenanceType.preventive;
  IncidentPriority _selectedPriority = IncidentPriority.medium;
  String? _assignedTechnician = 'Karim (Technicien)';

  final List<String> _technicians = [
    'Karim (Technicien)',
    'Sami (Électricien)',
    'Mourad (Technicien)',
    'Non assigné',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assetNameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Add maintenance task using provider
      ref.read(maintenanceProvider.notifier).addMaintenanceTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assetId: 'asset-${DateTime.now().millisecondsSinceEpoch}',
        assetName: _assetNameController.text.trim(),
        activityId: 'pool', // Mock default activity id
        type: _selectedType,
        priority: _selectedPriority,
        assignedTechnician: _assignedTechnician == 'Non assigné' ? null : _assignedTechnician,
      );

      // Return to list
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance créée avec succès ✓'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une Maintenance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                const Text(
                  'Titre de la tâche',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ex: Remplacement vanne papillon',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Asset Name Field with Mock Scan Action
                const Text(
                  'Équipement / Asset',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _assetNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nom ou Code-barres de l\'équipement',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.accentPrimary),
                      onPressed: () {
                        // Mock QR scanning and autofill
                        setState(() {
                          _assetNameController.text = 'Filtre Principal A';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Équipement détecté : Filtre Principal A'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir ou scanner un équipement';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Maintenance Type Choice
                const Text(
                  'Type de maintenance',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppFilterChip(
                      label: 'Préventif',
                      isSelected: _selectedType == MaintenanceType.preventive,
                      onTap: () => setState(() => _selectedType = MaintenanceType.preventive),
                    ),
                    const SizedBox(width: 12),
                    AppFilterChip(
                      label: 'Correctif',
                      isSelected: _selectedType == MaintenanceType.corrective,
                      onTap: () => setState(() => _selectedType = MaintenanceType.corrective),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Priority Selection (4 options)
                const Text(
                  'Priorité',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
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
                        _buildPriorityButton(IncidentPriority.low, 'Faible', AppColors.priorityLow),
                        _buildPriorityButton(IncidentPriority.medium, 'Moyen', AppColors.priorityMedium),
                        _buildPriorityButton(IncidentPriority.high, 'Élevé', AppColors.priorityHigh),
                        _buildPriorityButton(IncidentPriority.critical, 'Critique', AppColors.priorityCritical),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Description Field
                const Text(
                  'Description',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Décrivez en détail les travaux de maintenance requis...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Assignee Dropdown
                const Text(
                  'Technicien assigné',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.backgroundSecondary,
                  initialValue: _assignedTechnician,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Enregistrer la Maintenance'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(IncidentPriority priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppColors.backgroundSecondary,
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
