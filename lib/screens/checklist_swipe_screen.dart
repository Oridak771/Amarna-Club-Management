import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/swipe_card.dart';

class ChecklistSwipeScreen extends ConsumerStatefulWidget {
  final String activityId;
  const ChecklistSwipeScreen({super.key, required this.activityId});

  @override
  ConsumerState<ChecklistSwipeScreen> createState() => _ChecklistSwipeScreenState();
}

class _ChecklistSwipeScreenState extends ConsumerState<ChecklistSwipeScreen> {
  // Simple dialog to log problem details
  Future<Map<String, String>?> _showProblemDialog(BuildContext context, ChecklistItem item) async {
    final commentController = TextEditingController();
    String? simulatedPhotoPath;
    
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signaler un Problème',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Décrivez le problème...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accentPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Simulated photo capture
                    if (item.requiresPhoto && simulatedPhotoPath == null) ...[
                      const Text(
                        'Photo obligatoire *',
                        style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: simulatedPhotoPath != null ? AppColors.success : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(
                          simulatedPhotoPath != null ? Icons.check : Icons.camera_alt,
                          color: simulatedPhotoPath != null ? AppColors.success : AppColors.info,
                        ),
                        label: Text(
                          simulatedPhotoPath != null ? 'Photo enregistrée' : 'Prendre une photo',
                          style: TextStyle(
                            color: simulatedPhotoPath != null ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        onPressed: () {
                          // Simulate taking a photo
                          setState(() {
                            simulatedPhotoPath = 'assets/images/inspections/simulated_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (item.requiresPhoto && simulatedPhotoPath == null)
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'comment': commentController.text,
                            'photoPath': simulatedPhotoPath ?? '',
                          });
                        },
                  child: const Text('Signaler'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allChecklists = ref.watch(checklistProvider);
    final activityChecklists = allChecklists.where((item) => item.activityId == widget.activityId).toList();
    
    if (activityChecklists.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: const Center(
          child: Text('Aucune inspection configurée pour cette activité.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final openChecklists = activityChecklists.where((item) => item.status == ChecklistStatus.open).toList();
    final completedCount = activityChecklists.length - openChecklists.length;
    final progress = activityChecklists.isNotEmpty ? completedCount / activityChecklists.length : 0.0;

    // Trigger navigation to summary if all swiped
    if (openChecklists.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/activites/${widget.activityId}/checklist-summary');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentItem = openChecklists.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle Journalier'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression : $completedCount / ${activityChecklists.length}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
            const Spacer(),
            
            // Swipe Stack Card
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SwipeCard(
                  key: ValueKey(currentItem.id),
                  title: currentItem.title,
                  category: currentItem.category,
                  requiresPhoto: currentItem.requiresPhoto,
                  onSwiped: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Swipe Right -> Success Done
                      ref.read(checklistProvider.notifier).updateItemStatus(
                        currentItem.id,
                        ChecklistStatus.done,
                      );
                    } else {
                      // Swipe Left -> Problem Dialog
                      final details = await _showProblemDialog(context, currentItem);
                      if (details != null) {
                        ref.read(checklistProvider.notifier).updateItemStatus(
                          currentItem.id,
                          ChecklistStatus.problem,
                          comment: details['comment'],
                          photoPath: details['photoPath'],
                        );
                      } else {
                        // User cancelled, force state rebuild to center card back
                        setState(() {});
                      }
                    }
                  },
                ),
              ),
            ),
            
            const Spacer(),
            // Bottom Action Hints
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSwipeHint(Icons.arrow_back, '⚠️ PROBLÈME', AppColors.warning),
                _buildSwipeHint(Icons.arrow_forward, '✅ TERMINÉ', AppColors.success),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeHint(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == Icons.arrow_back) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (icon == Icons.arrow_forward) ...[
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 16),
          ],
        ],
      ),
    );
  }
}
